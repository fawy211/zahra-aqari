-- Expose only the display name and avatar reference needed by authenticated chat participants.
-- Email, phone, account type, and subscription fields remain private in public.profiles.
CREATE OR REPLACE VIEW public.profiles_public
WITH (security_barrier = true)
AS
SELECT
    id,
    name,
    avatar_path
FROM public.profiles;

GRANT SELECT ON public.profiles_public TO authenticated;
