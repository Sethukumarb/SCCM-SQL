/*
===============================================================================
Script Name : Get-SCCMUniqueApplicationInventoryWithUserDetails.sql
Author      : Sethu Kumar B
Purpose     : Retrieve unique installed applications from selected SCCM
              devices along with hostname, serial number, and user email.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves installed applications from selected SCCM devices
- Removes duplicate application entries per device
- Displays:
    - Hostname
    - Serial Number
    - User Email
    - Application Name
    - Publisher
    - Device Count

Use Cases:
- Software inventory audit
- License tracking
- User-to-device application mapping
- Application compliance reporting
- SCCM asset management

Main SCCM Views Used:
- v_R_System
- v_Add_Remove_Programs
- v_GS_PC_BIOS
- v_R_User

Important Notes:
- Duplicate applications per device are removed
- Counts unique devices per application
- Useful for user/application ownership analysis

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
    rs.ResourceID,

    -- Device hostname
    rs.Name0,

    -- Last logged-on username
    rs.User_Name0

INTO #FilteredDevices

FROM v_R_System rs

WHERE rs.Name0 IN
(
    'WDAP-a27dFKILEQ',
    'WDAP-im7nawng2i',
    '7WD7G33',
    '68M21J3'
);


-- ============================================================================
-- STEP 2
-- Remove Duplicate Application Entries Per Device
-- ============================================================================

IF OBJECT_ID('tempdb..#UniqueApps') IS NOT NULL
    DROP TABLE #UniqueApps;

SELECT DISTINCT

    -- SCCM Resource ID
    fd.ResourceID,

    -- Device hostname
    fd.Name0 AS Hostname,

    -- Installed application name
    arp.DisplayName0 AS AppName,

    -- Application publisher
    arp.Publisher0 AS Publisher,

    -- Device serial number
    bios.SerialNumber0 AS SerialNumber,

    -- User email address
    usr.User_Principal_Name0 AS UserEmail

INTO #UniqueApps

FROM #FilteredDevices fd

-- Join installed application inventory
INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = fd.ResourceID

-- Join BIOS inventory for serial number
LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = fd.ResourceID

-- Join SCCM user inventory
LEFT JOIN v_R_User usr
    ON usr.User_Name0 = fd.User_Name0

WHERE

    -- Exclude empty application names
    ISNULL(arp.DisplayName0, '') <> '';


-- ============================================================================
-- STEP 3
-- Final Consolidated Report
-- ============================================================================

SELECT

    -- Device hostname
    Hostname,

    -- Device serial number
    SerialNumber,

    -- User email address
    UserEmail,

    -- Installed application name
    AppName,

    -- Application publisher
    Publisher,

    -- Count of unique devices per application
    COUNT(ResourceID) AS DeviceCount

FROM #UniqueApps

GROUP BY

    Hostname,
    SerialNumber,
    UserEmail,
    AppName,
    Publisher

ORDER BY

    -- Sort by hostname and application
    Hostname,
    AppName;


-- ============================================================================
-- STEP 4
-- Cleanup Temporary Tables
-- ============================================================================

DROP TABLE #UniqueApps;

DROP TABLE #FilteredDevices;