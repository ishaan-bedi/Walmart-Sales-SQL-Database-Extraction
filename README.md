readme = """# Financial Reports Projects — Retail Sales (Walmart-Style) SQL Analysis

This repository documents the SQL used to explore a multi-table weekly retail sales dataset and outlines the insights each query is designed to produce. It also describes how to run the analysis, expected outputs, assumptions, and next steps.

> **Scope**: Compare factors in weekly sales across stores and departments and relate them to store attributes and macro features (temperature, fuel, CPI, unemployment). The analytical window is designed to support both descriptive reporting and model-ready aggregates (e.g., rolling averages, YoY growth, holiday impacts).

---

## Dataset & Schema

- **`sales`** — Weekly records by `Store`, `Dept`, `Date` with `Weekly_Sales`, `IsHoliday` (boolean-like text).
- **`stores`** — One row per store with `Store`, `Category` (e.g., Type A/B/C), and `Size` (floor area).
- **`features`** — Weekly exogenous features by `Store`, `Date`, including `Temperature`, `Fuel_Price`, `CPI`, `Unemployment`, and optional `MarkDown1..5` fields.

> Files assumed present (CSV or tables):
> - `sales.csv`
> - `stores.csv`
> - `features.csv`

---

## Query Catalog (What each script does)

Below is a high-level map of the SQL tasks and the insights they’re intended to produce. The numbers match the inline comments in the SQL file.

1) **Date Range Covered** — Confirms the min/max dates in `sales` for time-window sanity checks.
2) **Total Weekly Sales by Store (+Category/Size)** — Ranks stores by gross sales to spotlight top performers and contextualize by format and footprint.
3) **Total Sales by Category and Year** — Identifies which store categories lead by year to track structural shifts over time.
4) **Master Sales Table** — Builds `master_sales_data` via left joins of `sales`↔`stores`↔`features`; becomes a single, tidy table for BI & ML.
   - **Aggregated version (Store-Date)** — Model-friendly weekly totals + holiday flag + averaged exogenous features.
6) **Avg Weekly Sales per Department by Year** — Normalizes department performance across years to reveal departmental trend lines.
7) **Temperature & Fuel Stats by Month/Store** — Summaries that can be joined back to analyze seasonality and macro-sensitivity.
8) **Avg Weekly Sales per Store by Year** — Yearly store-level normalization for cohort or lifecycle comparisons.
9) **4-Week Rolling Average of Weekly Sales** — Smooths week-to-week volatility; useful for trend visualization and anomaly detection.
10) **Holiday Week Sales per Store** — Pulls out only the holiday weeks; can be compared to baseline to estimate holiday uplift.
11) **Department Share of Store Sales** — Computes `dept_sales_pct` to rank each department’s contribution within each store.
12) **Sales Spike Detection** — Flags weeks where `Weekly_Sales` > 1.5× prior week (Store+Dept granularity) for rapid QA and promo/stockout investigation.
13) **Markdowns vs Sales (Store-Year)** — Sums markdowns and pairs with sales to analyze promo effectiveness (correlation/elasticity downstream).
14) **YoY Sales Growth by Store** — Uses window functions to compute YoY% growth; ideal for growth dashboards and comp-store analysis.
15) **Revenue per Unit Area** — Normalizes by `Size` to compare productivity across footprints (sales density).

---

## Expected Outputs & How to Read Them

- **Date Window** — A single row with `start_date` and `end_date`. Use this in all downstream charts to label axes and confirm completeness.
- **Store Rankings** — A table ordered by `total_sales`; read alongside `Category` and `Size` to identify over/under-achievers by footprint.
- **Category × Year** — Heatmap-friendly pivot where the diagonal trend shows which formats are winning/lagging year to year.
- **Model-Ready Aggregates** — Weekly `Store` totals plus averaged features unlock simple baselines (e.g., linear models) and tree-based models.
- **Dept Trends** — Line charts (Dept × Year) to spot rising/falling departments and potential assortment issues.
- **Seasonality & Macro** — Monthly `avg_temp` and `avg_fuel_price` enable seasonality overlays against sales trends.
- **Rolling 4-Week** — Smoother lines for storytelling; use side-by-side with raw totals to show volatility vs. underlying momentum.
- **Holiday Uplift** — Compare `holiday_sales` to the 4-week rolling baseline or to matched non-holiday weeks.
- **Mix Contribution** — Pareto chart of `dept_sales_pct` per store to flag assortment dependence or concentration risk.
- **Spikes** — Quick anomaly log to QA data and investigate promos, price changes, stockouts, or calendar effects.
- **Markdowns vs Sales** — Scatterplots or correlations at Store-Year level to check whether deeper markdowns drove incremental volume.
- **YoY Growth** — Bar/column chart of `yoy_growth_pct` by store to highlight comp-store performance.
- **Sales Density** — `sales_per_unit_area` allows apples-to-apples productivity comparisons; great for benchmarking formats.

---

## Reproducing the Results

1. Load the three CSVs into your database as tables `sales`, `stores`, `features` (matching the column names above).
2. Run the SQL file **in order** so `master_sales_data` is created before dependent analyses.
3. Export result sets (CSV/Parquet) for charting in Python/R or your BI tool of choice.

---

## Assumptions & Data Quality Checks

- **Weekly alignment**: `features` are matched on the same `Store, Date` as `sales`. If feature dates are mid-week observations, aggregate to sales week first.
- **Missing markdowns**: `COALESCE` ensures missing `MarkDown1..5` are treated as zero.
- **Holiday logic**: A single weekly flag is acceptable for first-pass uplift estimates; refine with named holidays if available.
- **Store size stability**: Assumes `Size` is constant; if remodels occur, consider time-varying size metadata.

---

## Attribution

The SQL in this project covers date windows, store/category/department sales, rollups, rolling averages, holiday filters, markdown sums, YoY growth, and sales density. See the SQL comments in `Walmart_Data_Extraction.sql` for the numbered sections referenced above.
