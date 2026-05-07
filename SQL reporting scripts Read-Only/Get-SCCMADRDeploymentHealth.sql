/*
===============================================================================
Script Name : Get-SCCMADRDeploymentHealth.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM Automatic Deployment Rule status and health details.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- IMPORTANT:
-- Make sure you are connected to the SCCM Site Database before running.
-- Example:
-- USE CM_ABC;
-- GO


-- ============================================================================
-- TABLE 1: ADR Status and Health Details
-- ============================================================================

SELECT
    adr.AutoDeploymentID,
    adr.Name AS ADRName,

    CASE adr.AutoDeploymentEnabled
        WHEN 1 THEN 'Enabled'
        WHEN 0 THEN 'Disabled'
        ELSE 'Unknown'
    END AS ADRStatus,

    adr.LastRunTime,
    adr.LastErrorCode,
    adr.LastErrorTime,
    adr.AssociatedUpdateGroupID,
    adr.AssociatedDeploymentID,

    CASE
        WHEN adr.AutoDeploymentEnabled = 0 THEN 'Disabled'
        WHEN adr.LastErrorCode IS NULL THEN 'No Error Reported'
        WHEN adr.LastErrorCode = 0 THEN 'Healthy'
        ELSE 'Needs Checking'
    END AS HealthStatus

FROM vSMS_AutoDeployments adr

ORDER BY
    ADRName;


-- ============================================================================
-- TABLE 2: ADR Health Summary
-- ============================================================================

SELECT
    HealthStatus,
    COUNT(*) AS ADRCount
FROM
(
    SELECT
        CASE
            WHEN adr.AutoDeploymentEnabled = 0 THEN 'Disabled'
            WHEN adr.LastErrorCode IS NULL THEN 'No Error Reported'
            WHEN adr.LastErrorCode = 0 THEN 'Healthy'
            ELSE 'Needs Checking'
        END AS HealthStatus
    FROM vSMS_AutoDeployments adr
) AS ADRSummary

GROUP BY
    HealthStatus

ORDER BY
    ADRCount DESC;