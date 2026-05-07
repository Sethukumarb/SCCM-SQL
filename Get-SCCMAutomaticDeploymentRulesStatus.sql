/*
===============================================================================
Script Name : Get-SCCMAutomaticDeploymentRulesStatus.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM Automatic Deployment Rule (ADR) status,
              execution details, and associated deployment information.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all SCCM Automatic Deployment Rules (ADR)
- Displays:
    - ADR ID
    - ADR Name
    - Enabled status
    - Last run time
    - Last error code
    - Last error time
    - Associated Software Update Group ID
    - Associated Deployment ID

Use Cases:
- ADR health monitoring
- Patch automation validation
- Troubleshooting failed ADR executions
- Monthly patch deployment verification
- SCCM Software Update automation audit

Main SCCM Views Used:
- vSMS_AutoDeployments

Important Notes:
- AutoDeploymentEnabled:
    1 = Enabled
    0 = Disabled

- LastErrorCode:
    0 or NULL usually indicates successful execution

- AssociatedUpdateGroupID:
    Links ADR to generated Software Update Group (SUG)

===============================================================================
*/

SELECT

    -- SCCM Automatic Deployment Rule ID
    adr.AutoDeploymentID,

    -- ADR name
    adr.Name AS ADRName,

    -- ADR enabled status
    -- 1 = Enabled
    -- 0 = Disabled
    adr.AutoDeploymentEnabled AS IsEnabled,

    -- Last successful or attempted ADR run time
    adr.LastRunTime,

    -- Last ADR execution error code
    adr.LastErrorCode,

    -- Time last error occurred
    adr.LastErrorTime,

    -- Associated Software Update Group ID
    adr.AssociatedUpdateGroupID,

    -- Associated deployment ID
    adr.AssociatedDeploymentID

FROM vSMS_AutoDeployments adr

ORDER BY

    -- Sort ADRs alphabetically
    adr.Name;