/*
===============================================================================
Script Name : Get-SCCMDevicesMissingHardwareInventory-WithSerialNumber.sql
Author      : Sethu Kumar B

Purpose     :
This script identifies SCCM workstation devices that have missing or old
hardware inventory data.

The report categorizes devices based on the last hardware inventory date:
    - Hardware Inventory Missing
    - Hardware Inventory Older Than 30 Days
    - Hardware Inventory Current

The script generates:
    1. Device-level hardware inventory status report
    2. Summary count with percentage for each inventory status

Additional Details Included:
    - Device Serial Number
    - Last Logged-On User
    - Operating System
    - SCCM Last Hardware Inventory Timestamp

Use Cases  :
    - SCCM hardware inventory health validation
    - Identify devices not reporting inventory
    - Troubleshoot SCCM client inventory issues
    - Support compliance and asset reporting
    - SCCM cleanup and remediation planning

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/

DECLARE @HardwareInventoryDays INT = 30;

-- ============================================================================
-- TABLE 1: Device-Level Hardware Inventory Status
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID,

    bios.SerialNumber0 AS SerialNumber,

    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    ch.LastHW AS LastHardwareInventory,

    DATEDIFF(DAY, ch.LastHW, GETDATE()) AS DaysSinceLastHardwareInventory,

    CASE
        WHEN ch.LastHW IS NULL THEN 'Hardware Inventory Missing'
        WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareInventoryDays
            THEN 'Hardware Inventory Older Than 30 Days'
        ELSE 'Hardware Inventory Current'
    END AS HardwareInventoryStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    HardwareInventoryStatus,
    ch.LastHW,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Hardware Inventory Status Summary with Percentage
-- ============================================================================

SELECT
    HardwareInventoryStatus,

    COUNT(*) AS DeviceCount,

    CAST
    (
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,1)
    ) AS Percentage

FROM
(
    SELECT
        CASE
            WHEN ch.LastHW IS NULL THEN 'Hardware Inventory Missing'
            WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareInventoryDays
                THEN 'Hardware Inventory Older Than 30 Days'
            ELSE 'Hardware Inventory Current'
        END AS HardwareInventoryStatus

    FROM v_CH_ClientSummary ch

    LEFT JOIN v_R_System rs
        ON rs.ResourceID = ch.ResourceID

    WHERE
        rs.Operating_System_Name_and0 LIKE '%workstation%'

) AS HardwareInventorySummary

GROUP BY
    HardwareInventoryStatus

ORDER BY
    DeviceCount DESC;
