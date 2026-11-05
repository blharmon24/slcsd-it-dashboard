-- Renewals > Certificates: web/TLS certificate inventory
-- Run once in the Supabase SQL editor.
--
-- One row per certificate. When a cert is renewed, edit the row's dates in place.
-- Removing a cert in the UI sets active = false (soft delete; history preserved).

create table if not exists public.renewal_certificates (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,              -- system / friendly name, e.g. "PowerSchool prod"
  hostnames       text,                       -- CN + SANs, comma-separated
  issuer          text not null default 'other', -- self_signed | internal_ca | digicert | letsencrypt | other
  issued_date     date,
  expires_date    date not null,
  auto_renew      boolean not null default false,
  owner           text,                       -- VG / BH / JF / SQ
  installed_on    text,                       -- server, load balancer, appliance
  notes           text,                       -- standing renewal instructions
  active          boolean not null default true,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now(),
  updated_by      uuid references auth.users,
  updated_by_name text
);

-- Admin-only, matching the other tracker tables (see rls_admin_lockdown.sql)
alter table public.renewal_certificates enable row level security;
drop policy if exists renewal_certificates_admin_only on public.renewal_certificates;
create policy renewal_certificates_admin_only on public.renewal_certificates
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- New tables need explicit Data API grants
grant select, insert, update, delete on public.renewal_certificates to authenticated;
