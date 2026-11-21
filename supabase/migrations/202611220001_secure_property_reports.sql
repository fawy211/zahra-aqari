-- ZAHRA: secure property reports
-- Apply this migration in Supabase SQL Editor before using the updated app.
-- Safe to re-run: constraints, index, policies and trigger are guarded/replaced.

begin;

alter table public.reports
  alter column status set default 'pending',
  alter column status set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.reports'::regclass
      and conname = 'reports_target_type_check'
  ) then
    alter table public.reports
      add constraint reports_target_type_check
      check (target_type = 'property');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.reports'::regclass
      and conname = 'reports_reason_check'
  ) then
    alter table public.reports
      add constraint reports_reason_check
      check (char_length(btrim(reason)) between 3 and 500);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.reports'::regclass
      and conname = 'reports_status_check'
  ) then
    alter table public.reports
      add constraint reports_status_check
      check (status in ('pending', 'resolved', 'dismissed'));
  end if;
end
$$;

create unique index if not exists reports_one_per_user_target_uidx
  on public.reports (user_id, target_type, target_id);

-- Least-privilege grants: clients may submit only the intended fields.
revoke all privileges on table public.reports from public, anon, authenticated;
grant select on table public.reports to authenticated;
grant insert (user_id, target_type, target_id, reason)
  on table public.reports to authenticated;
grant update (status) on table public.reports to authenticated;

drop policy if exists "Reports are manageable by owner" on public.reports;
drop policy if exists reports_insert_own_property on public.reports;
drop policy if exists reports_select_own_or_admin on public.reports;
drop policy if exists reports_update_admin_status on public.reports;

create policy reports_insert_own_property
on public.reports
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and target_type = 'property'
  and char_length(btrim(reason)) between 3 and 500
  and exists (
    select 1
    from public.properties p
    where p.id = target_id
      and p.status = 'verified'
      and p.owner_id <> (select auth.uid())
  )
);

create policy reports_select_own_or_admin
on public.reports
for select
to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.admins a
    where a.user_id = (select auth.uid())
      and a.role in ('super_admin', 'moderator')
  )
);

create policy reports_update_admin_status
on public.reports
for update
to authenticated
using (
  exists (
    select 1
    from public.admins a
    where a.user_id = (select auth.uid())
      and a.role in ('super_admin', 'moderator')
  )
)
with check (
  exists (
    select 1
    from public.admins a
    where a.user_id = (select auth.uid())
      and a.role in ('super_admin', 'moderator')
  )
  and status in ('resolved', 'dismissed')
);

-- Maintain the existing properties summary fields from the report records.
create or replace function public.sync_property_report_state()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_target_id uuid;
  total_reports integer;
  pending_reports integer;
begin
  if tg_op = 'DELETE' then
    affected_target_id := old.target_id;
  else
    affected_target_id := new.target_id;
  end if;

  select
    count(*)::integer,
    count(*) filter (where r.status = 'pending')::integer
  into total_reports, pending_reports
  from public.reports r
  where r.target_type = 'property'
    and r.target_id = affected_target_id;

  update public.properties
  set report_count = coalesce(total_reports, 0),
      is_reported = coalesce(pending_reports, 0) > 0
  where id = affected_target_id;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.sync_property_report_state() from public, anon, authenticated;

drop trigger if exists reports_sync_property_state on public.reports;
create trigger reports_sync_property_state
after insert or update of status or delete
on public.reports
for each row
execute function public.sync_property_report_state();

commit;
