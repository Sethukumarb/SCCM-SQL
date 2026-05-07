/*
===============================================================================
Script Name : Get-SCCMFailedDeployments.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM software update deployments with failed devices.
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
-- TABLE 1: Deployments with Failures
-- ============================================================================

SELECT
    uds.AssignmentName AS DeploymentName,
    uds.CollectionName AS TargetCollection,

    CASE uds.AssignmentEnabled
        WHEN 1 THEN 'Enabled'
        WHEN 0 THEN 'Disabled'
        ELSE 'Unknown'
    END AS DeploymentStatus,

    uds.StartTime,
    uds.LastSummaryTime,
    uds.NumTotal AS TotalDevices,
    uds.NumInstalled AS Installed,
    uds.NumMissing AS Missing,
    uds.NumFailed AS Failed,
    uds.NumUnknown AS Unknown,
    uds.NumNotApplicable AS NotApplicable,

    CAST(
        100.0 * uds.NumFailed / NULLIF(uds.NumTotal, 0)
        AS DECIMAL(5,1)
    ) AS FailedPercentage

FROM v_UpdateDeploymentSummary uds

WHERE
    uds.AssignmentName IS NOT NULL
    AND uds.NumFailed > 0

ORDER BY
    uds.NumFailed DESC,
    uds.StartTime DESC;


-- ============================================================================
-- TABLE 2: Failed Deployment Summary Count
-- ============================================================================

SELECT
    COUNT(*) AS FailedDeploymentCount,
    SUM(uds.NumFailed) AS TotalFailedDevices
FROM v_UpdateDeploymentSummary uds
WHERE
    uds.AssignmentName IS NOT NULL
    AND uds.NumFailed > 0;