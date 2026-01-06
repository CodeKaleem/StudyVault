-- =========================================================
-- FEATURE: ADD/REMOVE STUDENTS BY EMAIL
-- Run this in Supabase SQL Editor
-- =========================================================

-- 1. Add 'email' column to public.profiles so we can search by it
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email text;

-- 2. Backfill emails for existing users
UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id;

-- 3. Update the Signup Trigger to include email automatically for new users
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role, email)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'full_name', 'Unknown User'), 
    new.raw_user_meta_data->>'avatar_url',
    COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role),
    new.email -- Capturing the email now
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Enable Server Owners to Manage Members (Add/Remove)
-- This policy allows a user to DELETE or INSERT into server_members
-- IF they are the owner of the referenced server.
DROP POLICY IF EXISTS "Owners can manage members" ON public.server_members;

CREATE POLICY "Owners can manage members"
ON public.server_members
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.chat_servers 
    WHERE id = public.server_members.server_id 
    AND owner_id = auth.uid()
  )
);
