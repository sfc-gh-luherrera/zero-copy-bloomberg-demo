-- =====================================================================
-- Zero-Copy Bloomberg Demo — synthetic data setup
-- BLOOMBERG_DATA_LICENSE  : stands in for the Marketplace listing (read-only)
-- INTERNAL_PORTFOLIO      : the firm's proprietary holdings + analyst views
-- All figures are SYNTHETIC / indicative, for demo purposes only.
-- =====================================================================
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;

CREATE DATABASE IF NOT EXISTS BLOOMBERG_DATA_LICENSE COMMENT = 'Bloomberg Data License (demo listing mount — synthetic)';
CREATE SCHEMA  IF NOT EXISTS BLOOMBERG_DATA_LICENSE.DL;
CREATE DATABASE IF NOT EXISTS INTERNAL_PORTFOLIO COMMENT = 'Proprietary holdings and research (demo — synthetic)';
CREATE SCHEMA  IF NOT EXISTS INTERNAL_PORTFOLIO.CORE;

-- ---------------------------------------------------------------------
-- 1. Security master + end-of-day reference prices (Bloomberg field names)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER (
  ID_BB_GLOBAL STRING, TICKER STRING, ID_ISIN STRING, NAME STRING,
  SECURITY_TYP STRING, BICS_LEVEL_1_SECTOR_NAME STRING, CNTRY_OF_RISK STRING, CRNCY STRING,
  ISSUER_TICKER STRING, PX_CLOSE_1D FLOAT, BEST_TARGET_PRICE FLOAT, PE_RATIO FLOAT,
  CUR_MKT_CAP_BN FLOAT, RTG_SP STRING, RTG_MOODY STRING, YLD_YTM_MID FLOAT, OAS_SPREAD_BID FLOAT,
  CPN FLOAT, MATURITY DATE
);

INSERT INTO BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER
SELECT 'BBG' || LPAD(ABS(HASH(column2)) % 1000000000, 9, '0'), column1, column2, column3, column4, column5, column6, column7,
       SPLIT_PART(column1, ' ', 1), column8, column9, column10, column11, column12, column13, column14, column15, column16, TRY_TO_DATE(column17)
FROM VALUES
-- ticker            isin            name                         typ            sector                    cty  ccy   close   target   pe    mcap  S&P   Moody  ytm  oas  cpn  mat
('AAPL US Equity','US0378331005','Apple Inc','Common Stock','Technology','US','USD',262.4,285.0,33.1,3890,'AA+','Aaa',NULL,NULL,NULL,NULL),
('MSFT US Equity','US5949181045','Microsoft Corp','Common Stock','Technology','US','USD',531.8,610.0,36.4,3950,'AAA','Aaa',NULL,NULL,NULL,NULL),
('NVDA US Equity','US67066G1040','NVIDIA Corp','Common Stock','Technology','US','USD',196.3,232.0,44.8,4780,'AA-','Aa2',NULL,NULL,NULL,NULL),
('AVGO US Equity','US11135F1012','Broadcom Inc','Common Stock','Technology','US','USD',351.2,395.0,38.9,1650,'BBB+','Baa1',NULL,NULL,NULL,NULL),
('ORCL US Equity','US68389X1054','Oracle Corp','Common Stock','Technology','US','USD',268.9,320.0,40.2,760,'BBB','Baa2',NULL,NULL,NULL,NULL),
('AMD US Equity','US0079031078','Advanced Micro Devices Inc','Common Stock','Technology','US','USD',241.5,265.0,52.3,390,'A','A2',NULL,NULL,NULL,NULL),
('INTC US Equity','US4581401001','Intel Corp','Common Stock','Technology','US','USD',38.7,34.0,NULL,169,'BBB','Baa2',NULL,NULL,NULL,NULL),
('CRM US Equity','US79466L3024','Salesforce Inc','Common Stock','Technology','US','USD',246.1,300.0,24.7,236,'A+','A2',NULL,NULL,NULL,NULL),
('ASML NA Equity','NL0010273215','ASML Holding NV','Common Stock','Technology','NL','EUR',912.4,1010.0,33.0,360,'A+','A2',NULL,NULL,NULL,NULL),
('SAP GR Equity','DE0007164600','SAP SE','Common Stock','Technology','DE','EUR',228.6,285.0,38.5,267,'A+','A2',NULL,NULL,NULL,NULL),
('GOOGL US Equity','US02079K3059','Alphabet Inc','Common Stock','Communications','US','USD',268.3,290.0,26.1,3240,'AA+','Aa2',NULL,NULL,NULL,NULL),
('META US Equity','US30303M1027','Meta Platforms Inc','Common Stock','Communications','US','USD',712.6,820.0,26.9,1790,'AA-','Aa3',NULL,NULL,NULL,NULL),
('NFLX US Equity','US64110L1061','Netflix Inc','Common Stock','Communications','US','USD',1098.0,1290.0,45.0,465,'A','A3',NULL,NULL,NULL,NULL),
('DIS US Equity','US2546871060','Walt Disney Co','Common Stock','Communications','US','USD',112.3,131.0,18.2,203,'A-','A2',NULL,NULL,NULL,NULL),
('T US Equity','US00206R1023','AT&T Inc','Common Stock','Communications','US','USD',25.9,30.5,15.8,186,'BBB','Baa2',NULL,NULL,NULL,NULL),
('VZ US Equity','US92343V1044','Verizon Communications Inc','Common Stock','Communications','US','USD',40.1,47.0,9.4,169,'BBB+','Baa1',NULL,NULL,NULL,NULL),
('AMZN US Equity','US0231351067','Amazon.com Inc','Common Stock','Consumer Discretionary','US','USD',226.8,265.0,34.6,2420,'AA','A1',NULL,NULL,NULL,NULL),
('TSLA US Equity','US88160R1014','Tesla Inc','Common Stock','Consumer Discretionary','US','USD',448.9,365.0,190.0,1490,'BBB','Baa3',NULL,NULL,NULL,NULL),
('HD US Equity','US4370761029','Home Depot Inc','Common Stock','Consumer Discretionary','US','USD',384.2,430.0,26.0,382,'A','A2',NULL,NULL,NULL,NULL),
('MCD US Equity','US5801351017','McDonald''s Corp','Common Stock','Consumer Discretionary','US','USD',301.7,325.0,25.9,215,'BBB+','Baa1',NULL,NULL,NULL,NULL),
('NKE US Equity','US6541061031','Nike Inc','Common Stock','Consumer Discretionary','US','USD',67.4,78.0,33.0,99,'AA-','A1',NULL,NULL,NULL,NULL),
('MC FP Equity','FR0000121014','LVMH Moet Hennessy Louis Vuitton','Common Stock','Consumer Discretionary','FR','EUR',598.2,640.0,25.8,298,'AA-','Aa3',NULL,NULL,NULL,NULL),
('WMT US Equity','US9311421039','Walmart Inc','Common Stock','Consumer Staples','US','USD',101.8,115.0,38.2,812,'AA','Aa2',NULL,NULL,NULL,NULL),
('COST US Equity','US22160K1059','Costco Wholesale Corp','Common Stock','Consumer Staples','US','USD',918.4,1050.0,50.1,407,'AA','Aa3',NULL,NULL,NULL,NULL),
('PG US Equity','US7427181091','Procter & Gamble Co','Common Stock','Consumer Staples','US','USD',151.2,170.0,23.4,354,'AA-','Aa3',NULL,NULL,NULL,NULL),
('KO US Equity','US1912161007','Coca-Cola Co','Common Stock','Consumer Staples','US','USD',69.8,77.0,23.1,300,'A+','A1',NULL,NULL,NULL,NULL),
('PEP US Equity','US7134481081','PepsiCo Inc','Common Stock','Consumer Staples','US','USD',148.9,160.0,22.0,204,'A+','A1',NULL,NULL,NULL,NULL),
('NESN SW Equity','CH0038863350','Nestle SA','Common Stock','Consumer Staples','CH','CHF',79.3,92.0,18.9,205,'AA-','Aa3',NULL,NULL,NULL,NULL),
('LLY US Equity','US5324571083','Eli Lilly & Co','Common Stock','Health Care','US','USD',824.5,950.0,53.8,780,'A+','A1',NULL,NULL,NULL,NULL),
('UNH US Equity','US91324P1021','UnitedHealth Group Inc','Common Stock','Health Care','US','USD',358.6,400.0,18.6,325,'A+','A2',NULL,NULL,NULL,NULL),
('JNJ US Equity','US4781601046','Johnson & Johnson','Common Stock','Health Care','US','USD',190.4,205.0,18.3,458,'AAA','Aaa',NULL,NULL,NULL,NULL),
('ABBV US Equity','US00287Y1091','AbbVie Inc','Common Stock','Health Care','US','USD',228.7,250.0,18.0,404,'A-','A3',NULL,NULL,NULL,NULL),
('MRK US Equity','US58933Y1055','Merck & Co Inc','Common Stock','Health Care','US','USD',86.2,99.0,10.4,215,'A+','A1',NULL,NULL,NULL,NULL),
('PFE US Equity','US7170811035','Pfizer Inc','Common Stock','Health Care','US','USD',24.9,28.5,7.9,141,'A','A2',NULL,NULL,NULL,NULL),
('NOVOB DC Equity','DK0062498333','Novo Nordisk A/S','Common Stock','Health Care','DK','DKK',318.5,420.0,13.9,212,'AA-','Aa3',NULL,NULL,NULL,NULL),
('AZN LN Equity','GB0009895292','AstraZeneca PLC','Common Stock','Health Care','GB','GBP',12450.0,13800.0,17.8,252,'A','A2',NULL,NULL,NULL,NULL),
('JPM US Equity','US46625H1005','JPMorgan Chase & Co','Common Stock','Financials','US','USD',309.6,335.0,15.4,851,'A','A1',NULL,NULL,NULL,NULL),
('BAC US Equity','US0605051046','Bank of America Corp','Common Stock','Financials','US','USD',52.8,58.0,14.1,390,'A-','A1',NULL,NULL,NULL,NULL),
('GS US Equity','US38141G1040','Goldman Sachs Group Inc','Common Stock','Financials','US','USD',803.9,840.0,17.2,247,'BBB+','A2',NULL,NULL,NULL,NULL),
('MS US Equity','US6174464486','Morgan Stanley','Common Stock','Financials','US','USD',163.4,170.0,17.8,261,'A-','A1',NULL,NULL,NULL,NULL),
('V US Equity','US92826C8394','Visa Inc','Common Stock','Financials','US','USD',344.1,400.0,31.6,665,'AA-','Aa3',NULL,NULL,NULL,NULL),
('MA US Equity','US57636Q1040','Mastercard Inc','Common Stock','Financials','US','USD',561.2,650.0,36.7,510,'A+','Aa3',NULL,NULL,NULL,NULL),
('BRK/B US Equity','US0846707026','Berkshire Hathaway Inc','Common Stock','Financials','US','USD',487.3,530.0,16.1,1050,'AA','Aa2',NULL,NULL,NULL,NULL),
('HSBA LN Equity','GB0005405286','HSBC Holdings PLC','Common Stock','Financials','GB','GBP',1012.5,1080.0,9.6,232,'A-','A3',NULL,NULL,NULL,NULL),
('XOM US Equity','US30231G1022','Exxon Mobil Corp','Common Stock','Energy','US','USD',114.6,126.0,15.9,488,'AA-','Aa2',NULL,NULL,NULL,NULL),
('CVX US Equity','US1667641005','Chevron Corp','Common Stock','Energy','US','USD',154.2,170.0,19.4,312,'AA-','Aa2',NULL,NULL,NULL,NULL),
('SHEL LN Equity','GB00BP6MXD84','Shell PLC','Common Stock','Energy','GB','GBP',2735.0,3050.0,12.8,212,'A+','Aa2',NULL,NULL,NULL,NULL),
('TTE FP Equity','FR0000120271','TotalEnergies SE','Common Stock','Energy','FR','EUR',53.9,62.0,9.1,124,'A+','A1',NULL,NULL,NULL,NULL),
('CAT US Equity','US1491231015','Caterpillar Inc','Common Stock','Industrials','US','USD',538.4,560.0,26.3,252,'A','A2',NULL,NULL,NULL,NULL),
('BA US Equity','US0970231058','Boeing Co','Common Stock','Industrials','US','USD',219.6,255.0,NULL,166,'BBB-','Baa3',NULL,NULL,NULL,NULL),
('SIE GR Equity','DE0007236101','Siemens AG','Common Stock','Industrials','DE','EUR',238.1,262.0,20.4,188,'AA-','Aa3',NULL,NULL,NULL,NULL),
('NEE US Equity','US65339F1012','NextEra Energy Inc','Common Stock','Utilities','US','USD',84.7,92.0,26.9,174,'A-','Baa1',NULL,NULL,NULL,NULL),
('DUK US Equity','US26441C2044','Duke Energy Corp','Common Stock','Utilities','US','USD',124.9,133.0,20.1,97,'BBB+','Baa2',NULL,NULL,NULL,NULL),
-- Fixed income (synthetic bond identifiers; issuer ratings mirror the equities above)
('T 4.25 08/15/35 Govt','US91282CNT44','US Treasury 4.25% 2035','US GOVERNMENT','Government','US','USD',100.9,NULL,NULL,NULL,'AA+','Aaa',4.13,0,4.25,'2035-08-15'),
('T 4.625 05/15/55 Govt','US912810UK33','US Treasury 4.625% 2055','US GOVERNMENT','Government','US','USD',98.1,NULL,NULL,NULL,'AA+','Aaa',4.74,0,4.625,'2055-05-15'),
('DBR 2.6 08/15/35 Govt','DE000BU2Z056','Bundesrepublik 2.6% 2035','EURO-ZONE','Government','DE','EUR',99.4,NULL,NULL,NULL,'AAA','Aaa',2.67,0,2.6,'2035-08-15'),
('ORCL 5.375 09/27/54 Corp','US68389XCT01','Oracle Corp 5.375% 2054','GLOBAL','Technology','US','USD',88.6,NULL,NULL,NULL,'BBB','Baa2',6.21,168,5.375,'2054-09-27'),
('BA 6.858 05/01/54 Corp','US097023DJ17','Boeing Co 6.858% 2054','GLOBAL','Industrials','US','USD',105.2,NULL,NULL,NULL,'BBB-','Baa3',6.45,195,6.858,'2054-05-01'),
('INTC 5.6 02/21/54 Corp','US458140CK49','Intel Corp 5.6% 2054','GLOBAL','Technology','US','USD',90.3,NULL,NULL,NULL,'BBB','Baa2',6.33,182,5.6,'2054-02-21'),
('T 3.5 09/15/53 Corp','US00206RMN98','AT&T Inc 3.5% 2053','GLOBAL','Communications','US','USD',68.4,NULL,NULL,NULL,'BBB','Baa2',5.94,141,3.5,'2053-09-15'),
('JPM 5.336 01/23/35 Corp','US46647PEB86','JPMorgan Chase 5.336% 2035','GLOBAL','Financials','US','USD',102.7,NULL,NULL,NULL,'A','A1',4.96,92,5.336,'2035-01-23'),
('AAPL 4.85 05/10/53 Corp','US037833ET32','Apple Inc 4.85% 2053','GLOBAL','Technology','US','USD',95.8,NULL,NULL,NULL,'AA+','Aaa',5.12,52,4.85,'2053-05-10'),
('TSLA 2 05/15/30 Corp','US88160RAK72','Tesla Inc 2% 2030 (Conv)','CONVERTIBLE','Consumer Discretionary','US','USD',196.4,NULL,NULL,NULL,'BBB','Baa3',1.10,NULL,2.0,'2030-05-15')
;

UPDATE BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER SET ISSUER_TICKER = 'UST' WHERE TICKER LIKE 'T %Govt';

-- ---------------------------------------------------------------------
-- 2. "Live" market data view — ticks on every query (simulates DL intraday)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW BLOOMBERG_DATA_LICENSE.DL.SECURITIES_MARKET_DATA AS
WITH t AS (
  SELECT m.*,
         -- deterministic daily drift + per-query micro tick
         (UNIFORM(-180, 220, HASH(ID_ISIN, CURRENT_DATE())) / 10000.0)
       + (UNIFORM(-15, 15, RANDOM()) / 10000.0) AS chg
  FROM BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER m
)
SELECT ID_BB_GLOBAL, TICKER, ID_ISIN, NAME, SECURITY_TYP, BICS_LEVEL_1_SECTOR_NAME, CNTRY_OF_RISK, CRNCY, ISSUER_TICKER,
       ROUND(PX_CLOSE_1D * (1 + IFF(SECURITY_TYP IN ('Common Stock','CONVERTIBLE'), chg, chg / 8)), 3) AS PX_LAST,
       PX_CLOSE_1D,
       ROUND(IFF(SECURITY_TYP IN ('Common Stock','CONVERTIBLE'), chg, chg / 8) * 100, 2) AS CHG_PCT_1D,
       BEST_TARGET_PRICE, PE_RATIO, CUR_MKT_CAP_BN, RTG_SP, RTG_MOODY,
       ROUND(YLD_YTM_MID - IFF(YLD_YTM_MID IS NULL, 0, chg * 2), 3) AS YLD_YTM_MID,
       OAS_SPREAD_BID, CPN, MATURITY,
       DATEADD('second', -UNIFORM(1, 45, RANDOM()), CURRENT_TIMESTAMP()) AS LAST_UPDATE_TS
FROM t;

-- ---------------------------------------------------------------------
-- 3. Internal portfolio holdings (3 funds, multi-asset) + FX
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE INTERNAL_PORTFOLIO.CORE.FX_RATES (CRNCY STRING, USD_PER_UNIT FLOAT) AS
SELECT * FROM VALUES ('USD',1.0),('EUR',1.163),('GBP',0.01334),('CHF',1.252),('DKK',0.1558); -- GBP quoted in pence (GBp)

CREATE OR REPLACE TABLE INTERNAL_PORTFOLIO.CORE.PORTFOLIOS (PORTFOLIO_ID STRING, PORTFOLIO_NAME STRING, STRATEGY STRING, PM STRING, SECTOR_LIMIT_PCT FLOAT, ISSUER_LIMIT_PCT FLOAT) AS
SELECT * FROM VALUES
 ('GEQ-01','Global Equity Opportunities','Long-only equity','A. Moreau',25,7.5),
 ('MAI-02','Multi-Asset Income','Balanced 60/40','J. Patel',30,5.0),
 ('TCG-03','Tech & Communications Growth','Sector thematic','K. Lindqvist',60,10.0);

CREATE OR REPLACE TABLE INTERNAL_PORTFOLIO.CORE.HOLDINGS AS
WITH u AS (
  SELECT m.ID_ISIN, m.TICKER, m.SECURITY_TYP, m.BICS_LEVEL_1_SECTOR_NAME AS sector, m.PX_CLOSE_1D, m.CRNCY, p.PORTFOLIO_ID,
         -- target weights: thematic fund tilts to tech/comms; income fund holds the bonds
         CASE
           WHEN p.PORTFOLIO_ID = 'TCG-03' AND m.BICS_LEVEL_1_SECTOR_NAME IN ('Technology','Communications') AND m.SECURITY_TYP = 'Common Stock' THEN UNIFORM(30, 120, HASH(m.ID_ISIN, p.PORTFOLIO_ID))
           WHEN p.PORTFOLIO_ID = 'TCG-03' THEN 0
           WHEN p.PORTFOLIO_ID = 'MAI-02' AND m.SECURITY_TYP <> 'Common Stock' THEN UNIFORM(40, 110, HASH(m.ID_ISIN, p.PORTFOLIO_ID))
           WHEN p.PORTFOLIO_ID = 'GEQ-01' AND m.SECURITY_TYP <> 'Common Stock' THEN 0
           WHEN UNIFORM(0, 100, HASH(m.ID_ISIN, p.PORTFOLIO_ID, 7)) < 30 THEN 0
           ELSE UNIFORM(5, 40, HASH(m.ID_ISIN, p.PORTFOLIO_ID))
             * IFF(m.BICS_LEVEL_1_SECTOR_NAME = 'Technology' AND p.PORTFOLIO_ID = 'GEQ-01', 2.4, 1)   -- planted concentration breach
         END AS raw_w
  FROM BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER m
  CROSS JOIN INTERNAL_PORTFOLIO.CORE.PORTFOLIOS p
), aum AS (SELECT * FROM VALUES ('GEQ-01', 4.2e9), ('MAI-02', 2.8e9), ('TCG-03', 1.6e9) a(PORTFOLIO_ID, AUM_USD))
SELECT u.PORTFOLIO_ID, u.ID_ISIN, u.TICKER AS INTERNAL_TICKER,
       -- bonds held in face value (price per 100), equities in shares
       ROUND(a.AUM_USD * u.raw_w / SUM(u.raw_w) OVER (PARTITION BY u.PORTFOLIO_ID)
             / (u.PX_CLOSE_1D * f.USD_PER_UNIT / IFF(u.SECURITY_TYP = 'Common Stock', 1, 100)), 0) AS QUANTITY,
       IFF(u.SECURITY_TYP = 'Common Stock', 'SHARES', 'FACE') AS QTY_TYPE,
       ROUND(u.PX_CLOSE_1D * UNIFORM(70, 105, HASH(u.ID_ISIN, u.PORTFOLIO_ID, 3)) / 100, 2) AS AVG_COST_LOCAL,
       DATEADD('day', -UNIFORM(30, 900, HASH(u.ID_ISIN, u.PORTFOLIO_ID, 9)), '2026-10-27'::DATE) AS FIRST_BUY_DATE,
       '2026-10-27'::DATE AS AS_OF_DATE
FROM u JOIN aum a USING (PORTFOLIO_ID) JOIN INTERNAL_PORTFOLIO.CORE.FX_RATES f ON f.CRNCY = u.CRNCY
WHERE u.raw_w > 0;

-- ---------------------------------------------------------------------
-- 4. Internal analyst research views (proprietary)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE INTERNAL_PORTFOLIO.CORE.ANALYST_VIEWS AS
SELECT m.ID_ISIN,
       CASE m.TICKER
         WHEN 'NVDA US Equity' THEN 'Strong Buy' WHEN 'NOVOB DC Equity' THEN 'Strong Buy' WHEN 'UNH US Equity' THEN 'Buy'
         WHEN 'TSLA US Equity' THEN 'Sell'       WHEN 'INTC US Equity'  THEN 'Sell'       WHEN 'BA US Equity'  THEN 'Underweight'
         WHEN 'ORCL US Equity' THEN 'Hold'       WHEN 'NKE US Equity'   THEN 'Buy'        WHEN 'CRM US Equity' THEN 'Buy'
         ELSE DECODE(UNIFORM(0, 4, HASH(m.ID_ISIN, 11)), 0, 'Buy', 1, 'Hold', 2, 'Buy', 3, 'Hold', 'Overweight') END AS INTERNAL_RATING,
       ROUND(m.PX_CLOSE_1D * CASE m.TICKER
         WHEN 'NVDA US Equity' THEN 1.31 WHEN 'NOVOB DC Equity' THEN 1.42 WHEN 'UNH US Equity' THEN 1.24 WHEN 'NKE US Equity' THEN 1.27
         WHEN 'CRM US Equity'  THEN 1.29 WHEN 'TSLA US Equity'  THEN 0.62 WHEN 'INTC US Equity' THEN 0.74 WHEN 'BA US Equity' THEN 0.86
         WHEN 'ORCL US Equity' THEN 0.97
         ELSE UNIFORM(92, 114, HASH(m.ID_ISIN, 13)) / 100 END, 2) AS INTERNAL_FAIR_VALUE,
       CASE WHEN m.TICKER IN ('ORCL US Equity','INTC US Equity','BA US Equity','T US Equity') THEN 'Negative'
            WHEN m.TICKER IN ('NVDA US Equity','AMD US Equity','MSFT US Equity') THEN 'Positive' ELSE 'Stable' END AS INTERNAL_CREDIT_OUTLOOK,
       DECODE(m.BICS_LEVEL_1_SECTOR_NAME, 'Technology','R. Okafor', 'Communications','R. Okafor', 'Health Care','S. Brandt',
              'Financials','M. Ito', 'Energy','L. Duarte', 'Government','Rates Desk', 'C. Nguyen') AS ANALYST,
       CASE m.TICKER
         WHEN 'NVDA US Equity'  THEN 'Blackwell Ultra ramp + sovereign AI orders underappreciated by consensus'
         WHEN 'NOVOB DC Equity' THEN 'Oral GLP-1 launch de-risked; market pricing share loss too aggressively'
         WHEN 'TSLA US Equity'  THEN 'Auto margins compressing; robotaxi optionality already priced in'
         WHEN 'INTC US Equity'  THEN 'Foundry capex burn; leverage rising faster than rating implies'
         WHEN 'ORCL US Equity'  THEN 'OCI backlog strong but debt-funded capex pressures BBB rating'
         WHEN 'BA US Equity'    THEN 'Production cadence improving; balance sheet remains at BBB- cliff'
         WHEN 'UNH US Equity'   THEN 'Medicare Advantage repricing for 2027 restores margin trajectory'
         ELSE NULL END AS THESIS,
       DATEADD('day', -UNIFORM(1, 40, HASH(m.ID_ISIN, 17)), '2026-10-28'::DATE) AS LAST_REVIEWED
FROM BLOOMBERG_DATA_LICENSE.DL.SECURITY_MASTER m;
