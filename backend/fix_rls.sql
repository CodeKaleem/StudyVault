-- =========================================================
-- FIX: INFINITE RECURSION IN RLS POLICIES
-- Run this script in the Supabase SQL Editor to fix the 500 Error
-- =========================================================

-- 1. Create a Secure Function to check membership
-- "SECURITY DEFINER" allows this function to read the table 
-- without triggering the RLS policy again (breaking the loop).
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

-- Grant access to the function
GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO service_role;


-- 2. Fix "server_members" Policy (The Request causing the crash)
DROP POLICY IF EXISTS "Members viewable by server members" ON public.server_members;

CREATE POLICY "Members viewable by server members" 
ON public.server_members 
FOR SELECT 
USING (
  -- I can always see my own membership row
  auth.uid() = user_id 
  -- OR I can see other rows if I am a member of that server
  -- (Using the function avoids the recursion)
  OR public.check_is_member(server_id)
);


-- 3. (Optional but Recommended) Optimize other policies to use this function
-- This makes your app faster and prevents similar recursion bugs elsewhere.

-- Fix Chat Messages
DROP POLICY IF EXISTS "View Messages" ON public.chat_messages;
CREATE POLICY "View Messages" ON public.chat_messages 
FOR SELECT USING ( public.check_is_member(server_id) );

DROP POLICY IF EXISTS "Send Messages" ON public.chat_messages;
CREATE POLICY "Send Messages" ON public.chat_messages 
FOR INSERT WITH CHECK ( 
    auth.uid() = sender_id AND public.check_is_member(server_id) 
);

-- Fix Content Library
DROP POLICY IF EXISTS "Content Access" ON public.content_library;
CREATE POLICY "Content Access" ON public.content_library 
FOR SELECT USING ( 
    auth.uid() = uploader_id OR public.check_is_member(server_id) 
);
