/*
===============================================================================
Script Name : Get-SCCMBitLockerProtectionStatus.sql
Author      : Sethu Kumar B
Purpose     : Retrieve BitLocker protection status for Windows workstation
              devices from SCCM hardware inventory.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level BitLocker Protection Status
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    enc.DriveLetter0 AS DriveLetter,
    enc.ProtectionStatus0 AS ProtectionStatusCode,

    CASE enc.ProtectionStatus0
        WHEN 1 THEN 'Protected'
        WHEN 0 THEN 'Unprotected'
        ELSE 'Unknown'
    END AS ProtectionStatus

FROM v_R_System rs

LEFT JOIN v_GS_ENCRYPTABLE_VOLUME enc
    ON enc.ResourceID = rs.ResourceID
   AND enc.DriveLetter0 = 'C:'

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    ProtectionStatus,
    rs.Name0;


-- ============================================================================
-- TABLE 2: BitLocker Protection Status Summary
-- ============================================================================

SELECT
    CASE enc.ProtectionStatus0
        WHEN 1 THEN 'Protected'
        WHEN 0 THEN 'Unprotected'
        ELSE 'Unknown'
    END AS ProtectionStatus,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

LEFT JOIN v_GS_ENCRYPTABLE_VOLUME enc
    ON enc.ResourceID = rs.ResourceID
   AND enc.DriveLetter0 = 'C:'

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

GROUP BY
    enc.ProtectionStatus0

ORDER BY
    DeviceCount DESC;