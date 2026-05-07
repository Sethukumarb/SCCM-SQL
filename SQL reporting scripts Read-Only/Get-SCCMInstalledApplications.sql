/*
===============================================================================
Script Name : Get-SCCMInstalledApplications.sql
Author      : Sethu Kumar B
Purpose     : Retrieve installed application inventory from SCCM using
              Add/Remove Programs data.
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
-- TABLE 1: Installed Application Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    bios.SerialNumber0 AS SerialNumber,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0 AS Publisher,
    arp.Version0 AS ApplicationVersion,
    arp.InstallDate0 AS InstallDate

FROM v_R_System rs

LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = rs.ResourceID

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''

ORDER BY
    rs.Name0,
    arp.DisplayName0,
    arp.Version0;


-- ============================================================================
-- TABLE 2: Application Summary Count
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0 AS Publisher,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''

GROUP BY
    arp.DisplayName0,
    arp.Publisher0

ORDER BY
    DeviceCount DESC,
    ApplicationName;