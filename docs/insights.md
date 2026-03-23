# Business insights (Python / BigQuery)

These insights are derived from the same logic as `sql/` modules, executed against `bigquery-public-data.thelook_ecommerce`. Regenerate figures and `outputs/figures/summary_metrics.json` with `python python/generate_charts.py`.

## Funnel (session-level: product view → cart → purchase)

Among sessions that viewed a product, **430,501** added to cart and **180,868** completed purchase. The largest proportional drop is between **product view and cart** (sessions with product view: **680,868**), indicating browse-to-cart friction is a primary lever.

**Recommendation:** Test PDP clarity, shipping/returns messaging, and cart prompts; run segmented funnel analysis by traffic source.

## Session purchase rate by traffic source

`YouTube` leads at **26.79%** session purchase rate, with `Adwords` (**26.61%**) and `Email` (**26.54%**) close behind; `Organic` is lowest at **26.22%** in this aggregation.

**Recommendation:** Channel mix shifts alone are unlikely to fix conversion; pair channel tests with on-site funnel and merchandising improvements.

## Cohort retention

The retention heatmap shows low repeat activity in later months relative to cohort size (see `03_cohort_retention_heatmap.png`). This aligns with needing strong lifecycle programs after first purchase.

**Recommendation:** Prioritize first-to-second-order campaigns and win-back for lapsing buyers.

## RFM

`Champions` (**8,885** customers, **~$2.41M** revenue) and `At Risk` (**10,218** customers, **~$1.90M** revenue) illustrate both concentration of value and reactivation opportunity.

**Recommendation:** Protect high-value segments with loyalty benefits; run targeted offers for `At Risk` and `Hibernating` segments.

## Geography

Top revenue concentration: **China**, **United States**, **Brasil** (see bar chart and `summary_metrics.json`).

**Recommendation:** Localize merchandising and lifecycle messaging in top markets before broad expansion.

## What we do not claim

This analysis does **not** include paid-media metrics such as CTR, CPC, CPA, or ROAS, because they are not supported by this dataset in the same way as ad platform exports.
