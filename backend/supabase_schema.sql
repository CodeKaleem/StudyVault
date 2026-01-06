-- ==============================================================================
-- ADRIAN CROSS - ARCHITECTURE
-- SUPABASE SCHEMA - EDU APP (OPTION A: DECOUPLED ASSET MODEL)
-- ==============================================================================

-- 1. ENUMS & CONFIGURATION
-- ========================
create type user_role as enum ('teacher', 'student');

-- 2. PUBLIC PROFILES
-- ==================
-- Links to auth.users. This is the source of truth for user roles.
create table public.profiles (
  id uuid references auth.users not null primary key,
  full_name text not null,
  avatar_url text,
  role user_role not null default 'student',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Policies
create policy "Public profiles are viewable by everyone" 
  on profiles for select 
  using ( true );

create policy "Users can update own profile" 
  on profiles for update 
  using ( auth.uid() = id );

-- Trigger for New User Creation (Auto-Profile)
-- Note: You handle the role assignment in your SignUp UI or Function.
-- Here we default to 'student' if not specified, but usually meta-data handles this.
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url, role)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'avatar_url',
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'student')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- 3. COURSES & METADATA (Normalized)
-- ===================================
-- Keeps data clean. "Maths" vs "Mathematics" is solved here.
create table public.courses (
  id uuid default gen_random_uuid() primary key,
  code text not null unique, -- e.g., "CS101"
  name text not null, -- e.g., "Intro to Computer Science"
  created_at timestamptz default now()
);

alter table public.courses enable row level security;

create policy "Courses are readable by everyone" 
  on courses for select 
  using ( true );

-- Only teachers can add new courses (Optional strictness)
create policy "Teachers can create courses" 
  on courses for insert 
  with check ( 
    exists (select 1 from profiles where id = auth.uid() and role = 'teacher')
  );


-- 4. CHAT SERVERS
-- ===============
create table public.chat_servers (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  name text not null,
  description text,
  owner_id uuid references profiles(id) not null,
  invite_code text unique not null, -- For joining
  course_id uuid references courses(id), -- Optional: Link server to a course
  semester text, -- e.g., "Fall 2025"
  banner_url text
);

alter table public.chat_servers enable row level security;

-- RLS:
-- 1. Everyone can see basic info (needed to join via invite code preview).
-- 2. Only Owners (Teachers) can update/delete.
create policy "Servers viewable" 
  on chat_servers for select 
  using ( true );

create policy "Teachers can create servers" 
  on chat_servers for insert 
  with check ( 
    exists (select 1 from profiles where id = auth.uid() and role = 'teacher')
  );

create policy "Owners can update servers" 
  on chat_servers for update 
  using ( auth.uid() = owner_id );


-- 5. SERVER MEMBERS
-- =================
create table public.server_members (
  id uuid default gen_random_uuid() primary key,
  server_id uuid references chat_servers(id) not null,
  user_id uuid references profiles(id) not null,
  joined_at timestamptz default now(),
  unique(server_id, user_id) -- No duplicate memberships
);

alter table public.server_members enable row level security;

create policy "Members viewable by server members" 
  on server_members for select 
  using (
    -- User is the member OR User is also a member of the same server
    auth.uid() = user_id or 
    exists (
      select 1 from server_members sm 
      where sm.server_id = server_members.server_id 
      and sm.user_id = auth.uid()
    )
  );

create policy "Users can join via code (handled by function usually) or open insert" 
  on server_members for insert 
  with check ( auth.uid() = user_id );


-- 6. CONTENT LIBRARY (The Core Asset)
-- ===================================
-- IMPLEMENTING OPTION A: Decoupled Assets
-- Files live here. Chat messages reference this.
create table public.content_library (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  title text not null,
  file_url text not null,
  file_type text not null, -- 'pdf', 'image', etc.
  file_size_bytes bigint,
  
  -- Categorization
  course_id uuid references courses(id),
  subject text, -- Loose string if needed, or link to course
  semester text,
  
  -- Ownership
  server_id uuid references chat_servers(id), -- Which server does this belong to?
  uploader_id uuid references profiles(id) not null
);

alter table public.content_library enable row level security;

-- Policies:
-- 1. Viewable if you are a member of the server it belongs to OR if you are the uploader.
create policy "Content Access" 
  on content_library for select 
  using (
    auth.uid() = uploader_id or
    exists (
      select 1 from server_members 
      where server_members.server_id = content_library.server_id 
      and server_members.user_id = auth.uid()
    )
  );

-- 2. Insert: Must be a member (or teacher owner)
create policy "Content Upload" 
  on content_library for insert 
  with check (
    auth.uid() = uploader_id and 
    exists (
      select 1 from server_members 
      where server_members.server_id = content_library.server_id 
      and server_members.user_id = auth.uid()
    )
  );


-- 7. CHAT MESSAGES
-- ================
create table public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  server_id uuid references chat_servers(id) not null,
  sender_id uuid references profiles(id) not null,
  
  message_text text, -- Can be null if it's purely an attachment
  
  -- LINK TO CONTENT (Option A)
  attachment_id uuid references content_library(id)
);

alter table public.chat_messages enable row level security;

create policy "View Messages" 
  on chat_messages for select 
  using (
    exists (
        select 1 from server_members 
        where server_members.server_id = chat_messages.server_id 
        and server_members.user_id = auth.uid()
    )
  );

create policy "Send Messages" 
  on chat_messages for insert 
  with check (
    auth.uid() = sender_id and
    exists (
        select 1 from server_members 
        where server_members.server_id = chat_messages.server_id 
        and server_members.user_id = auth.uid()
    )
  );


-- 8. PAST PAPERS
-- ==============
create table public.past_papers (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  title text not null,
  year int not null,
  semester text,
  
  course_id uuid references courses(id),
  file_url text not null,
  uploaded_by uuid references profiles(id)
);

alter table public.past_papers enable row level security;

create policy "View Past Papers" 
  on past_papers for select 
  using ( true ); -- Open to all authenticated users

create policy "Teachers Upload Papers" 
  on past_papers for insert 
  with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'teacher')
  );


-- 9. GPA CALCULATOR
-- =================
create table public.student_grades (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  student_id uuid references profiles(id) not null,
  
  course_name text not null,
  credit_hours numeric(3,1) not null,
  grade_point numeric(3,2) not null, -- e.g., 3.5
  semester text
);

alter table public.student_grades enable row level security;

create policy "Own Grades" 
  on student_grades for all
  using ( auth.uid() = student_id );

create policy "Teachers View Grades" 
  on student_grades for select 
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'teacher')
  );


-- ==============================================================================
-- STORAGE BUCKETS (Run these in SQL Editor or Dashboard)
-- ==============================================================================
-- 1. 'chat-attachments' (public access false)
-- 2. 'past-papers' (public access true)
-- 3. 'avatars' (public access true)

-- STORAGE POLICIES (Example for chat-attachments)
-- insert into storage.buckets (id, name, public) values ('chat-attachments', 'chat-attachments', false);
-- 
-- policy "Give users access to own folder 1ok22a_0":
--   CAN INSERT: auth.uid() = owner_id
--   (Requires specific folder structure policies or generally allowing authenticated uploads)
