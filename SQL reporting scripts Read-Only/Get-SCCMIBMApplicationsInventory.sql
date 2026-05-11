/*
===============================================================================
Script Name : Get-SCCMIBMApplicationsInventory.sql
Author      : Sethu Kumar B

Purpose     :
This script retrieves all IBM-related applications detected in SCCM
Add/Remove Programs inventory across Windows workstation devices.

The report helps identify:
    - IBM applications currently installed in the environment
    - Exact application names
    - Versions installed
    - Device counts per application

This script is useful before creating targeted cleanup or migration
reports for specific IBM applications such as:
    - IBM iSeries
    - IBM Client Access
    - IBM Personal Communications
    - IBM Access Client Solutions (ACS)
    - IBM MQ
    - Other IBM software

The script generates:
    1. IBM application inventory summary
    2. Device count for each IBM application/version

Use Cases  :
    - IBM software discovery
    - IBM migration planning
    - IBM software cleanup projects
    - Application inventory validation
    - Identify exact application naming in SCCM

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/

-- ============================================================================
-- TABLE 1: IBM Application Inventory Summary
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0 AS Publisher,
    arp.Version0 AS ApplicationVersion,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    -- Windows workstation devices only
    rs.Operating_System_Name_and0 LIKE '%workstation%'

    -- Exclude empty application names
    AND ISNULL(arp.DisplayName0, '') <> ''

    -- IBM application filter
    AND
    (
        arp.DisplayName0 LIKE '%IBM%'
        OR arp.Publisher0 LIKE '%IBM%'
    )

GROUP BY
    arp.DisplayName0,
    arp.Publisher0,
    arp.Version0

ORDER BY
    ApplicationName ASC,
    ApplicationVersion ASC,
    DeviceCount DESC;
