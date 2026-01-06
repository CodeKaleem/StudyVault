-- ==========================================
-- FIX SCHEMA SCRIPT (Run this in Supabase)
-- ==========================================

-- 1. Safely Create Enum
DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('teacher', 'student');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create Profiles Table (if missing)
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  full_name text not null,
  avatar_url text,
  role public.user_role not null default 'student',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. Update RLS on Profiles
alter table public.profiles enable row level security;

-- Drop existing policies to avoid conflicts
drop policy if exists "Public profiles are viewable by everyone" on profiles;
create policy "Public profiles are viewable by everyone" on profiles for select using (true);

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on profiles;
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);

-- 4. Fix/Re-create Trigger Function (CRITICAL FOR SIGNUP)
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url, role)
  values (
    new.id, 
    -- Fallback to 'Unknown User' if name is missing
    coalesce(new.raw_user_meta_data->>'full_name', 'Unknown User'), 
    new.raw_user_meta_data->>'avatar_url',
    -- Safely cast role, default to student
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role)
  );
  return new;
end;
$$ language plpgsql security definer;

-- 5. Re-attach Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 6. Ensure other tables exist (Simplified checks)
create table if not exists public.courses (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  name text not null,
  created_at timestamptz default now()
);

alter table public.courses enable row level security;
drop policy if exists "Courses are readable by everyone" on courses;
create policy "Courses are readable by everyone" on courses for select using (true);
