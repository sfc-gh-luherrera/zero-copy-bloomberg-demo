import time
from concurrent.futures import ThreadPoolExecutor

import altair as alt
import pandas as pd
import streamlit as st

st.set_page_config(page_title="Zero-Copy Bloomberg x Holdings", page_icon=":material/bolt:", layout="wide")

conn = st.connection("snowflake")

POSITIONS_CTE = """
WITH pos AS (
  SELECT h.PORTFOLIO_ID, m.*, h.QUANTITY,
         h.QUANTITY * m.PX_LAST * fx.USD_PER_UNIT / IFF(m.SECURITY_TYP = 'Common Stock', 1, 100) AS MV_USD
  FROM INTERNAL_PORTFOLIO.CORE.HOLDINGS h
  JOIN BLOOMBERG_DATA_LICENSE.DL.SECURITIES_MARKET_DATA m ON m.ID_ISIN = h.ID_ISIN
  JOIN INTERNAL_PORTFOLIO.CORE.FX_RATES fx ON fx.CRNCY = m.CRNCY
)
"""

RESEARCH_SQL = POSITIONS_CTE + """
SELECT p.TICKER, p.NAME, p.BICS_LEVEL_1_SECTOR_NAME AS SECTOR,
       p.PX_LAST, p.CHG_PCT_1D, p.RTG_SP, p.RTG_MOODY,
       ROUND((p.BEST_TARGET_PRICE / p.PX_LAST - 1) * 100, 1)   AS STREET_UPSIDE_PCT,
       a.INTERNAL_RATING, a.INTERNAL_CREDIT_OUTLOOK,
       ROUND((a.INTERNAL_FAIR_VALUE / p.PX_LAST - 1) * 100, 1) AS INTERNAL_UPSIDE_PCT,
       ROUND(SUM(p.MV_USD) / 1e6, 1)                           AS FIRM_MV_USD_MM,
       a.ANALYST, a.THESIS,
       MAX(CONVERT_TIMEZONE('Europe/Paris', p.LAST_UPDATE_TS)::TIMESTAMP_NTZ) AS LAST_UPDATE_TS
FROM pos p
JOIN INTERNAL_PORTFOLIO.CORE.ANALYST_VIEWS a ON a.ID_ISIN = p.ID_ISIN
WHERE p.SECURITY_TYP = 'Common Stock'
GROUP BY ALL
HAVING ABS(INTERNAL_UPSIDE_PCT - STREET_UPSIDE_PCT) >= 15
ORDER BY ABS(INTERNAL_UPSIDE_PCT - STREET_UPSIDE_PCT) DESC
"""

SECTOR_SQL = POSITIONS_CTE + """
SELECT p.PORTFOLIO_ID, pf.PORTFOLIO_NAME, p.BICS_LEVEL_1_SECTOR_NAME AS SECTOR,
       ROUND(SUM(p.MV_USD) / 1e6, 1) AS MV_USD_MM,
       ROUND(100 * RATIO_TO_REPORT(SUM(p.MV_USD)) OVER (PARTITION BY p.PORTFOLIO_ID), 2) AS WEIGHT_PCT,
       pf.SECTOR_LIMIT_PCT
FROM pos p JOIN INTERNAL_PORTFOLIO.CORE.PORTFOLIOS pf USING (PORTFOLIO_ID)
GROUP BY ALL
"""

ISSUER_SQL = POSITIONS_CTE + """
SELECT p.PORTFOLIO_ID, p.ISSUER_TICKER AS ISSUER, ANY_VALUE(p.RTG_SP) AS RTG_SP,
       COUNT(DISTINCT p.SECURITY_TYP) > 1 AS CROSS_ASSET,
       ROUND(100 * RATIO_TO_REPORT(SUM(p.MV_USD)) OVER (PARTITION BY p.PORTFOLIO_ID), 2) AS WEIGHT_PCT,
       ANY_VALUE(pf.ISSUER_LIMIT_PCT) AS LIMIT_PCT
FROM pos p JOIN INTERNAL_PORTFOLIO.CORE.PORTFOLIOS pf USING (PORTFOLIO_ID)
WHERE p.BICS_LEVEL_1_SECTOR_NAME <> 'Government'  -- sovereigns exempt from issuer limits
GROUP BY p.PORTFOLIO_ID, p.ISSUER_TICKER
QUALIFY WEIGHT_PCT >= 0.8 * LIMIT_PCT
ORDER BY WEIGHT_PCT / LIMIT_PCT DESC
"""


def _fetch(sql):
    cur = conn.raw_connection.cursor()
    try:
        return cur.execute(sql).fetch_pandas_all()
    finally:
        cur.close()


def run_live():
    # Run the three queries concurrently so the demo shows a single round-trip
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=3) as pool:
        frames = list(pool.map(_fetch, (RESEARCH_SQL, SECTOR_SQL, ISSUER_SQL)))
    return (*frames, time.perf_counter() - t0)


st.title("Instant time-to-insight")
st.caption(
    "Bloomberg Data License (Marketplace listing, zero-copy) :material/sync_alt: internal holdings & research — "
    "`BLOOMBERG_DATA_LICENSE.DL.SECURITIES_MARKET_DATA` ⋈ `INTERNAL_PORTFOLIO.CORE.HOLDINGS`"
)

with st.expander("Show the query", icon=":material/code:"):
    st.code(RESEARCH_SQL.strip(), language="sql")

if st.button("Run live query", type="primary", icon=":material/play_arrow:"):
    st.session_state.result = run_live()

if "result" not in st.session_state:
    st.info("Click **Run live query** to join live Bloomberg market data with internal holdings.", icon=":material/info:")
    st.stop()

research, sector, issuer, elapsed = st.session_state.result
breaches = int((sector["WEIGHT_PCT"] > sector["SECTOR_LIMIT_PCT"]).sum())

m1, m2, m3, m4 = st.columns(4)
m1.metric("Query time", f"{elapsed:.1f} s")
m2.metric("Mispriced vs Street", f"{len(research)} names")
m3.metric("Sector limit breaches", breaches)
m4.metric("Bloomberg data as of", pd.to_datetime(research["LAST_UPDATE_TS"]).max().strftime("%H:%M:%S CET"))

left, right = st.columns([1.15, 1])

with left.container(border=True):
    st.subheader(":material/query_stats: A · Investment research")
    st.caption("Live Bloomberg pricing, consensus targets and ratings vs our proprietary fair value")
    research["VIEW_GAP_PCT"] = research["INTERNAL_UPSIDE_PCT"] - research["STREET_UPSIDE_PCT"]
    st.dataframe(
        research[["TICKER", "INTERNAL_RATING", "INTERNAL_UPSIDE_PCT", "STREET_UPSIDE_PCT", "VIEW_GAP_PCT",
                  "PX_LAST", "CHG_PCT_1D", "RTG_SP", "RTG_MOODY", "FIRM_MV_USD_MM", "THESIS"]],
        hide_index=True,
        height=460,
        column_config={
            "TICKER": "Ticker",
            "PX_LAST": st.column_config.NumberColumn("PX_LAST", format="%.2f"),
            "CHG_PCT_1D": st.column_config.NumberColumn("1D %", format="%+.2f%%"),
            "RTG_SP": "S&P",
            "RTG_MOODY": "Moody's",
            "STREET_UPSIDE_PCT": st.column_config.NumberColumn("Street upside", format="%+.1f%%"),
            "INTERNAL_RATING": "Our rating",
            "INTERNAL_UPSIDE_PCT": st.column_config.NumberColumn("Our upside", format="%+.1f%%"),
            "VIEW_GAP_PCT": st.column_config.NumberColumn("Edge vs Street", format="%+.1f pp"),
            "FIRM_MV_USD_MM": st.column_config.NumberColumn("Firm MV ($mm)", format="%.0f"),
            "THESIS": st.column_config.TextColumn("Analyst thesis", width="large"),
        },
    )

with right.container(border=True):
    st.subheader(":material/grid_view: B · Portfolio risk")
    st.caption("Real-time sector exposure as % of each fund's mandate limit")
    sector["LIMIT_USED_PCT"] = (100 * sector["WEIGHT_PCT"] / sector["SECTOR_LIMIT_PCT"]).round(0)
    base = alt.Chart(sector).encode(
        x=alt.X("SECTOR:N", title=None, axis=alt.Axis(labelAngle=-45, labelOverlap=False, labelLimit=140)),
        y=alt.Y("PORTFOLIO_ID:N", title=None),
    )
    heat = base.mark_rect(cornerRadius=3).encode(
        color=alt.Color("LIMIT_USED_PCT:Q", title="% of limit",
                        scale=alt.Scale(domain=[0, 85, 100, 180], range=["#E8F6FC", "#29B5E8", "#FF9F36", "#D7263D"])),
        tooltip=["PORTFOLIO_NAME", "SECTOR", "WEIGHT_PCT", "SECTOR_LIMIT_PCT", "MV_USD_MM"],
    )
    labels = base.mark_text(fontSize=11).encode(
        text=alt.Text("WEIGHT_PCT:Q", format=".0f"),
        color=alt.condition(alt.datum.LIMIT_USED_PCT > 85, alt.value("white"), alt.value("#11567F")),
    )
    st.altair_chart((heat + labels).properties(height=300), use_container_width=True)

    st.markdown("**Issuer concentration watchlist** (≥80% of issuer limit)")
    st.dataframe(
        issuer, hide_index=True, height=200,
        column_config={
            "PORTFOLIO_ID": "Fund", "ISSUER": "Issuer", "RTG_SP": "S&P",
            "CROSS_ASSET": st.column_config.CheckboxColumn("Equity + bond"),
            "WEIGHT_PCT": st.column_config.ProgressColumn("Weight %", format="%.1f%%", min_value=0, max_value=15),
            "LIMIT_PCT": st.column_config.NumberColumn("Limit %", format="%.1f%%"),
        },
    )

st.divider()
b1, b2, b3 = st.columns(3)
b1.metric("Bytes copied", "0")
b2.metric("Governed", "100%")
b3.metric("Time to insight", "90 seconds")
st.caption("Demo data is synthetic and indicative only — modelled on Bloomberg Data License field names.")
