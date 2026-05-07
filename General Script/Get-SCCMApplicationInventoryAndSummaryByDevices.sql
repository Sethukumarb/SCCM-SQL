/*
===============================================================================
Script Name : Get-SCCMApplicationInventoryAndSummaryByDevices.sql
Author      : Sethu Kumar B
Purpose     : Retrieve installed application inventory and consolidated
              application summary for specific SCCM devices.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves installed applications for selected devices
- Generates:
    1. Device-level application inventory
    2. Consolidated application summary across devices

Outputs:
- TABLE 1:
    Detailed device-level application inventory

- TABLE 2:
    Consolidated application count grouped by application name
    and publisher

Use Cases:
- Application inventory audit
- Software compliance validation
- Device software comparison
- License tracking
- Security software verification
- SCCM asset management reporting

Main SCCM Views Used:
- v_R_System
- v_Add_Remove_Programs

Important Notes:
- Uses temporary table for reusable filtered device list
- Consolidates application counts across multiple versions
- Counts unique devices per application

===============================================================================
*/


-- ============================================================================
-- STEP 1
-- Store Filtered Devices
-- ============================================================================

IF OBJECT_ID('tempdb..#FilteredDevices') IS NOT NULL
    DROP TABLE #FilteredDevices;

SELECT

    -- SCCM Resource ID
    ResourceID,

    -- Device hostname
    Name0

INTO #FilteredDevices

FROM v_R_System

WHERE Name0 IN
(
    'WDAP-a27dFKILEQ',
    'WDAP-im7nawng2i',
    '7WD7G33',
    'GGR1W23'
);


-- ============================================================================
-- STEP 2
-- Device-Level Application Inventory
-- ============================================================================

SELECT

    -- Device hostname
    fd.Name0 AS DeviceName,

    -- Installed application name
    arp.DisplayName0 AS AppName,

    -- Application publisher
    arp.Publisher0 AS Publisher,

    -- Installed application version
    arp.Version0 AS AppVersion,

    -- Application install date
    arp.InstallDate0 AS InstallDate

FROM #FilteredDevices fd

-- Join installed application inventory
INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = fd.ResourceID

WHERE

    -- Exclude empty application names
    ISNULL(arp.DisplayName0, '') <> ''

ORDER BY

    -- Sort by device and application
    fd.Name0,
    arp.DisplayName0,
    arp.Version0;


-- ============================================================================
-- STEP 3
-- Consolidated Application Summary
-- ============================================================================

SELECT

    -- Installed application name
    arp.DisplayName0 AS AppName,

    -- Application publisher
    arp.Publisher0 AS Publisher,

    -- Count of unique devices with application installed
    COUNT(DISTINCT fd.ResourceID) AS DeviceCount

FROM #FilteredDevices fd

-- Join installed application inventory
INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = fd.ResourceID

WHERE

    -- Exclude empty application names
    ISNULL(arp.DisplayName0, '') <> ''

GROUP BY

    -- Group by application and publisher
    arp.DisplayName0,
    arp.Publisher0

ORDER BY

    -- Highest device count first
    DeviceCount DESC,

    -- Then sort alphabetically
    AppName;


-- ============================================================================
-- STEP 4
-- Cleanup Temporary Table
-- ============================================================================

DROP TABLE #FilteredDevices;