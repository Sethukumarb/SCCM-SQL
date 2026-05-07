/*
===============================================================================
Script Name : Get-SCCMDeploymentSummary.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM software update deployment summary with
              compliance counts by deployment and target collection.
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
-- TABLE 1: Software Update Deployment Summary
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
        100.0 * uds.NumInstalled / NULLIF(uds.NumTotal, 0)
        AS DECIMAL(5,1)
    ) AS InstalledPercentage

FROM v_UpdateDeploymentSummary uds

WHERE
    uds.AssignmentName IS NOT NULL

ORDER BY
    uds.StartTime DESC,
    uds.AssignmentName;


-- ============================================================================
-- TABLE 2: Deployment Health Summary
-- ============================================================================

SELECT
    DeploymentHealth,
    COUNT(*) AS DeploymentCount
FROM
(
    SELECT
        CASE
            WHEN uds.AssignmentEnabled = 0 THEN 'Disabled'
            WHEN uds.NumTotal = 0 THEN 'No Targeted Devices'
            WHEN uds.NumFailed > 0 THEN 'Has Failures'
            WHEN uds.NumMissing > 0 THEN 'Has Missing Devices'
            WHEN uds.NumUnknown > 0 THEN 'Has Unknown Devices'
            ELSE 'Healthy'
        END AS DeploymentHealth
    FROM v_UpdateDeploymentSummary uds
    WHERE uds.AssignmentName IS NOT NULL
) AS SummaryData

GROUP BY
    DeploymentHealth

ORDER BY
    DeploymentCount DESC;