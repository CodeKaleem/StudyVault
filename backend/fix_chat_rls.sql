-- =========================================================
-- FIX CHAT MESSAGE RLS POLICY
-- Run this in Supabase SQL Editor
-- =========================================================

-- The issue: The "Send Messages" policy is too restrictive or conflicting
-- Solution: Recreate the policy with proper logic

-- 1. Drop the existing policy
DROP POLICY IF EXISTS "Send Messages" ON public.chat_messages;

-- 2. Create a new, simpler policy for inserting messages
CREATE POLICY "Send Messages"
ON public.chat_messages
FOR INSERT
WITH CHECK (
  -- User must be authenticated
  auth.uid() IS NOT NULL
  AND
  -- User must be the sender
  auth.uid() = sender_id
  AND
  -- User must be a member of the server (using our safe function)
  public.check_is_member(server_id)
);

-- 3. Verify the check_is_member function exists
-- If it doesn't, create it:
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_is_member(uuid) TO service_role;

-- 4. Also ensure the SELECT policy is correct
DROP POLICY IF EXISTS "View Messages" ON public.chat_messages;

CREATE POLICY "View Messages"
ON public.chat_messages
FOR SELECT
USING (
  public.check_is_member(server_id)
);
