-- =====================================================================
-- CUT Clinic Appointment Management System - Supabase schema (prototype)
-- Run this whole file once in: Supabase Dashboard -> SQL Editor -> New query
-- Matches the Phase 2 ERD (Student, Staff, Appointment, Appointment_Status,
-- Notification). Document is omitted (optional in the ERD).
-- =====================================================================

-- ---------- Lookup: appointment statuses ----------
create table if not exists public.appointment_statuses (
  status    text primary key,
  label     text not null,
  is_active boolean not null default false
);

insert into public.appointment_statuses (status, label, is_active) values
  ('pending',   'Pending review', true),
  ('approved',  'Approved',       true),
  ('rejected',  'Not approved',   false),
  ('cancelled', 'Cancelled',      false),
  ('completed', 'Completed',      false)   -- frees the student's "one active" slot after the visit
on conflict (status) do nothing;

-- ---------- Students ----------
create table if not exists public.students (
  student_id     uuid primary key references auth.users(id) on delete cascade,
  first_name     text not null,
  last_name      text not null,
  email          text not null,
  phone          text not null,
  student_number text not null unique check (student_number ~ '^[0-9]{9}$'),
  registration_proof_path text   -- only used if proof upload is implemented
);

-- ---------- Staff ----------
-- Matches the staff table the web developer already created in Supabase:
-- staff_id is a bigint; the Supabase login is linked through auth_user_id.
create table if not exists public.staff (
  staff_id     bigint generated always as identity primary key,
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  full_name    varchar not null,
  email        varchar not null,
  phone_number varchar,
  created_at   timestamptz not null default now()
);

-- ---------- Appointments ----------
create table if not exists public.appointments (
  appointment_id   uuid primary key default gen_random_uuid(),   -- IR26
  student_id       uuid not null references public.students(student_id) on delete cascade,
  appointment_date date,            -- assigned by staff (null until then)
  appointment_time time,
  status           text not null default 'pending'
                   references public.appointment_statuses(status),
  notes            text,            -- student's brief reason
  created_at       timestamptz not null default now(),   -- FR9
  updated_at       timestamptz not null default now(),
  constraint slot_complete   check ((appointment_date is null) = (appointment_time is null)),
  constraint approved_has_slot check (status <> 'approved' or appointment_date is not null)
);

-- FR14 / NFR24: a student can have only ONE active appointment (history allowed).
create unique index if not exists one_active_appointment_per_student
  on public.appointments (student_id) where status in ('pending', 'approved');

-- FR13: no two approved appointments in the same slot.
create unique index if not exists no_double_booked_slot
  on public.appointments (appointment_date, appointment_time) where status = 'approved';

create index if not exists appointments_student_idx on public.appointments (student_id, created_at desc);

-- ---------- Notifications ----------
create table if not exists public.notifications (
  notification_id uuid primary key default gen_random_uuid(),
  student_id      uuid not null references public.students(student_id) on delete cascade,
  appointment_id  uuid references public.appointments(appointment_id) on delete set null,
  type            text not null check (type in ('SMS', 'Email')),
  message         text not null,
  status          text not null default 'queued' check (status in ('queued', 'sent', 'failed')),
  created_at      timestamptz not null default now(),
  sent_at         timestamptz           -- set by the delivery worker (IR28/IR29)
);
create index if not exists notifications_student_idx on public.notifications (student_id, created_at desc);

-- ---------- updated_at maintenance ----------
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_appointments_touch on public.appointments;
create trigger trg_appointments_touch before update on public.appointments
  for each row execute function public.touch_updated_at();

-- ---------- Helper: is the caller clinic staff? ----------
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where auth_user_id = auth.uid());
$$;

-- ---------- Registration: create the student row from sign-up metadata ----------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.raw_user_meta_data ? 'student_number'
     and coalesce(new.raw_user_meta_data->>'account_type', 'student') = 'student' then
    insert into public.students (student_id, first_name, last_name, email, phone, student_number)
    values (
      new.id,
      new.raw_user_meta_data->>'first_name',
      new.raw_user_meta_data->>'last_name',
      new.email,
      new.raw_user_meta_data->>'phone',
      new.raw_user_meta_data->>'student_number'
    );
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- RPC: student requests an appointment (FR8, FR9, FR14) ----------
create or replace function public.request_appointment(p_notes text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Please log in first.';
  end if;
  if not exists (select 1 from public.students where student_id = auth.uid()) then
    raise exception 'Only registered CUT students can request appointments.';
  end if;
  if p_notes is null or length(trim(p_notes)) < 5 then
    raise exception 'Please give a short reason for your visit.';
  end if;
  if exists (select 1 from public.appointments
             where student_id = auth.uid() and status in ('pending', 'approved')) then
    raise exception 'You already have an active appointment. Cancel it before requesting a new one.';
  end if;

  insert into public.appointments (student_id, notes)
  values (auth.uid(), left(trim(p_notes), 300))
  returning appointment_id into v_id;
  return v_id;
end $$;

-- ---------- RPC: student cancels own appointment (FR17) ----------
create or replace function public.cancel_appointment(p_appointment_id uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.appointments
     set status = 'cancelled'
   where appointment_id = p_appointment_id
     and student_id = auth.uid()
     and status in ('pending', 'approved');
  if not found then
    raise exception 'This appointment cannot be cancelled.';
  end if;
end $$;

-- ---------- Notification records on appointment events (FR20-FR23, FR25) ----------
-- This QUEUES SMS + Email rows. Actual delivery is done by an external worker /
-- Edge Function (or simulated for the demo) which marks rows 'sent' / 'failed'.
-- A failed notification never changes the appointment (IR28).
create or replace function public.queue_appointment_notifications() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_msg  text;
  v_when text;
begin
  if tg_op = 'INSERT' then
    v_msg := 'Your clinic appointment request has been received. Staff will assign a date and time.';
  else
    if new.appointment_date is not null then
      v_when := to_char(new.appointment_date, 'DD Mon YYYY') || ' at ' || to_char(new.appointment_time, 'HH24:MI');
    end if;

    if new.status is distinct from old.status then
      v_msg := case new.status
        when 'approved'  then 'Your clinic appointment has been approved for ' || coalesce(v_when, 'a date to be confirmed') || '.'
        when 'rejected'  then 'Your clinic appointment request was not approved. Please contact the clinic for help.'
        when 'cancelled' then 'Your clinic appointment has been cancelled.'
        else null
      end;
    elsif new.status = 'approved'
          and (new.appointment_date, new.appointment_time)
              is distinct from (old.appointment_date, old.appointment_time) then
      v_msg := 'Your clinic appointment has been rescheduled to ' || v_when || '.';
    end if;
  end if;

  if v_msg is not null then
    insert into public.notifications (student_id, appointment_id, type, message)
    select new.student_id, new.appointment_id, t, v_msg
    from unnest(array['SMS', 'Email']) as t;
  end if;
  return new;
end $$;

drop trigger if exists trg_appointment_notify on public.appointments;
create trigger trg_appointment_notify after insert or update on public.appointments
  for each row execute function public.queue_appointment_notifications();

-- ---------- Day-before reminders (FR24, IR21-IR23, NFR37) ----------
-- Duplicate-safe: the same reminder is never queued twice for an appointment.
create or replace function public.queue_day_before_reminders() returns integer
language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  insert into public.notifications (student_id, appointment_id, type, message)
  select a.student_id, a.appointment_id, t.type,
         'Reminder: you have a clinic appointment tomorrow, '
           || to_char(a.appointment_date, 'DD Mon YYYY') || ' at '
           || to_char(a.appointment_time, 'HH24:MI') || '.'
  from public.appointments a
  cross join (values ('SMS'), ('Email')) as t(type)
  where a.status = 'approved'
    and a.appointment_date = ((now() at time zone 'Africa/Johannesburg')::date + 1)
    and not exists (
      select 1 from public.notifications n
      where n.appointment_id = a.appointment_id
        and n.type = t.type
        and n.message = 'Reminder: you have a clinic appointment tomorrow, '
              || to_char(a.appointment_date, 'DD Mon YYYY') || ' at '
              || to_char(a.appointment_time, 'HH24:MI') || '.'
    );
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- Schedule daily at 15:00 UTC (17:00 SAST). Enable the pg_cron extension first
-- (Dashboard -> Database -> Extensions), then uncomment:
-- select cron.schedule('clinic-day-before-reminders', '0 15 * * *',
--                      $$ select public.queue_day_before_reminders(); $$);
-- For a live demo you can simply run:  select public.queue_day_before_reminders();

-- ---------- Row Level Security (NFR1-NFR3, NFR9, IR13-IR16) ----------
alter table public.appointment_statuses enable row level security;
alter table public.students            enable row level security;
alter table public.staff               enable row level security;
alter table public.appointments        enable row level security;
alter table public.notifications       enable row level security;

drop policy if exists statuses_read on public.appointment_statuses;
create policy statuses_read on public.appointment_statuses
  for select to authenticated using (true);

drop policy if exists students_select on public.students;
create policy students_select on public.students
  for select to authenticated using (student_id = auth.uid() or public.is_staff());

drop policy if exists staff_select_self on public.staff;
create policy staff_select_self on public.staff
  for select to authenticated using (auth_user_id = auth.uid() or public.is_staff());

-- Students can READ only their own appointments. All student writes go through
-- the RPC functions above (no direct insert/update/delete policy for students).
drop policy if exists appointments_select on public.appointments;
create policy appointments_select on public.appointments
  for select to authenticated using (student_id = auth.uid() or public.is_staff());

drop policy if exists appointments_staff_update on public.appointments;
create policy appointments_staff_update on public.appointments
  for update to authenticated using (public.is_staff()) with check (public.is_staff());

drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select to authenticated using (student_id = auth.uid() or public.is_staff());

-- ---------- Function permissions ----------
revoke all on function public.request_appointment(text)        from public, anon;
revoke all on function public.cancel_appointment(uuid)         from public, anon;
revoke all on function public.queue_day_before_reminders()     from public, anon, authenticated;
grant execute on function public.request_appointment(text)     to authenticated;
grant execute on function public.cancel_appointment(uuid)      to authenticated;
grant execute on function public.queue_day_before_reminders()  to service_role;

-- ---------- Realtime: lets the app update live when staff change things ----------
alter publication supabase_realtime add table public.appointments;
alter publication supabase_realtime add table public.notifications;

-- =====================================================================
-- CREATING A STAFF ACCOUNT (for the web team / demo)
-- 1. Dashboard -> Authentication -> Users -> Add user (email + password).
-- 2. Copy that user's UUID and run (replace the values):
--
-- insert into public.staff (auth_user_id, full_name, email)
-- values ('PASTE-USER-UUID', 'Clinic Nurse', 'nurse@example.com');
--
-- Staff can then approve/reject/reschedule by updating public.appointments:
--   update public.appointments
--      set status = 'approved', appointment_date = '2026-10-21', appointment_time = '09:30'
--    where appointment_id = '...';
-- =====================================================================