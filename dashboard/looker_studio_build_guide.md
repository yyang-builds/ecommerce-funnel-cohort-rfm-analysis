# Looker Studio Build Guide

## Goal
Build a recruiter-friendly Looker Studio dashboard on top of the BigQuery views in `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis` so the project is easy to scan in GitHub and strong enough to include in a PDF portfolio.

## Available BigQuery Views

### Core dashboard views
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.validation_summary`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.funnel_core`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.funnel_by_source_browser`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.cohort_retention_long`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.cohort_revenue_long`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.repeat_purchase_summary`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.rfm_user_scores`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.rfm_segment_summary`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.source_browser_session_performance`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.source_country_order_performance`
- `modular-embassy-469320-h8.ecommerce_funnel_cohort_rfm_analysis.city_session_performance`

### Optional validation views
- `validation_table_row_counts`
- `validation_date_coverage`
- `validation_event_type_distribution`
- `validation_order_status_distribution`
- `validation_baseline_metrics`
- `funnel_detailed`
- `source_country_city_order_performance`

## Recruiter-Friendly Dashboard Structure

### Page 1: Executive Overview
Purpose: give a hiring manager a fast understanding of scope, scale, and business value.

Use these scorecards:
- Sessions
- Purchasing Users
- Non-Cancelled Orders
- Revenue
- Average Order Value
- Repeat Buyer Rate

Recommended charts:
- Scorecard row across the top
- Bar chart: revenue by traffic source
- Bar chart: revenue by country
- Table: country performance summary

Primary views:
- `validation_summary`
- `repeat_purchase_summary`
- `source_country_order_performance`

Layout:
- Top row: six scorecards
- Middle left: revenue by source
- Middle right: revenue by country
- Bottom: country summary table

### Page 2: Funnel Performance
Purpose: show the customer journey from browse intent to purchase.

Recommended charts:
- Funnel chart: `product_view -> add_to_cart -> purchase`
- Bar chart: session purchase rate by traffic source
- Bar chart: session purchase rate by browser
- Table: source + browser + sessions + cart rate + purchase rate
- Table: top cities by sessions and purchase rate

Primary views:
- `funnel_core`
- `funnel_by_source_browser`
- `source_browser_session_performance`
- `city_session_performance`

Layout:
- Top left: funnel chart
- Top right: session purchase rate by source
- Middle left: session purchase rate by browser
- Middle right: top source/browser combination table
- Bottom: city table

### Page 3: Cohort Retention
Purpose: show whether first-time buyers come back.

Recommended charts:
- Heatmap: `cohort_month` by `months_since_first_order` colored by `retention_rate`
- Line chart: retention curve for month 0 through month 6
- Table: cohort revenue by month number
- Scorecard: repeat buyer rate

Primary views:
- `cohort_retention_long`
- `cohort_revenue_long`
- `repeat_purchase_summary`

Layout:
- Top: repeat buyer summary and short text insight
- Middle: cohort heatmap
- Bottom left: retention curve
- Bottom right: cohort revenue table

### Page 4: RFM Segmentation
Purpose: show customer value concentration and retention opportunity.

Recommended charts:
- Bar chart: customers by RFM segment
- Bar chart: total revenue by RFM segment
- Scatter plot: frequency vs monetary value colored by `rfm_segment`
- Table: segment metrics

Primary views:
- `rfm_segment_summary`
- `rfm_user_scores`

Layout:
- Top left: customers by segment
- Top right: revenue by segment
- Bottom left: scatter plot
- Bottom right: segment summary table

### Page 5: Channel, Browser, and Geo Performance
Purpose: compare acquisition quality and market contribution.

Recommended charts:
- Bar chart: purchasing users by traffic source
- Bar chart: browser session purchase rate
- Geo map: revenue by country
- Table: country-level performance

Primary views:
- `source_country_order_performance`
- `source_browser_session_performance`

Layout:
- Top left: purchasing users by source
- Top right: browser session purchase rate
- Bottom left: country geo map
- Bottom right: country performance table

## Exact View Mapping By Page

### Executive Overview
- KPI scorecards:
  - `validation_summary` for `sessions`, `non_cancelled_orders`, `purchasing_users`, `gross_merchandise_value`
  - `repeat_purchase_summary` for `repeat_buyer_rate`
  - Calculated field on `validation_summary` for average order value if desired:
    - `gross_merchandise_value / non_cancelled_orders`
- Revenue by traffic source:
  - `source_country_order_performance`
- Revenue by country:
  - `source_country_order_performance`

### Funnel Performance
- Funnel chart:
  - `funnel_core`
- Source and browser conversion charts:
  - `funnel_by_source_browser`
  - `source_browser_session_performance`
- City session table:
  - `city_session_performance`

### Cohort Retention
- Retention heatmap:
  - `cohort_retention_long`
- Revenue by cohort/month:
  - `cohort_revenue_long`
- Repeat buyer KPI:
  - `repeat_purchase_summary`

### RFM Segmentation
- Segment summary charts:
  - `rfm_segment_summary`
- User-level scatter plot:
  - `rfm_user_scores`

### Channel / Browser / Geo
- Country metrics:
  - `source_country_order_performance`
- Browser metrics:
  - `source_browser_session_performance`

## Recommended Filters

### Global filters
- Traffic Source
- Country

### Page-specific filters
- Funnel page:
  - Browser
  - City
- Cohort page:
  - Cohort Month
  - Months Since First Order
- RFM page:
  - RFM Segment
- Channel/Geo page:
  - Browser

## Looker Studio Build Checklist
1. Open Looker Studio and create a new report.
2. Add BigQuery as the data source.
3. Connect the views listed in the core dashboard views section.
4. Build the Executive Overview page first.
5. Add the Funnel Performance page with the 3-step funnel as the hero chart.
6. Add the Cohort Retention page and verify `retention_rate` is treated as a metric.
7. Add the RFM Segmentation page and confirm the scatter plot uses user-level data from `rfm_user_scores`.
8. Add the Channel / Browser / Geo page and format the country map and tables.
9. Add page titles and one short insight box per page.
10. Check that number formatting is consistent:
  - revenue as currency
  - rates as percentages
  - counts with comma separators
11. Apply a consistent color palette across the full report.
12. Review the dashboard in presentation mode before exporting screenshots.

## Layout and Design Recommendations
- Keep the dashboard to 5 pages max.
- Use a white background and one accent color.
- Put the most important metric or chart in the top-left of each page.
- Avoid cluttered legends and long chart titles.
- Use short insight callouts such as:
  - `Cart-to-purchase is the biggest conversion bottleneck.`
  - `Month-1 retention is low, making lifecycle marketing a priority.`
  - `Champions drive disproportionate revenue relative to segment size.`

## Screenshot Guidance For GitHub
- Capture 2 to 4 screenshots total, not every page.
- Best GitHub screenshot set:
  - Executive Overview
  - Funnel Performance
  - Cohort Retention
  - RFM Segmentation
- Recommended image width:
  - around 1400 to 1600 px for crisp README rendering
- Before capturing:
  - collapse edit panels
  - hide unnecessary control chrome
  - use presentation or view mode
  - make sure filters are set to the default full-range view

Suggested README section:
```md
## Dashboard Preview

### Executive Overview
![Executive Overview](dashboard/screenshots/executive-overview.png)

### Funnel Performance
![Funnel Performance](dashboard/screenshots/funnel-performance.png)

### Cohort Retention
![Cohort Retention](dashboard/screenshots/cohort-retention.png)

### RFM Segmentation
![RFM Segmentation](dashboard/screenshots/rfm-segmentation.png)
```

## Screenshot Guidance For PDF Portfolio
- Use one screenshot per slide or page section.
- Prefer landscape images.
- Crop tightly so text remains readable.
- Add a one-sentence takeaway under each screenshot.
- Recommended order:
  1. Executive Overview
  2. Funnel page
  3. Cohort page
  4. RFM page

Suggested caption style:
- `Funnel conversion analysis showing a strong drop-off between cart and purchase.`
- `Cohort retention view highlighting low repeat purchase behavior after month 1.`
- `RFM segmentation showing that Champions contribute outsized revenue.`

## Export Tips
- In Looker Studio, use presentation mode before taking screenshots.
- If you export to PDF directly from Looker Studio:
  - review page breaks
  - make sure scorecards are not clipped
  - verify the map renders correctly
- Keep both:
  - raw screenshots for GitHub
  - a polished PDF for applications

## Browser Automation Next Step
Browser automation can help after the dashboard is built, but it needs:
- the Looker Studio report URL
- access to a logged-in browser session if the report is private
- confirmation of which pages should be captured

Best capture workflow:
1. Build and save the dashboard in Looker Studio.
2. Share the report URL.
3. Specify which pages to capture.
4. Use browser automation to open each page in view mode and take clean screenshots.

## Important Note
The BigQuery views in your sandbox project currently have expiration limits. If you want a long-lived dashboard link for your portfolio, you should enable billing or recreate the same views in a billed project later.
