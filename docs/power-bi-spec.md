# Power BI dashboard build specification

Connect Power BI Desktop to PostgreSQL after generating and loading the data. Import the five source tables and the three session views (`v_session_funnel`, `v_session_product`, `v_session_order`). Keep SQL as the source of truth for definitions; the saved analyses under `sql/analyses/` provide the first validated result sets.

## Suggested model

- Use `sessions[session_id]` as the central grain. Relate users one-to-many to sessions, sessions one-to-many to events and orders, and products one-to-many to events.
- Set cross-filter direction to single wherever possible. Avoid joining raw events directly to orders in a way that multiplies revenue.
- Add a date table and relate it to `sessions[start_time]` (active) and optionally `users[signup_date]` (inactive).

## Page 1 — Funnel overview

- KPI cards: sessions, purchasers, session conversion, orders, net revenue, average order value.
- Funnel visual: viewed → cart → checkout → payment attempt → purchase from `v_session_funnel`.
- Trend line: daily sessions and conversion.
- Slicers: date, device, acquisition channel, new/returning.

## Page 2 — Where customers drop

- Matrix of device × channel with sessions, purchases, conversion, and checkout-to-purchase rate.
- Bar chart: conversion by product category.
- Bar chart: new vs returning session conversion and AOV.
- Use denominators explicitly in tooltips so low-volume segments are not overinterpreted.

## Page 3 — Cart and payment friction

- Cards: cart sessions, abandoned cart rate, estimated value at risk, payment-attempt sessions.
- Funnel filtered to cart sessions.
- Compare conversion for one vs multiple payment attempts; note this is a retry/recovery proxy because the source model records attempts but does not include a processor response code.
- Explain that estimated cart value is a proxy based on observed product price, not a booked revenue forecast.

## Page 4 — Offer and revenue

- Compare session conversion by `discount_offered` and show order-level discount, net revenue, and AOV.
- Revenue trend by channel and category.
- Clearly label discount findings as simulated association, not causal lift: offer assignment is randomized in this synthetic dataset, but no controlled experiment design is represented.

The repository contains no Power BI file or screenshot; this page plan is intended to be implemented in Power BI Desktop.
