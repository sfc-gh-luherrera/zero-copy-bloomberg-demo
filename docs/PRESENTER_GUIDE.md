# Presenter Guide: Zero-Copy Bloomberg Data Sharing

This guide is for the person running the demo. It covers what you need beforehand, how to set up, how to deliver the 90 seconds, and what to do if something goes wrong.

---

## 1. What the audience should leave with

- Bloomberg Data License data can be **queried in place** in Snowflake. No FTP, no file parsing, no ETL.
- The market data **joins directly** with internal holdings using plain SQL.
- Time-to-insight goes from days to **seconds**, with no copied data to keep in sync.

> All data in this demo is **synthetic**. Say so if anyone asks, and never present the numbers as real Bloomberg prices.

---

## 2. Prerequisites

### Snowflake account
| Requirement | Notes |
|---|---|
| A Snowflake account you can demo from | Any edition. The account must support Streamlit in Snowflake with the **container runtime** (check your region). |
| A role that can create databases | `CREATE DATABASE` on the account, or ownership of two pre-created databases. `ACCOUNTADMIN` or `SYSADMIN` works. |
| A warehouse | XS is enough. The role needs `USAGE` on it. |
| A compute pool for the Streamlit container | `SYSTEM_COMPUTE_POOL_CPU` exists in most accounts. Otherwise create one (`CPU_X64_XS`, min/max nodes 1) and grant `USAGE`. |
| `CREATE STREAMLIT` and `CREATE STAGE` on the app schema | Created by the setup script if your role owns the database. |

### Your laptop
- Snowsight access in a browser (the recommended way to present).
- Optional, for running the app locally: Python 3.11+, `pip install streamlit snowflake-snowpark-python pandas altair`, and a Snowflake connection configured in `~/.snowflake/connections.toml`.
- Optional: `git` to clone the repo.

### Materials
- This repository: SQL scripts, app, screenshots.
- The slide deck (Google Slides). Speaker notes are on every slide.

---

## 3. One-time setup (about 10 minutes)

1. **Clone the repo**
   ```bash
   git clone https://github.com/sfc-gh-luherrera/zero-copy-bloomberg-demo.git
   ```
2. **Create the synthetic data.** Open a Snowsight worksheet, set your role and warehouse, and run `01_setup_data.sql` in full. It creates:
   - `BLOOMBERG_DATA_LICENSE.DL`: security master plus the `SECURITIES_MARKET_DATA` view (stands in for the shared listing).
   - `INTERNAL_PORTFOLIO.CORE`: `HOLDINGS`, `PORTFOLIOS`, `FX_RATES`, `ANALYST_VIEWS`.
   - `INTERNAL_PORTFOLIO.APPS`: schema and stage for the app.
3. **Check the query.** Run `02_demo_query.sql`. You should get rows back in about a second.
4. **Deploy the app.** Upload `app/streamlit_app.py` to `@INTERNAL_PORTFOLIO.APPS.APP_STAGE/zero_copy_demo` (Snowsight: *Data » Databases » stage » + Files*, or `PUT` from a client), then run the `CREATE STREAMLIT` statement in the README with your warehouse and compute pool filled in.
5. **Open the app once** in Snowsight and click **Run**. The first start of the container can take a minute or two. Doing this ahead of time means the live demo starts warm.

---

## 4. Day-of checklist (15 minutes before)

- [ ] Logged into Snowsight with the right role. SSO/MFA already done.
- [ ] Warehouse resumed (run `SELECT 1;`).
- [ ] App open in its own tab, already run once, then refreshed to the start screen.
- [ ] Second tab: worksheet with `02_demo_query.sql` as a backup.
- [ ] Deck open in presenter view.
- [ ] Browser zoom set so the full results are visible without scrolling (80–90% is usually right on a projector).
- [ ] Notifications off, unrelated tabs closed.

---

## 5. Running the demo (90 seconds)

| Time | On screen | What to say |
|---|---|---|
| 0–15 s | App start screen | "This is Bloomberg Data License data, available in Snowflake through a share. Nothing has been downloaded or loaded." |
| 15–45 s | Click **Run** | "One SQL query joins live Bloomberg prices with our internal holdings, FX rates and analyst views." Point out the elapsed time. |
| 45–75 s | Results table and chart | "Here are the positions where our internal target diverges from the street by 15 points or more, plus the two names breaching concentration limits." |
| 75–90 s | Close | "No pipelines, no copies, no stale files. When Bloomberg updates the data, this query sees it straight away." |

The deck's speaker notes cover the slides around the demo.

---

## 6. Likely questions

- **"Is this real Bloomberg data?"** No, it's synthetic and shaped like Data License. With the real listing you change one database name (see *Using the real listing* in the README).
- **"Who pays for the compute?"** The consumer, using their own warehouse. The share itself doesn't copy storage.
- **"How fresh is the data?"** As fresh as the provider's share. There's no refresh job on the consumer side.
- **"Can we govern it?"** Yes. Standard roles, masking and row access policies apply to the joined result.
- **"What's on the Marketplace today?"** 32 Bloomberg Data License listings ([provider page](https://app.snowflake.com/marketplace/providers/GZU6Z9SLGH3/Bloomberg)) covering reference, pricing, fundamentals, corporate actions, ESG and more, with 82 active data shares across 57 customers. Snowflake is the first external data platform Bloomberg delivers through.
- **"What's coming?"** Roadmap, subject to change: 100+ historical-data listings from Bloomberg's Qube Data Store, and Bloomberg MCP servers planned for later this year. Say "planned"; don't promise dates.
- **Listing and customer counts on the slides:** check them against the current Marketplace before an external session. Region availability varies by listing.
- **Customer follow-ups that involve Bloomberg:** bring in your Snowflake account team, who will involve the right Bloomberg partnership contacts.

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| Clicking **Run** does nothing or spins | Container is still starting, or the warehouse is suspended. Wait, or run `SELECT 1` in a worksheet, then retry. |
| Running locally hangs on the first query | The OAuth connection is waiting for a browser SSO window. Complete the login. |
| `Object does not exist or not authorized` | Wrong role active, or `01_setup_data.sql` wasn't run with this role. Check `SELECT CURRENT_ROLE();` and the grants. |
| App fails to create | Compute pool missing or no `USAGE` on it, or the container runtime isn't available in this region. |
| Anything goes wrong live | Switch to the worksheet tab and run `02_demo_query.sql`. The message is the same. |

---

## 8. Cleanup (optional)

```sql
DROP DATABASE IF EXISTS INTERNAL_PORTFOLIO;
DROP DATABASE IF EXISTS BLOOMBERG_DATA_LICENSE;
```
