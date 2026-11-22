BEGIN;

-- Keep direct client access read-only and limited by the existing owner-row RLS rule.
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.admins'::regclass
      AND conname = 'admins_role_check'
  ) THEN
    ALTER TABLE public.admins
      ADD CONSTRAINT admins_role_check
      CHECK (role IN ('super_admin', 'moderator'));
  END IF;
END
$$;

REVOKE ALL PRIVILEGES ON TABLE public.admins FROM PUBLIC, anon, authenticated;
REVOKE ALL (id, user_id, role, created_at)
  ON TABLE public.admins FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.admins TO authenticated;

DROP POLICY IF EXISTS "Admins are viewable by owner" ON public.admins;
DROP POLICY IF EXISTS admins_select_own_authenticated ON public.admins;
CREATE POLICY admins_select_own_authenticated
  ON public.admins
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- All write operations are performed by narrowly scoped SECURITY DEFINER RPCs.
CREATE OR REPLACE FUNCTION public.admin_list_admins()
RETURNS TABLE (
  user_id uuid,
  role text,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.admins a
    WHERE a.user_id = auth.uid()
      AND a.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'غير مصرح لك بعرض قائمة المشرفين'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT a.user_id, a.role, a.created_at
  FROM public.admins a
  ORDER BY a.created_at ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_add(
  p_user_id uuid,
  p_role text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(734829105);

  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.admins a
    WHERE a.user_id = auth.uid()
      AND a.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'غير مصرح لك بإضافة مشرفين'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS NULL OR p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'معرّف المستخدم غير صالح'
      USING ERRCODE = '22023';
  END IF;

  IF p_role IS NULL OR p_role NOT IN ('super_admin', 'moderator') THEN
    RAISE EXCEPTION 'الدور المحدد غير مسموح به'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.admins (user_id, role)
  VALUES (p_user_id, p_role);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_role(
  p_user_id uuid,
  p_role text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_role text;
  v_super_admin_count bigint;
BEGIN
  PERFORM pg_advisory_xact_lock(734829105);

  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.admins a
    WHERE a.user_id = auth.uid()
      AND a.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'غير مصرح لك بتعديل أدوار المشرفين'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS NULL OR p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'لا يمكنك تعديل دور حسابك الحالي'
      USING ERRCODE = '42501';
  END IF;

  IF p_role IS NULL OR p_role NOT IN ('super_admin', 'moderator') THEN
    RAISE EXCEPTION 'الدور المحدد غير مسموح به'
      USING ERRCODE = '22023';
  END IF;

  SELECT a.role INTO v_current_role
  FROM public.admins a
  WHERE a.user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المشرف المطلوب غير موجود'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_current_role = 'super_admin' AND p_role <> 'super_admin' THEN
    SELECT count(*) INTO v_super_admin_count
    FROM public.admins a
    WHERE a.role = 'super_admin';

    IF v_super_admin_count <= 1 THEN
      RAISE EXCEPTION 'لا يمكن تخفيض رتبة آخر مشرف أعلى'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  UPDATE public.admins
  SET role = p_role
  WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_remove(
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_role text;
  v_super_admin_count bigint;
BEGIN
  PERFORM pg_advisory_xact_lock(734829105);

  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.admins a
    WHERE a.user_id = auth.uid()
      AND a.role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'غير مصرح لك بحذف المشرفين'
      USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS NULL OR p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'لا يمكنك حذف صلاحية الإشراف عن حسابك الحالي'
      USING ERRCODE = '42501';
  END IF;

  SELECT a.role INTO v_current_role
  FROM public.admins a
  WHERE a.user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'المشرف المطلوب غير موجود'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_current_role = 'super_admin' THEN
    SELECT count(*) INTO v_super_admin_count
    FROM public.admins a
    WHERE a.role = 'super_admin';

    IF v_super_admin_count <= 1 THEN
      RAISE EXCEPTION 'لا يمكن حذف آخر مشرف أعلى'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  DELETE FROM public.admins
  WHERE user_id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_admins() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_add(uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_update_role(uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_remove(uuid) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.admin_list_admins() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_add(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_role(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_remove(uuid) TO authenticated;

COMMIT;
