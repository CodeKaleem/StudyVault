-- =========================================================
-- ANNOUNCEMENTS & CHAT PERMISSIONS SCHEMA
-- Run this in Supabase SQL Editor
-- =========================================================

-- 1. Add chat permission settings to chat_servers table
ALTER TABLE public.chat_servers 
ADD COLUMN IF NOT EXISTS allow_student_messages boolean DEFAULT true;

-- 2. Create announcements table
CREATE TABLE IF NOT EXISTS public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  server_id uuid REFERENCES public.chat_servers(id) ON DELETE CASCADE NOT NULL,
  author_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  is_important boolean DEFAULT false,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- 3. Add is_announcement flag to chat_messages (for pinned announcements in chat)
ALTER TABLE public.chat_messages
ADD COLUMN IF NOT EXISTS is_announcement boolean DEFAULT false;

-- 4. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_announcements_server ON public.announcements(server_id);
CREATE INDEX IF NOT EXISTS idx_announcements_created ON public.announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_announcement ON public.chat_messages(server_id, is_announcement) WHERE is_announcement = true;

-- 5. RLS Policies for announcements

-- Enable RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- View announcements: Anyone in the server can view
DROP POLICY IF EXISTS "View announcements" ON public.announcements;
CREATE POLICY "View announcements"
ON public.announcements
FOR SELECT
USING (
  public.check_is_member(server_id)
  OR
  public.check_is_owner(server_id)
);

-- Create announcements: Only teachers (server owners)
DROP POLICY IF EXISTS "Create announcements" ON public.announcements;
CREATE POLICY "Create announcements"
ON public.announcements
FOR INSERT
WITH CHECK (
  auth.uid() = author_id
  AND
  public.check_is_owner(server_id)
);

-- Update announcements: Only the author
DROP POLICY IF EXISTS "Update announcements" ON public.announcements;
CREATE POLICY "Update announcements"
ON public.announcements
FOR UPDATE
USING (auth.uid() = author_id);

-- Delete announcements: Only the author
DROP POLICY IF EXISTS "Delete announcements" ON public.announcements;
CREATE POLICY "Delete announcements"
ON public.announcements
FOR DELETE
USING (auth.uid() = author_id);

-- 6. Update chat_messages policy to respect allow_student_messages setting
DROP POLICY IF EXISTS "Send Messages" ON public.chat_messages;

CREATE POLICY "Send Messages"
ON public.chat_messages
FOR INSERT
WITH CHECK (
  auth.uid() = sender_id
  AND
  (
    -- Owner can always send
    public.check_is_owner(server_id)
    OR
    -- Members can send if they're a member AND (it's an announcement OR student messages are allowed)
    (
      public.check_is_member(server_id)
      AND
      (
        is_announcement = false -- Regular messages
        AND
        EXISTS (
          SELECT 1 FROM public.chat_servers
          WHERE id = server_id
          AND (allow_student_messages = true OR owner_id = auth.uid())
        )
      )
    )
  )
);

-- 7. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Add trigger for announcements
DROP TRIGGER IF EXISTS update_announcements_updated_at ON public.announcements;
CREATE TRIGGER update_announcements_updated_at
BEFORE UPDATE ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
