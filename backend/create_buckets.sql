-- =========================================================
-- CREATE STORAGE BUCKETS
-- Run this in Supabase SQL Editor to enable file uploads
-- =========================================================

-- 1. Create the 'chat-attachments' bucket for images/files in chat
insert into storage.buckets (id, name, public) 
values ('chat-attachments', 'chat-attachments', false)
on conflict (id) do nothing;

-- 2. Create 'past-papers' bucket (public)
insert into storage.buckets (id, name, public) 
values ('past-papers', 'past-papers', true)
on conflict (id) do nothing;

-- 3. Create 'avatars' bucket (public)
insert into storage.buckets (id, name, public) 
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- =========================================================
-- STORAGE POLICIES (Required for Mobile Uploads)
-- =========================================================

-- Policy 1: Allow Authenticated Users to Upload Chat Attachments
create policy "Authenticated users can upload chat attachments"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'chat-attachments' );

-- Policy 2: Allow Authenticated Users to View Chat Attachments
-- (We rely on signed URLs for private buckets, but this helps general access)
create policy "Authenticated users can view chat attachments"
on storage.objects for select
to authenticated
using ( bucket_id = 'chat-attachments' );

-- Policy 3: Allow Teachers to Upload Past Papers
create policy "Teachers can upload past papers"
on storage.objects for insert
to authenticated
with check ( 
  bucket_id = 'past-papers' 
  AND exists (select 1 from public.profiles where id = auth.uid() and role = 'teacher')
);

-- Policy 4: Everyone can view Past Papers
create policy "Everyone can view past papers"
on storage.objects for select
to authenticated
using ( bucket_id = 'past-papers' );
