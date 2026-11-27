-- Expose only the company owner UUID needed to open the public company profile.
-- No email, phone, commercial register, or private metadata is exposed.
CREATE OR REPLACE VIEW public.companies_public
WITH (security_barrier = true)
AS
SELECT
    id,
    owner_id,
    name,
    metadata ->> 'business_field' AS business_field,
    created_at
FROM public.companies;
