/*
===============================================================================
Script Name : Get-SCCMSoftwareUpdateDeploymentInventory.sql
Author      : Sethu Kumar B
Purpose     : Validate whether software update deployments exist in SCCM
              and retrieve raw deployment inventory details.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Checks whether any software update deployments exist in SCCM
- Returns total deployment count
- Displays recent deployment details including:
    - Deployment name
    - Target collection
    - Deployment status
    - Compliance statistics

Use Cases:
- SCCM deployment validation
- Patch deployment troubleshooting
- Confirm deployment infrastructure health
- Verify Software Update deployment existence
- Troubleshoot missing monthly patch deployments

Main SCCM Views Used:
- v_UpdateDeploymentSummary

Important Notes:
- If TotalDeployments = 0:
    No software update deployments currently exist in SCCM

- Useful for validating whether:
    - ADRs are creating deployments
    - Software Update Groups are deployed
    - Deployment synchronization is functioning

===============================================================================
*/

-- ============================================================================
-- TABLE 1
-- Total Software Update Deployment Count
-- ============================================================================

SELECT

    -- Total number of software update deployments
    COUNT(*) AS TotalDeployments

FROM v_UpdateDeploymentSummary;


-- ============================================================================
-- TABLE 2
-- Raw Software Update Deployment Inventory
-- ============================================================================

SELECT TOP 20

    -- SCCM deployment name
    uds.AssignmentName,

    -- Target SCCM collection
    uds.CollectionName,

    -- Deployment enabled status
    -- 1 = Enabled
    -- 0 = Disabled
    uds.AssignmentEnabled,

    -- Deployment start time
    uds.StartTime,

    -- Last compliance summarization time
    uds.LastSummaryTime,

    -- Total targeted devices
    uds.NumTotal,

    -- Successfully installed devices
    uds.NumInstalled,

    -- Devices missing updates
    uds.NumMissing

FROM v_UpdateDeploymentSummary uds

ORDER BY

    -- Latest deployments first
    uds.StartTime DESC;