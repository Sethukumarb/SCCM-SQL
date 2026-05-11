/*
===============================================================================
Script Name : Get-SCCMIBMSystemiAccessInstalledDevices-WithUserDetails.sql
Author      : Sethu Kumar B

Purpose     :
This script identifies Windows workstation devices where the following
legacy IBM application is installed:

    - IBM System i Access For Windows V6R1M0

The report helps support:
    - IBM iSeries migration projects
    - Legacy IBM application cleanup
    - Migration completion tracking
    - Device remediation planning

The script generates:
    1. Device-level installation report
    2. Application summary report

Additional Details Included:
    - Device Serial Number
    - Username
    - Email Address
    - PC Model
    - Last SCCM Heartbeat Sync Time
    - SCCM Active / Inactive Status
    - Operating System

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level IBM System i Access Installation Report
-- ============================================================================

SELECT DISTINCT
    rs.Name0 AS ComputerName,
    rs.ResourceID,

    bios.SerialNumber0 AS SerialNumber,

    rs.User_Name0 AS UserName,
    usr.User_Principal_Name0 AS EmailAddress,

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
    -- Windows workstation devices only
    rs.Operating_System_Name_and0 LIKE '%workstation%'

    -- Target application only
    AND arp.DisplayName0 = 'IBM System i Access For Windows V6R1M0'

ORDER BY
    ComputerName ASC;


-- ============================================================================
-- TABLE 2: IBM System i Access Summary
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount,

    SUM
    (
        CASE
            WHEN ch.ClientActiveStatus = 1 THEN 1
            ELSE 0
        END
    ) AS ActiveDevices,

    SUM
    (
        CASE
            WHEN ch.ClientActiveStatus = 0 THEN 1
            ELSE 0
        END
    ) AS InactiveDevices,

    CAST
    (
        100.0 *
        SUM
        (
            CASE
                WHEN ch.ClientActiveStatus = 1 THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(COUNT(DISTINCT rs.ResourceID), 0)
        AS DECIMAL(5,1)
    ) AS ActivePercentage

FROM v_R_System rs

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    -- Windows workstation devices only
    rs.Operating_System_Name_and0 LIKE '%workstation%'

    -- Target application only
    AND arp.DisplayName0 = 'IBM System i Access For Windows V6R1M0'

GROUP BY
    arp.DisplayName0

ORDER BY
    ApplicationName ASC;
