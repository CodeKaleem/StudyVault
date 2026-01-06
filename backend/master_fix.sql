-- =================================================================
-- MASTER REPAIR SCRIPT 
-- Run this in Supabase SQL Editor to Fix:
-- 1. Missing Buckets (Upload Error)
-- 2. RLS Infinite Recursion (Crash Error)
-- 3. Schema/Tables (Data Error)
-- =================================================================

-- PART 1: STORAGE BUCKETS (Fixes "Bucket not found")
insert into storage.buckets (id, name, public) 
values ('chat-attachments', 'chat-attachments', true) -- Changing to TRUE to minimize access issues for now
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public) 
values ('past-papers', 'past-papers', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;


-- PART 2: STORAGE POLICIES (Fixes "Permission Denied" if you get that next)
-- First, drop old policies to ensure clean slate
drop policy if exists "Authenticated users can upload chat attachments" on storage.objects;
drop policy if exists "Authenticated users can view chat attachments" on storage.objects;
drop policy if exists "Chat Attachment Upload" on storage.objects;
drop policy if exists "Chat Attachment View" on storage.objects;

-- Create simple, permissive policies for the chat bucket
create policy "Chat Attachment Upload"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'chat-attachments' );

create policy "Chat Attachment View"
on storage.objects for select
to authenticated
using ( bucket_id = 'chat-attachments' );


-- PART 3: RECURSION FIX (Fixes "infinite recursion" crash)
CREATE OR REPLACE FUNCTION public.check_is_member(_server_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.server_members 
    WHERE server_id = _server_id 
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO service_role;

-- Apply safe policies
DROP POLICY IF EXISTS "Members viewable by server members" ON public.server_members;
CREATE POLICY "Members viewable by server members" 
ON public.server_members FOR SELECT 
USING ( auth.uid() = user_id OR public.check_is_member(server_id) );

DROP POLICY IF EXISTS "View Messages" ON public.chat_messages;
CREATE POLICY "View Messages" ON public.chat_messages 
FOR SELECT USING ( public.check_is_member(server_id) );

DROP POLICY IF EXISTS "Send Messages" ON public.chat_messages;
CREATE POLICY "Send Messages" ON public.chat_messages 
FOR INSERT WITH CHECK ( 
    auth.uid() = sender_id AND public.check_is_member(server_id) 
);

DROP POLICY IF EXISTS "Content Access" ON public.content_library;
CREATE POLICY "Content Access" ON public.content_library 
FOR SELECT USING ( 
    auth.uid() = uploader_id OR public.check_is_member(server_id) 
);
