# Looker Studio Dashboard Plan

## Goal
Create a recruiter-friendly dashboard that shows the full story from browsing behavior to purchase, repeat buying, and customer value segmentation.

## Recommended BigQuery Outputs
Materialize each SQL module as a view or saved query in your own BigQuery project:
- `validation_summary`
- `funnel_core`
- `funnel_by_source_browser`
- `cohort_retention_long`
- `rfm_user_scores`
- `rfm_segment_summary`
- `source_browser_session_performance`
- `source_country_order_performance`
- `city_session_performance`

## Page 1: Executive Overview
Purpose: give hiring managers a fast summary of the business and analytical scope.

KPIs:
- sessions
- purchasing users
- non-cancelled orders
- revenue
- average order value
- repeat buyer rate

Charts:
- scorecard row for the KPIs
- monthly revenue trend line
- monthly purchasing users trend line
- bar chart of traffic source by revenue
- bar chart of top countries by revenue

Suggested filters:
- date range
- traffic source
- country

Primary data sources:
- `validation_summary`
- `source_country_order_performance`

## Page 2: Funnel and Session Behavior
Purpose: show where browse-to-buy conversion weakens.

Charts:
- funnel chart for `product_view -> add_to_cart -> purchase`
- bar chart for session purchase rate by traffic source
- bar chart for session purchase rate by browser
- table with source + browser + sessions + cart rate + purchase rate
- city-level table for high-volume cities

Suggested filters:
- traffic source
- browser
- city

Primary data sources:
- `funnel_core`
- `funnel_by_source_browser`
- `source_browser_session_performance`
- `city_session_performance`

## Page 3: Cohort Retention
Purpose: show whether new buyers come back.

Charts:
- cohort heatmap with `cohort_month` on rows and `months_since_first_order` on columns
- line chart for average retention curve by month number
- bar chart for repeat buyers vs one-time buyers

Suggested filters:
- cohort month
- country
- traffic source

Primary data sources:
- `cohort_retention_long`

## Page 4: RFM Segmentation
Purpose: show customer value concentration and retention opportunity.

Charts:
- bar chart of customers by RFM segment
- bar chart of revenue by RFM segment
- scatter plot of frequency vs monetary value, colored by segment
- table of segment summary with customers, avg orders, avg revenue, total revenue

Suggested filters:
- RFM segment
- country
- traffic source

Primary data sources:
- `rfm_user_scores`
- `rfm_segment_summary`

## Page 5: Channel and Geo Performance
Purpose: compare acquisition efficiency and geographic contribution.

Charts:
- bar chart of purchasing users by traffic source
- map chart of revenue by country
- table of country metrics with users, purchasing users, orders, revenue, AOV
- bar chart of browser session purchase rate

Suggested filters:
- country
- traffic source
- browser

Primary data sources:
- `source_country_order_performance`
- `source_browser_session_performance`

## Dashboard Design Tips
- Keep the color palette minimal and business-like.
- Use consistent KPI naming between the README and dashboard.
- Add short text callouts to explain the 2-3 most important findings on each page.
- Default the dashboard to the full available date range.

## Manual Steps In BigQuery
1. Save each final query as a view or scheduled query in your own GCP project.
2. Confirm field names and data types in the resulting views.
3. If needed, create slimmed-down reporting tables to improve dashboard speed.

## Manual Steps In Looker Studio
1. Connect Looker Studio to your BigQuery project.
2. Add each saved view as a data source.
3. Build the pages above using the recommended charts.
4. Format scorecards, chart labels, and filter controls for readability.
5. Add an insights panel or text box on each page summarizing the main takeaway.
