-- PressLedger: Sistem Akuntansi Modal, Prive, dan Laporan Perubahan Ekuitas
-- Jalankan seluruh file ini di Supabase SQL Editor.

create extension if not exists pgcrypto;

do $$ begin
  create type public.jenis_transaksi_modal as enum ('setoran', 'prive', 'laba', 'rugi');
exception when duplicate_object then null;
end $$;

create table if not exists public.pemilik (
  id uuid primary key default gen_random_uuid(),
  nama text not null check (char_length(trim(nama)) >= 2),
  created_at timestamptz not null default now()
);

create table if not exists public.transaksi_modal (
  id uuid primary key default gen_random_uuid(),
  pemilik_id uuid references public.pemilik(id) on update cascade on delete restrict,
  tanggal date not null default current_date,
  jenis public.jenis_transaksi_modal not null,
  jumlah numeric(18,2) not null check (jumlah >= 0),
  keterangan text,
  no_bukti text,
  created_at timestamptz not null default now()
);

alter table public.transaksi_modal alter column pemilik_id drop not null;

create table if not exists public.periode_laporan (
  id uuid primary key default gen_random_uuid(),
  nama_periode text not null,
  modal_awal numeric(18,2) not null default 0 check (modal_awal >= 0),
  modal_akhir numeric(18,2) not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists transaksi_modal_pemilik_id_idx on public.transaksi_modal(pemilik_id);
create index if not exists transaksi_modal_tanggal_idx on public.transaksi_modal(tanggal);
create index if not exists transaksi_modal_jenis_idx on public.transaksi_modal(jenis);

-- Hitung modal akhir tanpa trigger rekursif.
create or replace function public.calculate_period_modal_akhir()
returns trigger language plpgsql as $$
declare
  month_number integer;
  period_year integer;
begin
  month_number := case lower(split_part(trim(new.nama_periode), ' ', 1))
    when 'januari' then 1 when 'februari' then 2 when 'maret' then 3
    when 'april' then 4 when 'mei' then 5 when 'juni' then 6
    when 'juli' then 7 when 'agustus' then 8 when 'september' then 9
    when 'oktober' then 10 when 'november' then 11 when 'desember' then 12
    else null end;
  period_year := nullif(split_part(trim(new.nama_periode), ' ', 2), '')::integer;
  if month_number is not null and period_year is not null then
    select new.modal_awal + coalesce(sum(case when jenis = 'setoran' then jumlah when jenis = 'prive' then -jumlah when jenis = 'laba' then jumlah when jenis = 'rugi' then -jumlah end), 0)
      into new.modal_akhir from public.transaksi_modal
      where extract(month from tanggal) = month_number and extract(year from tanggal) = period_year;
  else
    new.modal_akhir := new.modal_awal;
  end if;
  return new;
end $$;

create or replace function public.refresh_all_period_modal_akhir()
returns trigger language plpgsql as $$
begin
  update public.periode_laporan period
  set modal_akhir = period.modal_awal + coalesce((
    select sum(case when transaction_row.jenis = 'setoran' then transaction_row.jumlah when transaction_row.jenis = 'prive' then -transaction_row.jumlah when transaction_row.jenis = 'laba' then transaction_row.jumlah when transaction_row.jenis = 'rugi' then -transaction_row.jumlah end)
    from public.transaksi_modal transaction_row
    where extract(year from transaction_row.tanggal) = nullif(split_part(trim(period.nama_periode), ' ', 2), '')::integer
      and extract(month from transaction_row.tanggal) = case lower(split_part(trim(period.nama_periode), ' ', 1))
        when 'januari' then 1 when 'februari' then 2 when 'maret' then 3
        when 'april' then 4 when 'mei' then 5 when 'juni' then 6
        when 'juli' then 7 when 'agustus' then 8 when 'september' then 9
        when 'oktober' then 10 when 'november' then 11 when 'desember' then 12
        else null end
  ), 0)
  where period.id is not null;
  return null;
end $$;

drop trigger if exists transaksi_modal_refresh_period on public.transaksi_modal;
create trigger transaksi_modal_refresh_period after insert or update or delete on public.transaksi_modal for each statement execute function public.refresh_all_period_modal_akhir();
drop trigger if exists periode_refresh_modal on public.periode_laporan;
drop trigger if exists periode_calculate_modal on public.periode_laporan;
create trigger periode_calculate_modal before insert or update of nama_periode, modal_awal on public.periode_laporan for each row execute function public.calculate_period_modal_akhir();

-- RLS aktif agar tabel tidak terbuka tanpa policy.
alter table public.pemilik enable row level security;
alter table public.transaksi_modal enable row level security;
alter table public.periode_laporan enable row level security;

-- Policy ini cocok untuk aplikasi internal dengan anon key.
-- Untuk produksi, ganti dengan policy berbasis autentikasi pengguna.
drop policy if exists "public read pemilik" on public.pemilik;
create policy "public read pemilik" on public.pemilik for select using (true);
drop policy if exists "public insert pemilik" on public.pemilik;
create policy "public insert pemilik" on public.pemilik for insert with check (true);
drop policy if exists "public update pemilik" on public.pemilik;
create policy "public update pemilik" on public.pemilik for update using (true) with check (true);
drop policy if exists "public delete pemilik" on public.pemilik;
create policy "public delete pemilik" on public.pemilik for delete using (true);

drop policy if exists "public read transaksi_modal" on public.transaksi_modal;
create policy "public read transaksi_modal" on public.transaksi_modal for select using (true);
drop policy if exists "public insert transaksi_modal" on public.transaksi_modal;
create policy "public insert transaksi_modal" on public.transaksi_modal for insert with check (true);
drop policy if exists "public update transaksi_modal" on public.transaksi_modal;
create policy "public update transaksi_modal" on public.transaksi_modal for update using (true) with check (true);
drop policy if exists "public delete transaksi_modal" on public.transaksi_modal;
create policy "public delete transaksi_modal" on public.transaksi_modal for delete using (true);

drop policy if exists "public read periode_laporan" on public.periode_laporan;
create policy "public read periode_laporan" on public.periode_laporan for select using (true);
drop policy if exists "public insert periode_laporan" on public.periode_laporan;
create policy "public insert periode_laporan" on public.periode_laporan for insert with check (true);
drop policy if exists "public update periode_laporan" on public.periode_laporan;
create policy "public update periode_laporan" on public.periode_laporan for update using (true) with check (true);
drop policy if exists "public delete periode_laporan" on public.periode_laporan;
create policy "public delete periode_laporan" on public.periode_laporan for delete using (true);

-- View siap pakai untuk ringkasan mutasi per bulan.
create or replace view public.ringkasan_perubahan_ekuitas as
select
  date_trunc('month', tanggal)::date as bulan,
  coalesce(sum(jumlah) filter (where jenis = 'setoran'), 0) as setoran,
  coalesce(sum(jumlah) filter (where jenis = 'prive'), 0) as prive,
  coalesce(sum(jumlah) filter (where jenis = 'laba'), 0) as laba,
  coalesce(sum(jumlah) filter (where jenis = 'rugi'), 0) as rugi
from public.transaksi_modal
group by date_trunc('month', tanggal);
