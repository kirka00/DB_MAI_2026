-- в рамках одного заказа можно забронировать несколько номеров,
-- в одной брони может жить несколько гостей.
begin;

create table
    orders (
        order_id bigint generated always as identity primary key,
        guest_id bigint not null references guest (guest_id) on delete restrict,
        created_dt timestamptz not null default now ()
    );

alter table booking
add column order_id bigint references orders (order_id) on delete restrict;

alter table orders
add column tmp_booking_id bigint;

insert into
    orders (guest_id, created_dt, tmp_booking_id)
select
    guest_id,
    created_dt,
    booking_id
from
    booking;

update booking b
set
    order_id = (
        select
            o.order_id
        from
            orders o
        where
            o.tmp_booking_id = b.booking_id
    );

alter table orders
drop column tmp_booking_id;

alter table booking
alter column order_id
set
    not null;

create table
    booking_guest (
        booking_id bigint not null references booking (booking_id) on delete cascade,
        guest_id bigint not null references guest (guest_id) on delete restrict,
        primary key (booking_id, guest_id)
    );

insert into
    booking_guest (booking_id, guest_id)
select
    booking_id,
    guest_id
from
    booking;

insert into
    guest (full_name, passport, phone)
values
    (
        'Иванова Ольга Петровна',
        '4511 100001',
        '+79160000001'
    ),
    (
        'Смирнова Елена Игоревна',
        '4511 100002',
        '+79160000002'
    ),
    (
        'Кузнецов Андрей Олегович',
        '4511 100003',
        '+79160000003'
    ),
    (
        'Иванов Пётр Иванович',
        '4511 100004',
        '+79160000004'
    ),
    (
        'Иванова Анна Ивановна',
        '4511 100005',
        '+79160000005'
    ),
    (
        'Соколова Ирина Викторовна',
        '4511 100006',
        '+79160000006'
    ),
    (
        'Петров Сергей Николаевич',
        '4511 100007',
        '+79160000007'
    ),
    (
        'Петрова Дарья Сергеевна',
        '4511 100008',
        '+79160000008'
    ),
    (
        'Петров Максим Сергеевич',
        '4511 100009',
        '+79160000009'
    );

insert into
    booking_guest (booking_id, guest_id)
values
    (
        1,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100001'
        )
    ),
    (
        3,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100002'
        )
    ),
    (
        4,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100003'
        )
    ),
    (
        6,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100004'
        )
    ),
    (
        6,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100005'
        )
    ),
    (
        7,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100006'
        )
    ),
    (
        8,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100007'
        )
    ),
    (
        8,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100008'
        )
    ),
    (
        8,
        (
            select
                guest_id
            from
                guest
            where
                passport = '4511 100009'
        )
    );

alter table booking
drop column guests_count;

alter table booking
drop column guest_id;

commit;