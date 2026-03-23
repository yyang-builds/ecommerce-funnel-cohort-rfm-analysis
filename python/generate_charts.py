#!/usr/bin/env python3
"""
Generate portfolio charts from TheLook E-commerce (BigQuery public dataset).

Queries `bigquery-public-data.thelook_ecommerce` using either:
  1) `bq` CLI (recommended if you use `gcloud` / `bq` auth already), or
  2) `google-cloud-bigquery` with Application Default Credentials.

Set USE_BQ_CLI=0 to force the Python BigQuery client.

Usage:
  cd /path/to/ecommerce-funnel-cohort-rfm-analysis
  python -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt
  python python/generate_charts.py

Outputs PNGs to outputs/figures/
"""

from __future__ import annotations

import io
import json
import os
import subprocess
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

# Project root (parent of python/)
ROOT = Path(__file__).resolve().parent.parent
FIG_DIR = ROOT / "outputs" / "figures"

DATASET = "`bigquery-public-data.thelook_ecommerce`"

# Prefer billing project for job labels (optional)
_BQ_PROJECT = os.environ.get("GCP_PROJECT") or os.environ.get("GOOGLE_CLOUD_PROJECT") or "modular-embassy-469320-h8"


def query_to_df_bq_cli(sql: str) -> pd.DataFrame:
    """Run SQL via `bq query --format=csv` (uses your local gcloud/bq credentials)."""
    cmd = [
        "bq",
        "query",
        f"--project_id={_BQ_PROJECT}",
        "--use_legacy_sql=false",
        "--format=csv",
        "--max_rows=1000000",
        "--quiet",
        sql,
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"bq query failed:\n{proc.stderr}\n{proc.stdout}")
    out = proc.stdout.strip()
    if not out:
        return pd.DataFrame()
    return pd.read_csv(io.StringIO(out))


def query_to_df_api(sql: str) -> pd.DataFrame:
    from google.cloud import bigquery

    client = bigquery.Client(project=_BQ_PROJECT)
    job = client.query(sql)
    return job.to_dataframe(create_bqstorage_client=False)


def query_to_df(sql: str) -> pd.DataFrame:
    use_cli = os.environ.get("USE_BQ_CLI", "1").lower() not in ("0", "false", "no")
    if use_cli:
        try:
            return query_to_df_bq_cli(sql)
        except (FileNotFoundError, RuntimeError) as e:
            print(f"Note: bq CLI failed ({e}). Falling back to google-cloud-bigquery...", file=sys.stderr)
    return query_to_df_api(sql)


def chart_funnel(df: pd.DataFrame, out: Path) -> None:
    """df columns: step_name, sessions_at_step (ordered product_view, add_to_cart, purchase)"""
    plt.figure(figsize=(8, 5))
    order = ["product_view", "add_to_cart", "purchase"]
    d = df.set_index("step_name").reindex(order).fillna(0)
    sns.barplot(x=d.index.astype(str), y=d["sessions_at_step"].values, palette="Blues_d")
    plt.title("Session funnel: product view → cart → purchase")
    plt.ylabel("Sessions")
    plt.xlabel("Step")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def chart_source_purchase_rate(df: pd.DataFrame, out: Path) -> None:
    d = df.sort_values("session_to_purchase_rate", ascending=False)
    plt.figure(figsize=(9, 5))
    sns.barplot(data=d, x="traffic_source", y="session_to_purchase_rate", palette="viridis")
    plt.title("Session purchase rate by traffic source")
    plt.ylabel("Session purchase rate (%)")
    plt.xlabel("Traffic source")
    plt.xticks(rotation=15)
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def chart_cohort_heatmap(df: pd.DataFrame, out: Path) -> None:
    """Pivot cohort_month x months_since_first_order -> retention_rate"""
    if df.empty:
        return
    pivot = df.pivot_table(
        index="cohort_month",
        columns="months_since_first_order",
        values="retention_rate",
        aggfunc="mean",
    )
    # limit columns for readability
    cols = sorted([c for c in pivot.columns if c <= 12])[:13]
    pivot = pivot[cols]
    plt.figure(figsize=(12, max(6, len(pivot) * 0.25)))
    sns.heatmap(pivot, annot=False, cmap="YlOrRd", fmt=".1f", cbar_kws={"label": "Retention %"})
    plt.title("Cohort retention (monthly, % of cohort)")
    plt.ylabel("Cohort month")
    plt.xlabel("Months since first order")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def chart_rfm_bars(df: pd.DataFrame, out_customers: Path, out_revenue: Path) -> None:
    d = df.sort_values("total_revenue", ascending=False)
    plt.figure(figsize=(9, 5))
    sns.barplot(data=d, x="rfm_segment", y="customers", palette="muted")
    plt.title("Customers by RFM segment")
    plt.ylabel("Customers")
    plt.xlabel("RFM segment")
    plt.xticks(rotation=25, ha="right")
    plt.tight_layout()
    plt.savefig(out_customers, dpi=150)
    plt.close()

    plt.figure(figsize=(9, 5))
    sns.barplot(data=d, x="rfm_segment", y="total_revenue", palette="husl")
    plt.title("Total revenue by RFM segment")
    plt.ylabel("Revenue")
    plt.xlabel("RFM segment")
    plt.xticks(rotation=25, ha="right")
    plt.tight_layout()
    plt.savefig(out_revenue, dpi=150)
    plt.close()


def chart_rfm_scatter(df: pd.DataFrame, out: Path) -> None:
    plt.figure(figsize=(8, 6))
    sns.scatterplot(
        data=df.sample(min(5000, len(df)), random_state=42),
        x="frequency_orders",
        y="monetary_value",
        hue="rfm_segment",
        alpha=0.5,
        s=12,
    )
    plt.title("RFM: frequency vs monetary (sample)")
    plt.xlabel("Orders (frequency)")
    plt.ylabel("Revenue (monetary)")
    plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left", fontsize=8)
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def chart_top_countries(df: pd.DataFrame, out: Path, top_n: int = 10) -> None:
    d = df.nlargest(top_n, "revenue")
    plt.figure(figsize=(9, 5))
    sns.barplot(data=d, x="country", y="revenue", palette="crest")
    plt.title(f"Top {top_n} countries by revenue")
    plt.ylabel("Revenue")
    plt.xlabel("Country")
    plt.xticks(rotation=15)
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close()


def main() -> int:
    sns.set_theme(style="whitegrid")
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- Funnel (session-level) ---
    sql_funnel = f"""
    WITH session_flags AS (
      SELECT
        session_id,
        MAX(CASE WHEN event_type = 'product' THEN 1 ELSE 0 END) AS viewed_product,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
      FROM {DATASET}.events
      GROUP BY session_id
    )
    SELECT 'product_view' AS step_name, COUNTIF(viewed_product = 1) AS sessions_at_step
    FROM session_flags
    UNION ALL
    SELECT 'add_to_cart', COUNTIF(viewed_product = 1 AND added_to_cart = 1)
    FROM session_flags
    UNION ALL
    SELECT 'purchase', COUNTIF(viewed_product = 1 AND added_to_cart = 1 AND purchased = 1)
    FROM session_flags
    """
    df_funnel = query_to_df(sql_funnel)
    chart_funnel(df_funnel, FIG_DIR / "01_funnel_product_cart_purchase.png")

    # --- Session purchase rate by traffic source ---
    sql_source = f"""
    WITH session_flags AS (
      SELECT
        session_id,
        ANY_VALUE(traffic_source) AS traffic_source,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
      FROM {DATASET}.events
      GROUP BY session_id
    )
    SELECT
      traffic_source,
      COUNT(*) AS sessions,
      COUNTIF(purchased = 1) AS purchase_sessions,
      ROUND(SAFE_DIVIDE(COUNTIF(purchased = 1), COUNT(*)) * 100, 2) AS session_to_purchase_rate
    FROM session_flags
    GROUP BY traffic_source
    ORDER BY session_to_purchase_rate DESC
    """
    df_source = query_to_df(sql_source)
    chart_source_purchase_rate(df_source, FIG_DIR / "02_session_purchase_rate_by_source.png")

    # --- Cohort retention long ---
    sql_cohort = f"""
    WITH valid_orders AS (
      SELECT order_id, user_id, DATE(created_at) AS order_date
      FROM {DATASET}.orders
      WHERE status != 'Cancelled'
    ),
    user_cohorts AS (
      SELECT user_id, DATE_TRUNC(MIN(order_date), MONTH) AS cohort_month
      FROM valid_orders
      GROUP BY user_id
    ),
    cohort_activity AS (
      SELECT
        uc.cohort_month,
        DATE_TRUNC(vo.order_date, MONTH) AS activity_month,
        DATE_DIFF(DATE_TRUNC(vo.order_date, MONTH), uc.cohort_month, MONTH) AS months_since_first_order,
        vo.user_id
      FROM valid_orders AS vo
      JOIN user_cohorts AS uc ON vo.user_id = uc.user_id
    ),
    cohort_sizes AS (
      SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
      FROM user_cohorts
      GROUP BY cohort_month
    )
    SELECT
      ca.cohort_month,
      ca.months_since_first_order,
      cs.cohort_size,
      COUNT(DISTINCT ca.user_id) AS retained_users,
      ROUND(SAFE_DIVIDE(COUNT(DISTINCT ca.user_id), cs.cohort_size) * 100, 2) AS retention_rate
    FROM cohort_activity AS ca
    JOIN cohort_sizes AS cs ON ca.cohort_month = cs.cohort_month
    GROUP BY ca.cohort_month, ca.months_since_first_order, cs.cohort_size
    """
    df_cohort = query_to_df(sql_cohort)
    cohort_month = pd.to_datetime(df_cohort["cohort_month"])
    df_cohort["cohort_month"] = cohort_month.dt.strftime("%Y-%m")
    chart_cohort_heatmap(df_cohort, FIG_DIR / "03_cohort_retention_heatmap.png")

    # --- RFM segment summary + user scores (inline) ---
    sql_rfm_summary = f"""
    WITH valid_orders AS (
      SELECT order_id, user_id, DATE(created_at) AS order_date
      FROM {DATASET}.orders
      WHERE status != 'Cancelled'
    ),
    order_revenue AS (
      SELECT order_id, ROUND(SUM(sale_price), 2) AS order_revenue
      FROM {DATASET}.order_items
      GROUP BY order_id
    ),
    user_rfm_base AS (
      SELECT
        vo.user_id,
        DATE_DIFF((SELECT MAX(order_date) FROM valid_orders), MAX(vo.order_date), DAY) AS recency_days,
        COUNT(DISTINCT vo.order_id) AS frequency_orders,
        ROUND(SUM(orv.order_revenue), 2) AS monetary_value
      FROM valid_orders AS vo
      LEFT JOIN order_revenue AS orv ON vo.order_id = orv.order_id
      GROUP BY vo.user_id
    ),
    scored AS (
      SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
      FROM user_rfm_base
    ),
    segmented AS (
      SELECT
        user_id,
        frequency_orders,
        monetary_value,
        CASE
          WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
          WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Loyal Customers'
          WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
          WHEN recency_score = 5 AND frequency_score = 1 THEN 'New Customers'
          WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
          WHEN recency_score = 1 AND frequency_score >= 4 THEN 'Cannot Lose Them'
          WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
          ELSE 'Potential Loyalists'
        END AS rfm_segment
      FROM scored
    )
    SELECT
      rfm_segment,
      COUNT(*) AS customers,
      ROUND(SUM(monetary_value), 2) AS total_revenue
    FROM segmented
    GROUP BY rfm_segment
    ORDER BY total_revenue DESC
    """
    df_rfm_seg = query_to_df(sql_rfm_summary)
    chart_rfm_bars(
        df_rfm_seg,
        FIG_DIR / "04_rfm_customers_by_segment.png",
        FIG_DIR / "04_rfm_revenue_by_segment.png",
    )

    sql_rfm_users = f"""
    WITH valid_orders AS (
      SELECT order_id, user_id, DATE(created_at) AS order_date
      FROM {DATASET}.orders
      WHERE status != 'Cancelled'
    ),
    order_revenue AS (
      SELECT order_id, ROUND(SUM(sale_price), 2) AS order_revenue
      FROM {DATASET}.order_items
      GROUP BY order_id
    ),
    user_rfm_base AS (
      SELECT
        vo.user_id,
        DATE_DIFF((SELECT MAX(order_date) FROM valid_orders), MAX(vo.order_date), DAY) AS recency_days,
        COUNT(DISTINCT vo.order_id) AS frequency_orders,
        ROUND(SUM(orv.order_revenue), 2) AS monetary_value
      FROM valid_orders AS vo
      LEFT JOIN order_revenue AS orv ON vo.order_id = orv.order_id
      GROUP BY vo.user_id
    ),
    scored AS (
      SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency_orders ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS monetary_score
      FROM user_rfm_base
    )
    SELECT
      user_id,
      frequency_orders,
      monetary_value,
      CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
        WHEN recency_score = 5 AND frequency_score = 1 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
        WHEN recency_score = 1 AND frequency_score >= 4 THEN 'Cannot Lose Them'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
        ELSE 'Potential Loyalists'
      END AS rfm_segment
    FROM scored
    """
    df_rfm_users = query_to_df(sql_rfm_users)
    chart_rfm_scatter(df_rfm_users, FIG_DIR / "04_rfm_frequency_vs_monetary.png")

    # --- Top countries by revenue ---
    sql_geo = f"""
    WITH valid_orders AS (
      SELECT o.order_id, o.user_id
      FROM {DATASET}.orders o
      WHERE o.status != 'Cancelled'
    ),
    order_revenue AS (
      SELECT order_id, ROUND(SUM(sale_price), 2) AS order_revenue
      FROM {DATASET}.order_items
      GROUP BY order_id
    )
    SELECT
      u.country,
      ROUND(SUM(orv.order_revenue), 2) AS revenue
    FROM {DATASET}.users u
    JOIN valid_orders vo ON u.id = vo.user_id
    JOIN order_revenue orv ON vo.order_id = orv.order_id
    GROUP BY u.country
    """
    df_geo = query_to_df(sql_geo)
    chart_top_countries(df_geo, FIG_DIR / "05_top_countries_revenue.png")

    # Summary metrics for README / insights file
    summary = {
        "funnel": df_funnel.to_dict("records"),
        "source_rates": df_source.to_dict("records"),
        "rfm_segments": df_rfm_seg.to_dict("records"),
        "top_countries": df_geo.nlargest(5, "revenue").to_dict("records"),
    }
    import json

    out_json = FIG_DIR / "summary_metrics.json"
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2, default=str)

    print(f"Wrote figures to {FIG_DIR}")
    print(f"Wrote {out_json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
