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
    COALESCE((metadata ->> 'properties_count')::integer, 0) AS properties_count,
    COALESCE((metadata ->> 'is_verified')::boolean, false) AS is_verified,
    created_at
FROM public.offices;

GRANT SELECT ON public.offices_public TO anon, authenticated;
