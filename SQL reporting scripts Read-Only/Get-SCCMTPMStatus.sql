/*
===============================================================================
Script Name : Get-SCCMTPMStatus.sql
Author      : Sethu Kumar B
Purpose     : Retrieve TPM status details for Windows workstation devices
              from SCCM hardware inventory.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level TPM Status
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    tpm.SpecVersion0 AS TPMSpecVersion,
    tpm.IsEnabled_InitialValue0 AS TPMEnabled,
    tpm.IsActivated_InitialValue0 AS TPMActivated,
    tpm.IsOwned_InitialValue0 AS TPMOwned,

    CASE tpm.IsEnabled_InitialValue0
        WHEN 1 THEN 'Enabled'
        WHEN 0 THEN 'Disabled'
        ELSE 'Unknown'
    END AS TPMEnabledStatus,

    CASE tpm.IsActivated_InitialValue0
        WHEN 1 THEN 'Activated'
        WHEN 0 THEN 'Not Activated'
        ELSE 'Unknown'
    END AS TPMActivatedStatus,

    CASE tpm.IsOwned_InitialValue0
        WHEN 1 THEN 'Owned'
        WHEN 0 THEN 'Not Owned'
        ELSE 'Unknown'
    END AS TPMOwnedStatus

FROM v_R_System rs

LEFT JOIN v_GS_TPM tpm
    ON tpm.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    TPMEnabledStatus,
    TPMActivatedStatus,
    rs.Name0;


-- ============================================================================
-- TABLE 2: TPM Status Summary
-- ============================================================================

SELECT
    CASE tpm.IsEnabled_InitialValue0
        WHEN 1 THEN 'Enabled'
        WHEN 0 THEN 'Disabled'
        ELSE 'Unknown'
    END AS TPMEnabledStatus,

    CASE tpm.IsActivated_InitialValue0
        WHEN 1 THEN 'Activated'
        WHEN 0 THEN 'Not Activated'
        ELSE 'Unknown'
    END AS TPMActivatedStatus,

    CASE tpm.IsOwned_InitialValue0
        WHEN 1 THEN 'Owned'
        WHEN 0 THEN 'Not Owned'
        ELSE 'Unknown'
    END AS TPMOwnedStatus,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

LEFT JOIN v_GS_TPM tpm
    ON tpm.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

GROUP BY
    tpm.IsEnabled_InitialValue0,
    tpm.IsActivated_InitialValue0,
    tpm.IsOwned_InitialValue0

ORDER BY
    DeviceCount DESC;