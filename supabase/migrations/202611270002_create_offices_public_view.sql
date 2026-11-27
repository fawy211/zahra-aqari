-- Public directory view: expose only intentionally public office contact details.
CREATE OR REPLACE VIEW public.offices_public
WITH (security_barrier = true)
AS
SELECT
    id,
    name,
    location,
    metadata ->> 'contact_phone' AS phone,
    metadata ->> 'logo_url' AS logo,
    created_at
FROM public.offices;

GRANT SELECT ON public.offices_public TO anon, authenticated;
