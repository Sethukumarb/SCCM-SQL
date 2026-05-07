/*
===============================================================================
Script Name : Get-SCCMDevicesWithoutDefender.sql
Author      : Sethu Kumar B
Purpose     : Identify Windows workstation devices where Microsoft Defender
              Antivirus is not visible in SCCM Add/Remove Programs inventory.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Devices Without Microsoft Defender Entry in Software Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    'Microsoft Defender Not Found in ARP Inventory' AS DefenderInventoryStatus

FROM v_R_System rs

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

    AND NOT EXISTS
    (
        SELECT 1
        FROM v_Add_Remove_Programs arp
        WHERE arp.ResourceID = rs.ResourceID
          AND
          (
              arp.DisplayName0 LIKE '%Microsoft Defender%'
              OR arp.DisplayName0 LIKE '%Windows Defender%'
          )
    )

ORDER BY
    rs.Name0;


-- ============================================================================
-- TABLE 2: Defender Inventory Summary
-- ============================================================================

SELECT
    DefenderInventoryStatus,
    COUNT(*) AS DeviceCount
FROM
(
    SELECT
        rs.ResourceID,

        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM v_Add_Remove_Programs arp
                WHERE arp.ResourceID = rs.ResourceID
                  AND
                  (
                      arp.DisplayName0 LIKE '%Microsoft Defender%'
                      OR arp.DisplayName0 LIKE '%Windows Defender%'
                  )
            )
                THEN 'Defender Found in ARP Inventory'
            ELSE 'Defender Not Found in ARP Inventory'
        END AS DefenderInventoryStatus

    FROM v_R_System rs

    WHERE
        rs.Operating_System_Name_and0 LIKE '%workstation%'

) AS DefenderSummary

GROUP BY
    DefenderInventoryStatus

ORDER BY
    DeviceCount DESC;