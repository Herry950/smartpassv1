DROP POLICY IF EXISTS "Assistants can view their assignments"
ON public.assistant_assignments;

CREATE POLICY "Assistants can view their assignments"
ON public.assistant_assignments
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.assistants AS a
    WHERE a.id = assistant_assignments.assistant_id
      AND a.auth_user_id = auth.uid()
      AND a.is_active = true
  )
);
