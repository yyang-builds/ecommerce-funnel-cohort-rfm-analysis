# E-commerce Funnel, Cohort, and RFM Analysis

Portfolio-ready analytics project using **`bigquery-public-data.thelook_ecommerce`** for session-level funnel analysis, cohort retention, RFM segmentation, and channel / browser / geo performance. Includes **BigQuery SQL** and a **Python visualization** layer that saves PNGs for README and portfolios.

## Business problem

E-commerce teams need to see where users drop out of the journey, how often customers return, which segments drive value, and which acquisition sources and geographies matter.

## Insights (summary)

See **[docs/insights.md](docs/insights.md)** for narrative. Numeric highlights also appear in `outputs/figures/summary_metrics.json` after you run the generator.

1. **Funnel:** **680,868** sessions with product view; **430,501** reach cart; **180,868** purchase—optimize browse-to-cart and cart-to-purchase.
2. **Channels:** Session purchase rates cluster in the **~26–27%** range by source; site experience and retention matter alongside channel mix.
3. **RFM:** **Champions** drive a large share of revenue; **At Risk** is both large and valuable for win-back.
4. **Geo:** Revenue concentrates in **China**, **United States**, **Brasil**.
5. **Cohort heatmap:** Low repeat engagement in later periods vs cohort size—prioritize lifecycle and second purchase.

## Dataset overview

- **Source:** `bigquery-public-data.thelook_ecommerce`
- **Tables used in SQL / Python:** `events`, `orders`, `order_items`, `users`, `products`
- **Approximate date coverage (validated earlier):** events through **2026-03-26**, orders through **2026-03-22**

## Visualizations

| File | Description |
|------|-------------|
| `outputs/figures/01_funnel_product_cart_purchase.png` | Sessions at product view → add to cart → purchase |
| `outputs/figures/02_session_purchase_rate_by_source.png` | Session purchase rate by `traffic_source` |
| `outputs/figures/03_cohort_retention_heatmap.png` | Cohort × months since first order (retention %) |
| `outputs/figures/04_rfm_customers_by_segment.png` | Customers by RFM segment |
| `outputs/figures/04_rfm_revenue_by_segment.png` | Revenue by RFM segment |
| `outputs/figures/04_rfm_frequency_vs_monetary.png` | Sample scatter: frequency vs monetary by segment |
| `outputs/figures/05_top_countries_revenue.png` | Top countries by revenue |

### Preview

<p align="center">
  <img src="outputs/figures/01_funnel_product_cart_purchase.png" alt="Funnel" width="45%" />
  <img src="outputs/figures/02_session_purchase_rate_by_source.png" alt="Session purchase rate by source" width="45%" />
</p>

<p align="center">
  <img src="outputs/figures/03_cohort_retention_heatmap.png" alt="Cohort retention heatmap" width="90%" />
</p>

<p align="center">
  <img src="outputs/figures/04_rfm_revenue_by_segment.png" alt="RFM revenue by segment" width="45%" />
  <img src="outputs/figures/05_top_countries_revenue.png" alt="Top countries revenue" width="45%" />
</p>

## Repo structure

```text
ecommerce-funnel-cohort-rfm-analysis/
├── README.md
├── requirements.txt
├── .gitignore
├── python/
│   └── generate_charts.py
├── outputs/
│   └── figures/
├── sql/
│   ├── 01_dataset_validation.sql
│   ├── 02_funnel_analysis.sql
│   ├── 03_retention_cohort.sql
│   ├── 04_rfm_analysis.sql
│   └── 05_channel_device_geo_performance.sql
└── docs/
    ├── business_questions.md
    ├── data_dictionary.md
    └── insights.md
```

## SQL modules

| File | Purpose |
|------|---------|
| `sql/01_dataset_validation.sql` | Row counts, date ranges, sanity checks |
| `sql/02_funnel_analysis.sql` | Session funnel and conversion by source/browser |
| `sql/03_retention_cohort.sql` | Monthly cohort retention |
| `sql/04_rfm_analysis.sql` | RFM scores and segments |
| `sql/05_channel_device_geo_performance.sql` | Channel, browser, geo performance |

## KPI definitions

- **Sessions:** distinct `session_id` in `events`
- **Session purchase rate:** sessions with a `purchase` event ÷ all sessions (by segment as coded)
- **Revenue:** sum of `order_items.sale_price` for non-cancelled orders
- **RFM:** recency / frequency / monetary with NTILE-based scores (see `sql/04_rfm_analysis.sql`)
