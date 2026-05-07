/*
===============================================================================
Script Name : Get-SCCMSUGDeploymentComplianceSummary.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM Software Update Group deployment compliance
              summary across all target collections.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all Software Update Group (SUG) deployments in SCCM
- Displays deployment compliance statistics including:
    - Total devices
    - Installed
    - Missing
    - Failed
    - Unknown
    - Not Applicable

Use Cases:
- Patch compliance validation
- Monthly deployment audit
- Deployment health monitoring
- Security remediation tracking
- Confirm whether specific monthly CUs were deployed

Main SCCM Views Used:
- v_UpdateDeploymentSummary

Compliance Status Meaning:
- Installed      = Devices successfully patched
- Missing        = Devices requiring the update
- Failed         = Installation failed
- Unknown        = No compliance state received
- NotApplicable  = Update not required on device

===============================================================================
*/

SELECT

    -- SCCM deployment name
    uds.AssignmentName AS DeploymentName,

    -- Target SCCM collection
    uds.CollectionName AS TargetCollection,

    -- Deployment enabled status
    uds.AssignmentEnabled,

    -- Deployment available/start time
    uds.StartTime,

    -- Last compliance summary update time
    uds.LastSummaryTime,

    -- Total targeted devices
    uds.NumTotal AS TotalDevices,

    -- Devices successfully installed
    uds.NumInstalled AS Installed,

    -- Devices missing updates
    uds.NumMissing AS Missing,

    -- Devices with failed installations
    uds.NumFailed AS Failed,

    -- Devices with unknown compliance state
    uds.NumUnknown AS Unknown,

    -- Devices where update is not applicable
    uds.NumNotApplicable AS NotApplicable

FROM v_UpdateDeploymentSummary uds

ORDER BY

    -- Latest deployments first
    uds.StartTime DESC;