-- ==============================================================================
-- ADRIAN CROSS - ARCHITECTURE
-- NOTIFICATION SYSTEM (FAN-OUT MODEL)
-- ==============================================================================

-- 1. NOTIFICATIONS TABLE
-- ======================
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now(),
  user_id uuid references profiles(id) not null, -- Who receives this
  title text not null,
  body text not null,
  is_read boolean default false,
  
  -- Metadata for navigation
  related_entity_type text, -- 'server', 'grade', etc.
  related_entity_id uuid
);

alter table public.notifications enable row level security;

-- Users can only see their own notifications
create policy "Own Notifications" 
  on notifications for select 
  using ( auth.uid() = user_id );

-- 2. TRIGGER FUNCTION (THE ENGINE)
-- ================================
create or replace function public.handle_new_chat_message() 
returns trigger as $$
declare
  server_name text;
  sender_name text;
begin
  -- Get Server Name
  select name into server_name from chat_servers where id = new.server_id;
  
  -- Get Sender Name
  select full_name into sender_name from profiles where id = new.sender_id;

  -- Insert notification for ALL members of the server EXCEPT the sender
  insert into public.notifications (user_id, title, body, related_entity_type, related_entity_id)
  select 
    user_id,
    'New Message in ' || server_name,
    sender_name || ': ' || coalesce(new.message_text, 'Sent a file'),
    'server',
    new.server_id
  from server_members
  where server_id = new.server_id
  and user_id != new.sender_id;

  return new;
end;
$$ language plpgsql security definer;

-- 3. ATTACH TRIGGER
-- =================
create trigger on_chat_message_created
  after insert on chat_messages
  for each row execute procedure public.handle_new_chat_message();
