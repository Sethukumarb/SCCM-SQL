/*
===============================================================================
Script Name : Get-SCCMIBMApplicationsFullInventoryReport.sql
Author      : Sethu Kumar B

Purpose:
This consolidated report provides a complete IBM software inventory from SCCM:

TABLE 1:
- Unique IBM Application Names with Publisher

TABLE 2:
- IBM Application Version Summary
- Active / Inactive device counts

TABLE 3:
- Full Device-Level IBM Inventory
- Hardware details, user info, site, and client activity status

===============================================================================
*/

-- ============================================================================
-- TABLE 1: Unique IBM Application Names
-- ============================================================================

SELECT DISTINCT
    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0   AS Publisher
FROM v_Add_Remove_Programs arp
WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND (
        arp.DisplayName0 LIKE '%IBM%'
        OR arp.Publisher0 LIKE '%IBM%'
    )
ORDER BY
    ApplicationName, Publisher;


-- ============================================================================
-- TABLE 2: IBM Application Version Summary (Active vs Inactive)
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Version0     AS ApplicationVersion,
    arp.Publisher0   AS Publisher,

    COUNT(DISTINCT rs.ResourceID) AS TotalDevices,

    COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 1 THEN rs.ResourceID END) AS ActiveDevices,

    COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 0 THEN rs.ResourceID END) AS InactiveDevices,

    CAST(
        100.0 * COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 1 THEN rs.ResourceID END)
        / NULLIF(COUNT(DISTINCT rs.ResourceID), 0)
        AS DECIMAL(5,1)
    ) AS ActivePercentage,

    CAST(
        100.0 * COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 0 THEN rs.ResourceID END)
        / NULLIF(COUNT(DISTINCT rs.ResourceID), 0)
        AS DECIMAL(5,1)
    ) AS InactivePercentage

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND (
        arp.DisplayName0 LIKE '%IBM%'
        OR arp.Publisher0 LIKE '%IBM%'
    )

GROUP BY
    arp.DisplayName0,
    arp.Version0,
    arp.Publisher0

ORDER BY
    ApplicationName, ApplicationVersion;


-- ============================================================================
-- TABLE 3: IBM FULL DEVICE LEVEL INVENTORY (NEW)
-- ============================================================================

SELECT DISTINCT
    -- =========================
    -- Device Details
    -- =========================
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS UserName,
    usr.User_Principal_Name0 AS EmailAddress,

    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    bios.SerialNumber0 AS SerialNumber,
    cs.Manufacturer0 AS Manufacturer,
    cs.Model0 AS PCModel,

    -- =========================
    -- Software Details
    -- =========================
    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,
    arp.Publisher0 AS Publisher,
    arp.InstallDate0 AS InstallDate,

    -- =========================
    -- Activity Details
    -- =========================
    ch.ClientActiveStatus,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMClientStatus,

    ch.LastDDR AS LastSCCMSyncTime,
    DATEDIFF(DAY, ch.LastDDR, GETDATE()) AS DaysSinceLastSync

FROM v_R_System rs

LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = rs.ResourceID

LEFT JOIN v_GS_COMPUTER_SYSTEM cs
    ON cs.ResourceID = rs.ResourceID

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

LEFT JOIN v_R_User usr
    ON usr.User_Name0 = rs.User_Name0

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND (
        arp.DisplayName0 LIKE '%IBM%'
        OR arp.Publisher0 LIKE '%IBM%'
    )

ORDER BY
    rs.Name0;
