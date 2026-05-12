/*
===============================================================================
Script Name : Get-SCCMIBMWebSphereMQInventory-ActiveInactiveSummary.sql
Author      : Sethu Kumar B

Purpose     :
This script identifies devices where IBM WebSphere MQ is installed and provides
device-level inventory plus version-based Active vs Inactive summary with
percentage.

Type        :
Read-Only SQL Report
===============================================================================
*/

DECLARE @ApplicationName NVARCHAR(200) = N'%IBM WebSphere MQ%';


-- ============================================================================
-- TABLE 1: Device-Level IBM WebSphere MQ Inventory
-- ============================================================================

SELECT DISTINCT
    rs.Name0 AS ComputerName,
    bios.SerialNumber0 AS SerialNumber,
    rs.User_Name0 AS LastLoggedOnUser,
    usr.User_Principal_Name0 AS EmailAddress,

    cs.Manufacturer0 AS Manufacturer,
    cs.Model0 AS Model,

    rs.Operating_System_Name_and0 AS OperatingSystem,

    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,
    arp.Publisher0 AS Publisher,

    ch.LastDDR AS LastSCCMSyncTime,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMClientStatus,

    CASE
        WHEN cs.Model0 LIKE '%Virtual%'
          OR cs.Model0 LIKE '%VMware%'
          OR cs.Model0 LIKE '%Hyper-V%'
          OR cs.Manufacturer0 LIKE '%VMware%'
          OR cs.Manufacturer0 LIKE '%Microsoft Corporation%'
            THEN 'Virtual Machine'
        ELSE 'Physical Workstation'
    END AS DeviceType

FROM v_R_System rs

LEFT JOIN v_GS_COMPUTER_SYSTEM cs
    ON cs.ResourceID = rs.ResourceID

LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = rs.ResourceID

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

LEFT JOIN v_R_User usr
    ON usr.User_Name0 = rs.User_Name0

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.DisplayName0 LIKE @ApplicationName

ORDER BY
    arp.DisplayName0,
    arp.Version0,
    rs.Name0;


-- ============================================================================
-- TABLE 2: IBM WebSphere MQ Version Summary
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,
    arp.Publisher0 AS Publisher,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.DisplayName0 LIKE @ApplicationName

GROUP BY
    arp.DisplayName0,
    arp.Version0,
    arp.Publisher0

ORDER BY
    arp.DisplayName0,
    arp.Version0;


-- ============================================================================
-- TABLE 3: Active vs Inactive Summary by Application Version with Percentage
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMClientStatus,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount,

    CAST(
        100.0 * COUNT(DISTINCT rs.ResourceID)
        / NULLIF(
            SUM(COUNT(DISTINCT rs.ResourceID)) OVER
            (
                PARTITION BY arp.DisplayName0, arp.Version0
            ),
            0
        )
        AS DECIMAL(5,1)
    ) AS PercentageByVersion

FROM v_R_System rs

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.DisplayName0 LIKE @ApplicationName

GROUP BY
    arp.DisplayName0,
    arp.Version0,
    ch.ClientActiveStatus

ORDER BY
    arp.DisplayName0,
    arp.Version0,
    SCCMClientStatus;
