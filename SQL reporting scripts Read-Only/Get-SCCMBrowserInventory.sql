/*
===============================================================================
Script Name : Get-SCCMBrowserInventory.sql
Author      : Sethu Kumar B
Purpose     : Retrieve installed browser inventory from SCCM Add/Remove
              Programs data.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level Browser Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    arp.DisplayName0 AS BrowserName,
    arp.Publisher0 AS Publisher,
    arp.Version0 AS BrowserVersion,
    arp.InstallDate0 AS InstallDate

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND
    (
        arp.DisplayName0 LIKE '%Google Chrome%'
        OR arp.DisplayName0 LIKE '%Microsoft Edge%'
        OR arp.DisplayName0 LIKE '%Mozilla Firefox%'
        OR arp.DisplayName0 LIKE '%Brave%'
        OR arp.DisplayName0 LIKE '%Opera%'
    )

ORDER BY
    rs.Name0,
    arp.DisplayName0,
    arp.Version0;


-- ============================================================================
-- TABLE 2: Browser Version Summary
-- ============================================================================

SELECT
    arp.DisplayName0 AS BrowserName,
    arp.Publisher0 AS Publisher,
    arp.Version0 AS BrowserVersion,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND
    (
        arp.DisplayName0 LIKE '%Google Chrome%'
        OR arp.DisplayName0 LIKE '%Microsoft Edge%'
        OR arp.DisplayName0 LIKE '%Mozilla Firefox%'
        OR arp.DisplayName0 LIKE '%Brave%'
        OR arp.DisplayName0 LIKE '%Opera%'
    )

GROUP BY
    arp.DisplayName0,
    arp.Publisher0,
    arp.Version0

ORDER BY
    BrowserName,
    DeviceCount DESC;