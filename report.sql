-- Итоги летнего сезона 2026
with
    -- отчётный период: [1 июня - 1 октября)
    period as (
        select
            date '2026-06-01' as p_start,
            date '2026-10-01' as p_end
    ),
    -- ночи каждой неотменённой брони внутри периода
    stays as (
        select
            r.hotel_id,
            b.booking_id,
            least (b.check_out, p.p_end) - greatest (b.check_in, p.p_start) as nights,
            b.price_per_night
        from
            booking b
            join room r on r.room_id = b.room_id
            cross join period p
        where
            b.status <> 'cancelled'
            and b.check_in < p.p_end
            and b.check_out > p.p_start
    ),
    -- отменённые брони с заездом в периоде
    cancels as (
        select
            r.hotel_id,
            count(*) as cancelled
        from
            booking b
            join room r on r.room_id = b.room_id
            cross join period p
        where
            b.status = 'cancelled'
            and b.check_in >= p.p_start
            and b.check_in < p.p_end
        group by
            r.hotel_id
    ),
    -- число номеров и доступные номеро-ночи за период
    capacity as (
        select
            r.hotel_id,
            count(*) as rooms,
            count(*) * (p.p_end - p.p_start) as room_nights
        from
            room r
            cross join period p
        group by
            r.hotel_id,
            p.p_end,
            p.p_start
    ),
    -- агрегация по гостинице
    hotel_stats as (
        select
            h.hotel_id,
            h.name,
            h.stars,
            coalesce(c.rooms, 0) as rooms,
            coalesce(c.room_nights, 0) as room_nights,
            count(s.booking_id) as stays,
            coalesce(sum(s.nights), 0) as sold_nights,
            coalesce(sum(s.nights * s.price_per_night), 0) as revenue,
            coalesce(x.cancelled, 0) as cancelled
        from
            hotel h
            left join capacity c on c.hotel_id = h.hotel_id
            left join stays s on s.hotel_id = h.hotel_id
            left join cancels x on x.hotel_id = h.hotel_id
        group by
            h.hotel_id,
            h.name,
            h.stars,
            c.rooms,
            c.room_nights,
            x.cancelled
    )
    -- Итог
select
    name as hotel,
    stars,
    rooms,
    stays,
    sold_nights,
    room_nights,
    round(100.0 * sold_nights / nullif(room_nights, 0), 1) as occupancy_pct,
    revenue,
    round(revenue / nullif(sold_nights, 0), 2) as adr,
    round(revenue / nullif(room_nights, 0), 2) as revpar,
    round(
        100.0 * cancelled / nullif(stays + cancelled, 0),
        1
    ) as cancel_pct,
    round(
        100.0 * revenue / nullif(sum(revenue) over (), 0),
        1
    ) as revenue_share_pct,
    rank() over (
        order by
            revenue / nullif(room_nights, 0) desc nulls last
    ) as revpar_rank
from
    hotel_stats
order by
    revpar_rank,
    name;