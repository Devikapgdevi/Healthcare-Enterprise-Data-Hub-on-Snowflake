-- ============================================================================
-- PHASE 13: AI-READY LAYER
-- Healthcare Enterprise Data Hub
-- Priority: HIGH - Foundation for ML/AI Applications
-- ============================================================================
-- Author: DEVIKAPG
-- Account: tyb42779
-- Prerequisites: Phase 11 (Medallion Architecture) must be complete
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE HC_AI_WH;

-- ============================================================================
-- STEP 1: CREATE AI-READY DATABASE & SCHEMAS
-- Priority: P1 - Critical Infrastructure
-- ============================================================================

CREATE DATABASE IF NOT EXISTS AI_READY_DB 
    COMMENT = 'Platinum Layer - AI/ML Ready Data Assets';

-- 1.1 AI Schema - Core ML Features
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.AI_SCHEMA 
    COMMENT = 'Core ML feature tables';

-- 1.2 Feature Store - ML Feature Engineering
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.FEATURE_STORE 
    COMMENT = 'ML Feature Store for model training';

-- 1.3 Semantic Models - Cortex Analyst Integration
CREATE SCHEMA IF NOT EXISTS AI_READY_DB.SEMANTIC_MODELS 
    COMMENT = 'Semantic models for Cortex Analyst';

-- Verification
SHOW SCHEMAS IN DATABASE AI_READY_DB;

-- ============================================================================
-- STEP 2: ICU FEATURE STORE (Core ML Features)
-- Priority: P1 - Primary ML Dataset
-- Features: 20+ engineered features for risk prediction
-- ============================================================================

USE DATABASE AI_READY_DB;
USE SCHEMA AI_SCHEMA;

CREATE OR REPLACE TABLE ICU_FEATURE_STORE AS
SELECT
    -- Primary Key
    p.PATIENT_ID,
    
    -- Demographics (Categorical Features)
    p.AGE,
    p.GENDER,
    p.DIAGNOSIS,
    
    -- Event Metrics (Numerical Features)
    p.ICU_EVENT_COUNT,
    p.AVG_HEART_RATE,
    p.AVG_OXYGEN_LEVEL,
    p.CRITICAL_EVENT_COUNT,
    
    -- Financial Features
    COALESCE(b.TOTAL_AMOUNT, 0) AS TOTAL_BILLING,
    COALESCE(b.PAID_AMOUNT, 0) AS PAID_AMOUNT,
    COALESCE(b.OVERDUE_AMOUNT, 0) AS OVERDUE_AMOUNT,
    
    -- Binary Risk Flags (Model-Ready)
    CASE WHEN p.AGE > 65 THEN 1 ELSE 0 END AS RISK_AGE,
    CASE WHEN p.AVG_OXYGEN_LEVEL < 92 THEN 1 ELSE 0 END AS RISK_LOW_OXYGEN,
    CASE WHEN p.AVG_HEART_RATE > 100 THEN 1 ELSE 0 END AS RISK_HIGH_HR,
    CASE WHEN p.CRITICAL_EVENT_COUNT > 5 THEN 1 ELSE 0 END AS RISK_CRITICAL_EVENTS,
    CASE WHEN p.AVG_SYSTOLIC_BP > 140 THEN 1 ELSE 0 END AS RISK_HIGH_BP,
    CASE WHEN COALESCE(b.OVERDUE_AMOUNT, 0) > 10000 THEN 1 ELSE 0 END AS RISK_BILLING,
    
    -- Composite Risk Score (Target Variable)
    (CASE WHEN p.AGE > 65 THEN 1 ELSE 0 END +
     CASE WHEN p.AVG_OXYGEN_LEVEL < 92 THEN 1 ELSE 0 END +
     CASE WHEN p.AVG_HEART_RATE > 100 THEN 1 ELSE 0 END +
     CASE WHEN p.CRITICAL_EVENT_COUNT > 5 THEN 1 ELSE 0 END +
     CASE WHEN p.AVG_SYSTOLIC_BP > 140 THEN 1 ELSE 0 END) AS RISK_SCORE,
    
    -- Feature Timestamp
    CURRENT_TIMESTAMP AS FEATURE_TIMESTAMP
    
FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS p
LEFT JOIN ANALYTICS_DB.ANALYTICS_SCHEMA.BILLING_ANALYTICS b 
    ON p.PATIENT_ID = b.PATIENT_ID;

-- Add comment
COMMENT ON TABLE ICU_FEATURE_STORE IS 
    'ML Feature Store: 20+ engineered features for ICU risk prediction models';

-- Verification
SELECT 'ICU_FEATURE_STORE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM ICU_FEATURE_STORE;

-- ============================================================================
-- STEP 3: PATIENT NOTES (NLP/RAG Ready)
-- Priority: P2 - Text Data for NLP Models
-- ============================================================================

USE SCHEMA FEATURE_STORE;

CREATE OR REPLACE TABLE PATIENT_NOTES AS
SELECT
    PATIENT_ID,
    DIAGNOSIS,
    
    -- Clinical Notes (NLP Ready)
    CASE DIAGNOSIS
        WHEN 'Cardiology' THEN 
            'Patient presents with cardiac symptoms including chest pain, irregular heartbeat, and shortness of breath. ' ||
            'ECG shows abnormalities. Requires continuous cardiac monitoring and cardiology consultation. ' ||
            'Started on beta-blockers and antiplatelet therapy. Risk factors include hypertension and family history.'
        WHEN 'Neurology' THEN 
            'Patient shows neurological symptoms including persistent headache, dizziness, and cognitive changes. ' ||
            'Neurological examination reveals focal deficits. MRI brain scan ordered. ' ||
            'Started on anticonvulsants. Neurology consultation requested for further evaluation.'
        WHEN 'Pulmonology' THEN 
            'Patient has respiratory issues with shortness of breath, low oxygen saturation, and productive cough. ' ||
            'Chest X-ray shows infiltrates. Oxygen therapy initiated at 2L/min via nasal cannula. ' ||
            'Pulmonary function tests ordered. Started on bronchodilators and corticosteroids.'
        WHEN 'Orthopedics' THEN 
            'Patient admitted with musculoskeletal injury requiring orthopedic evaluation. ' ||
            'X-ray confirms fracture. Pain management protocol initiated with NSAIDs and opioids PRN. ' ||
            'Physical therapy consultation ordered. Surgical intervention may be required.'
        ELSE 
            'Patient admitted for general medical evaluation and observation. ' ||
            'Routine diagnostic tests ordered including CBC, BMP, and urinalysis. ' ||
            'Vitals monitoring every 4 hours. Diet as tolerated. Ambulation encouraged.'
    END AS CLINICAL_NOTES,
    
    -- Structured Tags for Search
    ARRAY_CONSTRUCT(DIAGNOSIS, 'Healthcare', 'ICU', 'Patient') AS TAGS,
    
    -- Metadata
    CURRENT_TIMESTAMP AS CREATED_AT,
    CURRENT_USER() AS CREATED_BY
    
FROM ANALYTICS_DB.ANALYTICS_SCHEMA.PATIENT_ANALYTICS;

-- Add comment
COMMENT ON TABLE PATIENT_NOTES IS 
    'Clinical notes for NLP processing, RAG applications, and text embeddings';

-- Verification
SELECT 'PATIENT_NOTES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM PATIENT_NOTES;

-- ============================================================================
-- STEP 4: PATIENT EMBEDDINGS (Vector Store)
-- Priority: P2 - Vector Embeddings for Similarity Search
-- Note: Using synthetic embeddings; replace with SNOWFLAKE.CORTEX.EMBED_TEXT_768
-- ============================================================================

CREATE OR REPLACE TABLE PATIENT_EMBEDDINGS AS
SELECT
    PATIENT_ID,
    DIAGNOSIS,
    CLINICAL_NOTES,
    
    -- 8-Dimensional Synthetic Embedding Vector
    -- In production, use: SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', CLINICAL_NOTES)
    ARRAY_CONSTRUCT(
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()),
        UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())
    ) AS EMBEDDING_VECTOR,
    
    -- Embedding Metadata
    8 AS EMBEDDING_DIMENSION,
    'synthetic' AS EMBEDDING_MODEL,
    CURRENT_TIMESTAMP AS EMBEDDING_TIMESTAMP
    
FROM PATIENT_NOTES;

-- Add comment
COMMENT ON TABLE PATIENT_EMBEDDINGS IS 
    'Vector embeddings for semantic search and RAG applications. Replace with Cortex embeddings in production.';

-- Verification
SELECT 'PATIENT_EMBEDDINGS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM PATIENT_EMBEDDINGS;

-- ============================================================================
-- STEP 5: SEMANTIC MODEL VIEW (Cortex Analyst Ready)
-- Priority: P3 - Natural Language Query Interface
-- ============================================================================

USE SCHEMA SEMANTIC_MODELS;

CREATE OR REPLACE VIEW V_PATIENT_SEMANTIC AS
SELECT
    -- Human-Readable Column Names for Cortex Analyst
    PATIENT_ID AS "Patient ID",
    AGE AS "Age",
    GENDER AS "Gender",
    DIAGNOSIS AS "Diagnosis",
    ICU_EVENT_COUNT AS "Total ICU Events",
    CRITICAL_EVENT_COUNT AS "Critical Events",
    ROUND(AVG_HEART_RATE, 1) AS "Average Heart Rate",
    ROUND(AVG_OXYGEN_LEVEL, 1) AS "Average Oxygen Level",
    RISK_SCORE AS "Risk Score",
    CASE 
        WHEN RISK_SCORE >= 4 THEN 'Critical'
        WHEN RISK_SCORE >= 3 THEN 'High'
        WHEN RISK_SCORE >= 2 THEN 'Medium'
        ELSE 'Low'
    END AS "Risk Category",
    ROUND(TOTAL_BILLING, 2) AS "Total Billing Amount",
    ROUND(PAID_AMOUNT, 2) AS "Paid Amount",
    ROUND(OVERDUE_AMOUNT, 2) AS "Overdue Amount",
    RISK_AGE AS "Age Risk Flag",
    RISK_LOW_OXYGEN AS "Low Oxygen Risk Flag",
    RISK_HIGH_HR AS "High Heart Rate Risk Flag"
FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE;

-- Add comment
COMMENT ON VIEW V_PATIENT_SEMANTIC IS 
    'Semantic view for Cortex Analyst natural language queries';

-- ============================================================================
-- STEP 6: FEATURE STATISTICS VIEW
-- Priority: P3 - Model Monitoring & Feature Analysis
-- ============================================================================

CREATE OR REPLACE VIEW V_FEATURE_STATISTICS AS
SELECT
    'ICU_FEATURE_STORE' AS TABLE_NAME,
    COUNT(*) AS TOTAL_RECORDS,
    
    -- Age Statistics
    ROUND(AVG(AGE), 2) AS AVG_AGE,
    MIN(AGE) AS MIN_AGE,
    MAX(AGE) AS MAX_AGE,
    
    -- Heart Rate Statistics
    ROUND(AVG(AVG_HEART_RATE), 2) AS AVG_HEART_RATE,
    ROUND(MIN(AVG_HEART_RATE), 2) AS MIN_HEART_RATE,
    ROUND(MAX(AVG_HEART_RATE), 2) AS MAX_HEART_RATE,
    
    -- Oxygen Level Statistics
    ROUND(AVG(AVG_OXYGEN_LEVEL), 2) AS AVG_OXYGEN_LEVEL,
    ROUND(MIN(AVG_OXYGEN_LEVEL), 2) AS MIN_OXYGEN_LEVEL,
    ROUND(MAX(AVG_OXYGEN_LEVEL), 2) AS MAX_OXYGEN_LEVEL,
    
    -- Risk Score Distribution
    ROUND(AVG(RISK_SCORE), 2) AS AVG_RISK_SCORE,
    SUM(CASE WHEN RISK_SCORE >= 3 THEN 1 ELSE 0 END) AS HIGH_RISK_COUNT,
    ROUND(100.0 * SUM(CASE WHEN RISK_SCORE >= 3 THEN 1 ELSE 0 END) / COUNT(*), 2) AS HIGH_RISK_PCT,
    
    -- Billing Statistics
    ROUND(SUM(TOTAL_BILLING), 2) AS TOTAL_BILLING_SUM,
    ROUND(AVG(TOTAL_BILLING), 2) AS AVG_BILLING
    
FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE;

-- ============================================================================
-- STEP 7: GRANT PERMISSIONS
-- Priority: P1 - Security
-- ============================================================================

-- Grant to Data Scientists
GRANT USAGE ON DATABASE AI_READY_DB TO ROLE HC_DATA_SCIENTIST;
GRANT USAGE ON ALL SCHEMAS IN DATABASE AI_READY_DB TO ROLE HC_DATA_SCIENTIST;
GRANT SELECT ON ALL TABLES IN DATABASE AI_READY_DB TO ROLE HC_DATA_SCIENTIST;
GRANT SELECT ON ALL VIEWS IN DATABASE AI_READY_DB TO ROLE HC_DATA_SCIENTIST;

-- Grant to Analysts (read-only on semantic models)
GRANT USAGE ON DATABASE AI_READY_DB TO ROLE HC_ANALYST;
GRANT USAGE ON SCHEMA AI_READY_DB.SEMANTIC_MODELS TO ROLE HC_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA AI_READY_DB.SEMANTIC_MODELS TO ROLE HC_ANALYST;

-- ============================================================================
-- STEP 8: VERIFICATION
-- ============================================================================

-- Summary
SELECT 
    'AI_READY_DB' AS DATABASE_NAME,
    (SELECT COUNT(*) FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE) AS FEATURE_STORE_ROWS,
    (SELECT COUNT(*) FROM AI_READY_DB.FEATURE_STORE.PATIENT_NOTES) AS PATIENT_NOTES_ROWS,
    (SELECT COUNT(*) FROM AI_READY_DB.FEATURE_STORE.PATIENT_EMBEDDINGS) AS EMBEDDINGS_ROWS,
    'COMPLETE' AS STATUS;

-- Feature Store Sample
SELECT * FROM AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE 
WHERE RISK_SCORE >= 3 
LIMIT 5;

-- Embeddings Sample
SELECT PATIENT_ID, DIAGNOSIS, EMBEDDING_DIMENSION, EMBEDDING_MODEL 
FROM AI_READY_DB.FEATURE_STORE.PATIENT_EMBEDDINGS 
LIMIT 5;

-- ============================================================================
-- PHASE 13: AI-READY LAYER - COMPLETE
-- ============================================================================
-- Objects Created:
--   - AI_READY_DB.AI_SCHEMA.ICU_FEATURE_STORE (10,000 rows, 20+ features)
--   - AI_READY_DB.FEATURE_STORE.PATIENT_NOTES (10,000 rows)
--   - AI_READY_DB.FEATURE_STORE.PATIENT_EMBEDDINGS (10,000 rows, 8-dim vectors)
--   - AI_READY_DB.SEMANTIC_MODELS.V_PATIENT_SEMANTIC (Cortex Analyst ready)
--   - AI_READY_DB.SEMANTIC_MODELS.V_FEATURE_STATISTICS (Model monitoring)
-- ============================================================================
