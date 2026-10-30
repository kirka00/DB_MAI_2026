-- Гостиница
create table
    hotel (
        hotel_id bigint generated always as identity primary key,
        name text not null,
        city text not null,
        address text not null,
        stars integer not null check (stars between 1 and 5),
        unique (city, address)
    );

-- Тип номера
create table
    room_type (
        room_type_id bigint generated always as identity primary key,
        name text not null unique,
        capacity integer not null check (capacity > 0)
    );

-- Номер в гостинице
create table
    room (
        room_id bigint generated always as identity primary key,
        hotel_id bigint not null references hotel (hotel_id) on delete cascade,
        room_type_id bigint not null references room_type (room_type_id) on delete restrict,
        room_number varchar(10) not null,
        price_per_night numeric(10, 2) not null check (price_per_night > 0),
        unique (hotel_id, room_number)
    );

-- Гость
create table
    guest (
        guest_id bigint generated always as identity primary key,
        full_name text not null,
        passport varchar(20) not null unique,
        email text unique,
        phone varchar(20) not null
    );

-- Бронирование
create table
    booking (
        booking_id bigint generated always as identity primary key,
        guest_id bigint not null references guest (guest_id) on delete restrict,
        room_id bigint not null references room (room_id) on delete restrict,
        check_in date not null,
        check_out date not null,
        guests_count integer not null check (guests_count > 0),
        price_per_night numeric(10, 2) not null check (price_per_night > 0),
        status varchar(12) not null default 'pending' check (
            status in ('pending', 'confirmed', 'cancelled', 'completed')
        ),
        created_dt timestamptz not null default now (),
        check (check_out > check_in)
    );

-- Оплата
create table
    payment (
        payment_id bigint generated always as identity primary key,
        booking_id bigint not null references booking (booking_id) on delete restrict,
        amount numeric(10, 2) not null check (amount > 0),
        method varchar(10) not null check (method in ('card', 'cash')),
        paid_dt timestamptz not null default now ()
    );