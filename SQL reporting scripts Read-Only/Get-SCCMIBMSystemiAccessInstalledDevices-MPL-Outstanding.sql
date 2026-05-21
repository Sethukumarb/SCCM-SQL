/*
===============================================================================
Script Name : Get-SCCMIBMSystemiAccessInstalledDevices-MPL-Outstanding.sql
Author      : Sethu Kumar B

Purpose:
Extract MPL workstation devices where IBM System i Access / IBM iSeries related
application is still installed.

This report helps identify outstanding MPL devices before proceeding with Batch 3.
===============================================================================
*/

DECLARE @TargetSite NVARCHAR(50) = 'MPL';

-- ============================================================================
-- TABLE 1: MPL Outstanding Device-Level Report
-- ============================================================================

SELECT DISTINCT
    rs.Name0 AS ComputerName,
    rs.ResourceID,

    bios.SerialNumber0 AS SerialNumber,

    rs.User_Name0 AS UserName,
    usr.User_Principal_Name0 AS EmailAddress,

    cs.Manufacturer0 AS Manufacturer,
    cs.Model0 AS PCModel,

    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,
    arp.Publisher0 AS Publisher,
    arp.InstallDate0 AS InstallDate,

    ch.LastDDR AS LastSCCMSyncTime,
    DATEDIFF(DAY, ch.LastDDR, GETDATE()) AS DaysSinceLastSync,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMClientStatus

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
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.DisplayName0 LIKE '%IBM%System%i%Access%'
    AND rs.AD_Site_Name0 LIKE '%' + @TargetSite + '%'

ORDER BY
    rs.Name0 ASC;


-- ============================================================================
-- TABLE 2: MPL Active vs Inactive Summary by Application Version
-- ============================================================================

SELECT
    rs.AD_Site_Name0 AS ADSite,
    arp.DisplayName0 AS ApplicationName,
    arp.Version0 AS ApplicationVersion,

    COUNT(DISTINCT rs.ResourceID) AS TotalDevices,

    COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 1 THEN rs.ResourceID END) AS ActiveDevices,

    COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 0 THEN rs.ResourceID END) AS InactiveDevices,

    COUNT(DISTINCT CASE 
        WHEN ch.ClientActiveStatus IS NULL THEN rs.ResourceID 
    END) AS UnknownStatusDevices,

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

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.DisplayName0 LIKE '%IBM%System%i%Access%'
    AND rs.AD_Site_Name0 LIKE '%' + @TargetSite + '%'

GROUP BY
    rs.AD_Site_Name0,
    arp.DisplayName0,
    arp.Version0

ORDER BY
    rs.AD_Site_Name0,
    arp.Version0 ASC;
