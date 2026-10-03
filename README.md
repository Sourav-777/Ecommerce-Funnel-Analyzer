# E-commerce Funnel & Cart Abandonment Analyzer

A learning project that simulates an online store, loads its event data into PostgreSQL, and uses SQL to identify funnel loss, customer segments, payment friction, and revenue at risk. Power BI is the presentation layer after the SQL definitions are understood and checked.

The generator is deterministic by default and produces about 300,000 events. It models a lower mobile purchase probability, higher conversion when a discount is offered, category and channel differences, repeat sessions, ordered funnel events, payment retries, and successful purchases linked to orders. It is synthetic data; results are practice findings, not claims about a real business.

## Project map

- `generator/generate_data.py` — creates `users.csv`, `products.csv`, `sessions.csv`, `events.csv`, and `orders.csv` with pandas, NumPy, and Faker.
- `generator/load_data.py` — streams CSV files into PostgreSQL with COPY.
- `sql/00_schema.sql` — relational tables, checks, foreign keys, and useful indexes.
- `sql/01_validation_cleaning.sql` — referential, duplicate, and event-sequence checks plus a cleaned events view.
- `sql/02_analysis_views.sql` — reusable session-level analysis views.
- `sql/analyses/` — eight core business analyses.
- `docs/er-diagram.md` — editable Mermaid ER diagram.
- `docs/power-bi-spec.md` — suggested dashboard model and page layout.

## Run locally

Requires Python 3.10+ and a local PostgreSQL database. pgAdmin can create the database and run the SQL files; the command-line steps below are optional conveniences.

1. Create and activate a virtual environment, then install dependencies:

   ```powershell
   py -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r generator/requirements.txt
   ```

2. Generate the CSVs (default target approximately 300K events; output files are ignored by Git):

   ```powershell
   python generator/generate_data.py --target-events 300000 --output data
   ```

   The generator writes complete sessions, so actual count can vary around the target. It prints the exact table row counts.

3. In pgAdmin, create a database (for example `funnel_analyzer`) and execute `sql/00_schema.sql` in its Query Tool.

4. Load the five CSVs. Either use pgAdmin's Import/Export on each table in dependency order (`users`, `products`, `sessions`, `events`, `orders`), mapping headers to columns, or set a PostgreSQL DSN and use the loader:

   ```powershell
   $env:DATABASE_URL = "postgresql://postgres:YOUR_PASSWORD@localhost:5432/funnel_analyzer"
   python generator/load_data.py --data-dir data
   ```

   To replace an existing dataset, add `--truncate`. Do not run both load methods for the same generated files.

5. Execute `sql/01_validation_cleaning.sql`, then `sql/02_analysis_views.sql`. Review the validation result sets; expected issue counts are zero. Run the eight files under `sql/analyses/` in pgAdmin.

6. Connect Power BI Desktop to PostgreSQL and follow `docs/power-bi-spec.md`.

## What the data means

The grain of `sessions` is one visit; the grain of `events` is one timestamped action. A session may contain multiple views and payment attempts. Funnel reach is session-level: a session counts once at each step if it has at least one matching event. Event sequence is generated in order. Every order points to its purchase event and session. Discount exposure lives on sessions so non-buyers are included in offer conversion comparisons; order discount is the amount deducted from list price.

New vs returning is based on whether the session date is later than the user's first session date in the generated history. Signup date is retained as profile context. Repeat visits are distributed across the user base, so this is a simulated behavioral cohort rather than an identity-resolution claim.

The data generator aims near 300K events rather than truncating at an exact row count: cutting a file at the target could leave a partial session or an order without its purchase event. Use the printed event count in your README or interview story after you generate the data.

## Eight analyses

1. Overall funnel counts, stage conversion, and drop-off.
2. Funnel conversion by device and acquisition channel.
3. Funnel reach and conversion by product category.
4. New vs returning sessions, conversion, and average order value.
5. Cart abandonment and estimated gross revenue at risk.
6. Purchase recovery among sessions with repeated payment attempts.
7. Conversion by discount offer exposure, plus average order value.
8. Daily net revenue and average order value by acquisition channel.

The cart revenue-at-risk query uses observed product list price as an indicative value; it is not a forecast. The payment model records attempts and eventual purchases, not processor response codes, so query 6 measures retry/recovery behavior rather than a true gateway decline rate. The discount comparison is descriptive on simulated data and should not be presented as causal proof.

## Interview walkthrough

**Business problem:** High traffic does not guarantee revenue. The analysis identifies which journey step and customer segments lose the most potential purchases.

**Data model:** Separate user, product, session, event, and order entities. Events record behavior at timestamp grain; orders record money at order grain. Foreign keys keep joins coherent and indexes support frequent session and event filters.

**SQL approach:** First validate keys, relationships, and event order. Then build a reusable one-row-per-session view with boolean step flags. This avoids counting multiple views or payment retries as multiple sessions. Use conditional aggregates for stage counts and `NULLIF` to protect rates from divide-by-zero.

**Business interpretation:** Start with the largest funnel drop, then compare device/channel/category and customer cohorts. Use revenue-at-risk as a prioritization estimate, not committed revenue. Recommend fixes only where the segment has enough volume and the observed difference is large enough to investigate.

**Suggested recommendation format:** “In this generated dataset, [segment] has [rate] conversion vs [comparison rate]. The largest loss occurs between [step A] and [step B]. We estimate [amount] in indicative cart value among abandoned sessions. I would investigate [specific friction] and validate the change with an experiment before forecasting recovered revenue.” Replace bracketed values with outputs from the SQL queries; do not copy fabricated example numbers.

## Resume bullet template

Built a PostgreSQL e-commerce funnel analysis project with a reproducible Python data generator (~300K events), validated relational schema, and eight SQL analyses covering funnel drop-off, device/channel/category segments, repeat behavior, cart abandonment, payment retries, discounts, and revenue trends; outlined a Power BI dashboard for stakeholder reporting.

## Notes

- Generated CSVs are intentionally excluded from version control; recreate them with the documented seed and command.
- SQL targets PostgreSQL. The scripts use PostgreSQL `FILTER`, `BOOL_OR`, `LATERAL`, and window functions.
- No Power BI screenshots or PBIX are included because this environment does not author Power BI files.

## Results from the generated dataset

These results describe the synthetic dataset generated for this project; they are not findings from a real store.

Overall funnel: 125,000 sessions produced 14,563 purchases, for an 11.65% session conversion rate. The largest drop was from product view to add-to-cart: 66.34% of sessions did not reach the cart.

Device: Desktop conversion was 20.97%, compared with 7.05% on mobile and 12.54% on tablet. Mobile checkout-to-purchase conversion was 43.3%, compared with 63.4% on desktop.

Cart abandonment: 27,518 of 42,081 cart sessions were abandoned (65.39%). The $1,649,164 revenue-at-risk figure is an indicative estimate based on observed product list prices, not a forecast.

Discount offers: Sessions offered a discount converted at 18.67%, compared with 8.48% without an offer. Average order value was $54.40 for discounted orders and $60.29 for orders without a discount.

Revenue: Net revenue was approximately $835,302, with an average order value of $57.36.

## Interpretation and limitations

The simulated results suggest investigating mobile checkout and the tradeoff between discount-driven conversion and average order value. The discount comparison is descriptive of this synthetic dataset; it does not establish the effect a discount would have in a real store. The generated date range also creates a synthetic trend shape, so it should not be interpreted as real seasonality. Payment events record attempts and purchases, but not processor decline codes.

