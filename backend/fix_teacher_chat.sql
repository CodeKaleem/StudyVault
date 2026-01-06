-- =========================================================
-- FIX: Teacher Can't See Chat Messages
-- This ensures teachers (server owners) can see and send messages
-- =========================================================

-- PART 1: Ensure the check_is_member function works correctly
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


-- PART 2: Create a function to check if user is server owner
CREATE OR REPLACE FUNCTION public.check_is_owner(_server_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.chat_servers 
    WHERE id = _server_id 
    AND owner_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.check_is_owner(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_is_owner(uuid) TO service_role;


-- PART 3: Fix Chat Messages Policies
-- Allow viewing if you're a member OR the owner
DROP POLICY IF EXISTS "View Messages" ON public.chat_messages;

CREATE POLICY "View Messages"
ON public.chat_messages
FOR SELECT
USING (
  public.check_is_member(server_id) 
  OR 
  public.check_is_owner(server_id)
);

-- Allow sending if you're a member OR the owner
DROP POLICY IF EXISTS "Send Messages" ON public.chat_messages;

CREATE POLICY "Send Messages"
ON public.chat_messages
FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND
  (
    public.check_is_member(server_id)
    OR
    public.check_is_owner(server_id)
  )
);


-- PART 4: Fix Server Members Policy
-- Owners should be able to see all members
DROP POLICY IF EXISTS "Members viewable by server members" ON public.server_members;

CREATE POLICY "Members viewable by server members"
ON public.server_members
FOR SELECT
USING (
  auth.uid() = user_id
  OR
  public.check_is_member(server_id)
  OR
  public.check_is_owner(server_id)
);


-- PART 5: Backfill - Add existing server owners as members
-- This ensures all teachers who created servers are also members
INSERT INTO public.server_members (server_id, user_id)
SELECT id, owner_id 
FROM public.chat_servers
WHERE NOT EXISTS (
  SELECT 1 FROM public.server_members 
  WHERE server_id = chat_servers.id 
  AND user_id = chat_servers.owner_id
)
ON CONFLICT (server_id, user_id) DO NOTHING;
