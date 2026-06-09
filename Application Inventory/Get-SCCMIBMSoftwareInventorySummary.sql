/*
===============================================================================
Script Name : Get-SCCMIBMSoftwareInventorySummary.sql
Author      : Sethu Kumar B

Purpose     :
This script retrieves IBM application inventory from SCCM and provides:
- Unique IBM application list with publisher
- Version-level IBM software deployment summary with device activity status

Output:
Table 1: IBM Application Names + Publisher
Table 2: IBM Application Version Summary with Active/Inactive device counts

===============================================================================
*/

-- =====================================================================
-- TABLE 1: Unique IBM Application Names with Publisher
-- =====================================================================

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
    ApplicationName ASC,
    Publisher ASC;


-- =====================================================================
-- TABLE 2: IBM Applications by Version with Active/Inactive Summary
-- =====================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Version0     AS ApplicationVersion,
    arp.Publisher0   AS Publisher,

    -- Total devices where application is installed
    COUNT(DISTINCT rs.ResourceID) AS TotalDevices,

    -- Active SCCM clients
    COUNT(DISTINCT CASE 
        WHEN ch.ClientActiveStatus = 1 
        THEN rs.ResourceID 
    END) AS ActiveDevices,

    -- Inactive SCCM clients
    COUNT(DISTINCT CASE 
        WHEN ch.ClientActiveStatus = 0 
        THEN rs.ResourceID 
    END) AS InactiveDevices,

    -- Active percentage calculation
    CAST(
        100.0 *
        COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 1 THEN rs.ResourceID END)
        / NULLIF(COUNT(DISTINCT rs.ResourceID), 0)
        AS DECIMAL(5,1)
    ) AS ActivePercentage,

    -- Inactive percentage calculation
    CAST(
        100.0 *
        COUNT(DISTINCT CASE WHEN ch.ClientActiveStatus = 0 THEN rs.ResourceID END)
        / NULLIF(COUNT(DISTINCT rs.ResourceID), 0)
        AS DECIMAL(5,1)
    ) AS InactivePercentage

FROM v_Add_Remove_Programs arp

INNER JOIN v_R_System rs
    ON rs.ResourceID = arp.ResourceID

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
    arp.DisplayName0 ASC,
    arp.Version0 ASC;
