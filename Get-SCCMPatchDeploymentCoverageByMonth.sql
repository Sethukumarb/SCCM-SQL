/*
===============================================================================
Script Name : Get-SCCMPatchDeploymentCoverageByMonth.sql
Author      : Sethu Kumar B
Purpose     : Display SCCM patch deployment coverage grouped by month and
              target collection to identify deployment gaps.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves SCCM software update deployments grouped by patch month
  and target collection
- Shows deployment coverage trends across months
- Helps identify missing patch deployment periods
- Useful for compliance audits, patch investigations, and reporting

Use Case:
- Validate whether monthly Windows Cumulative Update deployments exist
- Identify missing deployment months (Example: July 2025 gap)
- Provide evidence for management/security review

Main SCCM View Used:
- v_UpdateDeploymentSummary

===============================================================================
*/

SELECT
    -- Patch deployment month in YYYY-MM format
    FORMAT(uds.StartTime, 'yyyy-MM') AS PatchMonth,

    -- Target SCCM collection name
    uds.CollectionName AS TargetCollection,

    -- Total unique deployments for the month and collection
    COUNT(DISTINCT uds.AssignmentName) AS DeploymentCount

FROM v_UpdateDeploymentSummary uds

WHERE
    -- Ensure deployment name exists
    uds.AssignmentName IS NOT NULL

    -- Ensure deployment start time exists
    AND uds.StartTime IS NOT NULL

    -- Filter deployments from January 2025 onwards
    AND uds.StartTime >= '2025-01-01'

GROUP BY
    -- Group by deployment month
    FORMAT(uds.StartTime, 'yyyy-MM'),

    -- Group by collection
    uds.CollectionName

ORDER BY
    -- Latest month first
    PatchMonth DESC,

    -- Sort collections alphabetically
    uds.CollectionName;