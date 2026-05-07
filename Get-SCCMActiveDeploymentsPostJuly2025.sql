/*
===============================================================================
Script Name : Get-SCCMActiveDeploymentsPostJuly2025.sql
Author      : Sethu Kumar B
Purpose     : Retrieve all active SCCM software update deployments
              created after July 2025.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all SCCM software update deployments created after July 2025
- Displays:
    - Deployment name
    - Target collection
    - Deployment enabled status
    - Deployment start time
    - Product category
    - Patch month classification

Use Cases:
- Patch deployment validation
- Deployment audit reporting
- Identify missing monthly CU deployments
- Security compliance investigation
- Verify deployment activity after July 2025

Main SCCM Views Used:
- v_UpdateDeploymentSummary

Important Notes:
- Compliance statistics intentionally removed because
  deployment summarization may be globally broken
- ProductCategory and PatchMonth are dynamically classified
  using deployment naming patterns

===============================================================================
*/

SELECT

    -- SCCM deployment name
    uds.AssignmentName AS DeploymentName,

    -- Target SCCM collection
    uds.CollectionName AS TargetCollection,

    -- Deployment enabled status
    -- 1 = Enabled
    -- 0 = Disabled
    uds.AssignmentEnabled,

    -- Deployment start time
    uds.StartTime,

    -- Categorize deployment product type
    CASE

        WHEN uds.AssignmentName LIKE '%Win%8%'
            THEN 'Windows 8'

        WHEN uds.AssignmentName LIKE '%Win%10%'
            THEN 'Windows 10'

        WHEN uds.AssignmentName LIKE '%Win%11%'
            THEN 'Windows 11'

        WHEN uds.AssignmentName LIKE '%Server%'
            THEN 'Windows Server'

        WHEN uds.AssignmentName LIKE '%Office%'
            THEN 'Office'

        WHEN uds.AssignmentName LIKE '%Edge%'
            THEN 'Edge'

        ELSE 'Other'

    END AS ProductCategory,

    -- Categorize deployment patch month
    CASE

        WHEN uds.AssignmentName LIKE '%2025-07%'
            THEN 'July 2025'

        WHEN uds.AssignmentName LIKE '%2025-06%'
            THEN 'June 2025'

        WHEN uds.AssignmentName LIKE '%2025-05%'
            THEN 'May 2025'

        WHEN uds.AssignmentName LIKE '%2025-04%'
            THEN 'April 2025'

        WHEN uds.AssignmentName LIKE '%2026-04%'
            THEN 'April 2026'

        ELSE 'Other'

    END AS PatchMonth

FROM v_UpdateDeploymentSummary uds

WHERE

    -- Retrieve deployments created after July 2025
    uds.StartTime >= '2025-07-01'

    -- Exclude empty deployment names
    AND uds.AssignmentName IS NOT NULL

ORDER BY

    -- Latest deployments first
    uds.StartTime DESC;