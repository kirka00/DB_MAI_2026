-- Запросы
-- журнал броней с заездом в октябре 2026
select
  b.booking_id,
  h.name as hotel,
  r.room_number,
  rt.name as room_type,
  g.full_name as customer,
  b.check_in,
  b.check_out,
  b.check_out - b.check_in as nights,
  (b.check_out - b.check_in) * b.price_per_night as total,
  b.status
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
  join room r on r.room_id = b.room_id
  join hotel h on h.hotel_id = r.hotel_id
  join room_type rt on rt.room_type_id = r.room_type_id
where
  b.check_in >= date '2026-10-01'
  and b.check_in < date '2026-11-01'
order by
  b.check_in,
  b.booking_id;

-- номера без броней (left join)
select
  h.name as hotel,
  h.city,
  r.room_number,
  rt.name as room_type,
  r.price_per_night
from
  room r
  join hotel h on h.hotel_id = r.hotel_id
  join room_type rt on rt.room_type_id = r.room_type_id
  left join booking b on b.room_id = r.room_id
  and b.status <> 'cancelled'
where
  b.booking_id is null
order by
  h.name,
  r.room_number;

-- гости, жившие летом в номере от 3 мест в гостинице от 4 звёзд
select distinct
  g.full_name,
  g.phone,
  h.name as hotel,
  h.stars,
  rt.name as room_type,
  b.check_in
from
  guest g
  join booking_guest bg on bg.guest_id = g.guest_id
  join booking b on b.booking_id = bg.booking_id
  join room r on r.room_id = b.room_id
  join room_type rt on rt.room_type_id = r.room_type_id
  join hotel h on h.hotel_id = r.hotel_id
where
  b.status = 'completed'
  and b.check_in >= date '2026-06-01'
  and b.check_in < date '2026-09-01'
  and rt.capacity >= 3
  and h.stars >= 4
order by
  b.check_in,
  g.full_name;

-- брони по гостиницам и статусам
select
  h.name as hotel,
  count(distinct r.room_id) as rooms,
  count(b.booking_id) as bookings,
  count(*) filter (
    where
      b.status = 'completed'
  ) as completed,
  count(*) filter (
    where
      b.status in ('pending', 'confirmed')
  ) as active,
  count(*) filter (
    where
      b.status = 'cancelled'
  ) as cancelled,
  count(distinct b.order_id) as orders
from
  hotel h
  left join room r on r.hotel_id = h.hotel_id
  left join booking b on b.room_id = r.room_id
group by
  h.hotel_id,
  h.name
order by
  bookings desc,
  h.name;

-- клиенты, заплатившие от 50 000 ₽ (having)
select
  g.full_name,
  count(distinct o.order_id) as orders,
  count(p.payment_id) as payments,
  sum(p.amount) as total_paid,
  round(avg(p.amount), 2) as avg_payment,
  max(p.amount) as max_payment
from
  guest g
  join orders o on o.guest_id = g.guest_id
  join booking b on b.order_id = o.order_id
  join payment p on p.booking_id = b.booking_id
group by
  g.guest_id,
  g.full_name
having
  sum(p.amount) >= 50000
order by
  total_paid desc;

-- сравнение месяцев
select
  to_char (date_trunc ('month', b.check_in), 'YYYY-MM') as month,
  count(*) as bookings,
  sum(b.check_out - b.check_in) as nights,
  sum((b.check_out - b.check_in) * b.price_per_night) as revenue,
  round(avg(b.price_per_night), 2) as avg_price,
  min(b.price_per_night) as min_price,
  max(b.price_per_night) as max_price
from
  booking b
where
  b.status <> 'cancelled'
group by
  date_trunc ('month', b.check_in)
order by
  month;

-- брони дороже средней по своей гостинице
select
  h.name as hotel,
  b.booking_id,
  (b.check_out - b.check_in) * b.price_per_night as total,
  round(a.avg_total, 2) as hotel_avg
from
  booking b
  join room r on r.room_id = b.room_id
  join hotel h on h.hotel_id = r.hotel_id
  join (
    select
      r2.hotel_id,
      avg((b2.check_out - b2.check_in) * b2.price_per_night) as avg_total
    from
      booking b2
      join room r2 on r2.room_id = b2.room_id
    where
      b2.status <> 'cancelled'
    group by
      r2.hotel_id
  ) a on a.hotel_id = r.hotel_id
where
  b.status <> 'cancelled'
  and (b.check_out - b.check_in) * b.price_per_night > a.avg_total
order by
  h.name,
  total desc;

-- кому вернуть предоплату за отменённую бронь
select
  g.full_name,
  g.phone,
  g.email
from
  guest g
where
  exists (
    select
      1
    from
      orders o
      join booking b on b.order_id = o.order_id
      join payment p on p.booking_id = b.booking_id
    where
      o.guest_id = g.guest_id
      and b.status = 'cancelled'
  )
order by
  g.full_name;

-- подтверждённые брони без оплаты
select
  b.booking_id,
  g.full_name as customer,
  g.phone,
  h.name as hotel,
  b.check_in,
  (b.check_out - b.check_in) * b.price_per_night as total
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
  join room r on r.room_id = b.room_id
  join hotel h on h.hotel_id = r.hotel_id
where
  b.status = 'confirmed'
  and not exists (
    select
      1
    from
      payment p
    where
      p.booking_id = b.booking_id
  )
order by
  b.check_in;

-- коррелированный подзапрос: долги по завершённым броням
select
  b.booking_id,
  g.full_name as customer,
  (b.check_out - b.check_in) * b.price_per_night as total,
  (
    select
      coalesce(sum(p.amount), 0)
    from
      payment p
    where
      p.booking_id = b.booking_id
  ) as paid,
  (b.check_out - b.check_in) * b.price_per_night - (
    select
      coalesce(sum(p.amount), 0)
    from
      payment p
    where
      p.booking_id = b.booking_id
  ) as debt
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
where
  b.status = 'completed'
  and (
    select
      coalesce(sum(p.amount), 0)
    from
      payment p
    where
      p.booking_id = b.booking_id
  ) < (b.check_out - b.check_in) * b.price_per_night
order by
  debt desc;