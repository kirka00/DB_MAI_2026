-- Операции изменения данных
begin;

insert into
  guest (full_name, passport, email, phone)
values
  (
    'Никитин Роман Алексеевич',
    '4523 310001',
    'nikitin@mail.ru',
    '+79031230101'
  );

insert into
  orders (guest_id, created_dt)
select
  guest_id,
  '2026-10-26 12:00+03'
from
  guest
where
  passport = '4523 310001';

insert into
  booking (
    order_id,
    room_id,
    check_in,
    check_out,
    price_per_night,
    status,
    created_dt
  )
select
  o.order_id,
  r.room_id,
  '2026-11-27',
  '2026-11-30',
  r.price_per_night,
  'pending',
  o.created_dt
from
  orders o
  join guest g on g.guest_id = o.guest_id
  join room r on r.hotel_id = 1
  and r.room_number = '103'
where
  g.passport = '4523 310001';

insert into
  booking_guest (booking_id, guest_id)
select
  b.booking_id,
  o.guest_id
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
where
  g.passport = '4523 310001';

insert into
  payment (booking_id, amount, method, paid_dt)
select
  b.booking_id,
  6500.00,
  'card',
  '2026-10-26 12:05+03'
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
where
  g.passport = '4523 310001';

commit;

-- проверка: новая бронь со всеми связанными данными
select
  b.booking_id,
  g.full_name,
  h.name as hotel,
  r.room_number,
  b.check_in,
  b.check_out,
  b.price_per_night,
  b.status,
  p.amount as paid
from
  booking b
  join orders o on o.order_id = b.order_id
  join guest g on g.guest_id = o.guest_id
  join room r on r.room_id = b.room_id
  join hotel h on h.hotel_id = r.hotel_id
  join payment p on p.booking_id = b.booking_id
where
  g.passport = '4523 310001';

-- UPDATE: бронь 4 завершена
update booking
set
  status = 'completed'
where
  booking_id = 4
  and status = 'confirmed';

select
  booking_id,
  check_in,
  check_out,
  status
from
  booking
where
  booking_id = 4;

-- Массовый UPDATE: цены «Невского» +10%, цены в бронях не меняются
update room r
set
  price_per_night = round(r.price_per_night * 1.10, 2)
from
  hotel h
where
  h.hotel_id = r.hotel_id
  and h.name = 'Невский';

select
  r.room_number,
  r.price_per_night as catalog_price,
  b.booking_id,
  b.price_per_night as booked_price
from
  room r
  join hotel h on h.hotel_id = r.hotel_id
  left join booking b on b.room_id = r.room_id
  and b.status in ('pending', 'confirmed')
where
  h.name = 'Невский'
order by
  r.room_number;

-- delete брони с платежом (ожидаемая ошибка - on delete restrict)
delete from booking
where
  booking_id = 20;

-- delete неоплаченной брони (booking_guest удаляется каскадно)
select
  count(*) as guests_before
from
  booking_guest
where
  booking_id = 33;

begin;

delete from booking
where
  booking_id = 33;

delete from orders o
where
  o.order_id = 32
  and not exists (
    select
      1
    from
      booking b
    where
      b.order_id = o.order_id
  );

commit;

select
  count(*) as guests_after
from
  booking_guest
where
  booking_id = 33;

-- rollback: update без where отменяется
select
  status,
  count(*)
from
  booking
group by
  status
order by
  status;

begin;

update booking
set
  status = 'cancelled';

select
  status,
  count(*)
from
  booking
group by
  status
order by
  status;

rollback;

select
  status,
  count(*)
from
  booking
group by
  status
order by
  status;