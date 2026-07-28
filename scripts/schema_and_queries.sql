-- =============================================================================
--  B2B (Business to Business) LEAD INTELLIGENCE ANALYTICS SCRIPT
--  Author: Data Analytics Pipeline
--  Engine: MySQL Workbench
--  Description: Star schema design with dimension tables, fact tables,
--              bridge tables for multi-valued attributes, and analytical queries.
-- ==============================================================================
-- ==========================================================
-- Query 1: DATABASE CREATION
-- ==========================================================

CREATE DATABASE company_intelligence_and_sales_lead_export;
USE company_intelligence_and_sales_lead_export;

-- ==========================================================
-- Query 2: CREATE THE MASTER ACCOUNT DIMENSION TABLE
-- ==========================================================
CREATE TABLE dim_accounts (
    apollo_account_id VARCHAR(50) PRIMARY KEY,
    company_name VARCHAR(255),
    account_stage VARCHAR(100),
    industry VARCHAR(255),
    founded_year INT,
    website VARCHAR(255),
    company_country VARCHAR(100),
    company_state VARCHAR(100),
    company_city VARCHAR(100)
    );
    
 -- ==========================================================
 -- Query 3: CREATE THE FINANCIAL METRICS FACT TABLE
 -- ==========================================================

CREATE TABLE fact_account_metrics (
    apollo_account_id VARCHAR(50),
    employee_count INT,
    annual_revenue NUMERIC(15, 2),
    total_funding NUMERIC(15, 2),
    latest_funding_amount NUMERIC(15, 2),
    PRIMARY KEY (apollo_account_id),
    CONSTRAINT fk_fact_accounts 
        FOREIGN KEY (apollo_account_id) REFERENCES dim_accounts(apollo_account_id)
);

 -- ==========================================================
 -- Query 4: CREATE THE TECHNOLOGY CATALOG DIMENSION
 -- ==========================================================

CREATE TABLE dim_technologies (
    tech_id INT PRIMARY KEY,
    tech_name VARCHAR(255) UNIQUE
);

 -- ==================================================================
 --  Query 5: CREATE THE MANY-TO-MANY BRIDGE TABLE FOR TECNOLOGIES
  -- =================================================================

CREATE TABLE bridge_account_tech (
    apollo_account_id VARCHAR(50),
    tech_id INT,
    PRIMARY KEY (apollo_account_id, tech_id),
    CONSTRAINT fk_bridge_tech_account 
        FOREIGN KEY (apollo_account_id) REFERENCES dim_accounts(apollo_account_id),
    CONSTRAINT fk_bridge_tech_catalog 
        FOREIGN KEY (tech_id) REFERENCES dim_technologies(tech_id)
);
    
     -- ==========================================================
	 -- Query 6: CREATE THE KEYWORD CATALOG DIMENSION
	 -- ==========================================================

CREATE TABLE dim_keywords (
    keyword_id INT PRIMARY KEY,
    keyword_name VARCHAR(255) UNIQUE
);

	 -- ==========================================================
     -- Query 7: CREATE THE MANY-TO-MANY BRIDGE TABLE FOR KEYWORDS
	 -- ==========================================================

CREATE TABLE bridge_account_keywords (
    apollo_account_id VARCHAR(50),
    keyword_id INT,
    PRIMARY KEY (apollo_account_id, keyword_id),
    CONSTRAINT fk_bridge_kw_account 
        FOREIGN KEY (apollo_account_id) REFERENCES dim_accounts(apollo_account_id),
    CONSTRAINT fk_bridge_kw_catalog 
        FOREIGN KEY (keyword_id) REFERENCES dim_keywords(keyword_id)
);

     -- =========================================================================
     -- Query 8:  CROSS-TABLE ANALYTICS (JOINING DATA)
     -- Purpose: Since the company profiles are in dim_accounts and the
     --          financials are in fact_account_metrics, you use a JOIN
     --          to bring them together.
     --          Average Revenue and Employees by Industry:
	 -- =========================================================================
     
SELECT 
    a.industry,
    COUNT(a.apollo_account_id) AS total_companies,
    ROUND(AVG(m.annual_revenue), 2) AS avg_annual_revenue,
	ROUND(AVG(m.employee_count), 0) AS avg_employee_count
FROM dim_accounts a
JOIN fact_account_metrics m ON a.apollo_account_id = m.apollo_account_id
GROUP BY a.industry
ORDER BY avg_annual_revenue DESC;

	 -- =======================================================================
     -- Query 9: TECHNOGRAPHIC ANALYSIS (UNLOCKING THE BRIDGE TABLES)
     -- Purpose: Now you can easily count which software tools or tech
     --          Now you can easily count which software tools or tech.
     --         Find the Most Popular Technologies Across Your Accounts:
	 -- =======================================================================

SELECT 
    t.tech_name,
    COUNT(b.apollo_account_id) AS company_count
FROM dim_technologies t
JOIN bridge_account_tech b ON t.tech_id = b.tech_id
GROUP BY t.tech_name
ORDER BY company_count DESC;

    -- =============================================================================
	-- Query 10: FILTERING AND SEGMENTATION
    -- Purpose: You can mix and match filters to find highly specific lists of leads.
    --            Find heavily funded Tech companies in a specific city:
	-- =============================================================================
    
SELECT 
a.company_name, 
a.website, 
m.total_funding, 
a.company_city
FROM dim_accounts a
JOIN fact_account_metrics m ON a.apollo_account_id = m.apollo_account_id
WHERE a.industry LIKE '%Technology%' 
  AND m.total_funding > 1000000
ORDER BY m.total_funding DESC;

	-- =============================================================================
	-- QUERY 11: High-Value Target Segmentation (Lead Scoring Simulation)
	-- Purpose: Filters out a highly specific list of target leads based on strict
	--          firmographic criteria (e.g., companies that have raised funding 
	--          and have a substantial employee base) so sales teams know who to call.
	-- =============================================================================

SELECT 
    a.company_name, 
    a.website, 
    a.industry, 
    m.employee_count, 
    m.total_funding
FROM dim_accounts a
JOIN fact_account_metrics m ON a.apollo_account_id = m.apollo_account_id
WHERE m.total_funding > 0 
  AND m.employee_count >= 50
ORDER BY m.total_funding DESC;

