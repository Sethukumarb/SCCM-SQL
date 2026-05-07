/*
===============================================================================
Script Name : Get-SCCMWindowsBuildInventoryAndSummary.sql
Author      : Sethu Kumar B
Purpose     : Retrieve Windows workstation inventory details along with
              summarized device count per OS build number.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all Windows workstation devices from SCCM
- Excludes Windows Server operating systems
- First result set:
    Detailed device inventory
- Second result set:
    Build number summary with total device counts

Use Cases:
- Windows OS inventory reporting
- Build/version distribution analysis
- Patch compliance tracking
- Upgrade readiness review

Main SCCM Views Used:
- v_R_System
- v_GS_OPERATING_SYSTEM

===============================================================================
*/

-- ============================================================================
-- TABLE 1
-- Detailed Windows Workstation Inventory
-- ============================================================================

SELECT

    -- Device hostname
    sys.Name0 AS ComputerName,

    -- Operating system name
    os.Caption0 AS OSCaption,

    -- Full OS version
    os.Version0 AS FullVersion,

    -- Windows build number
    os.BuildNumber0 AS BuildNumber

FROM v_R_System sys

-- Join operating system inventory data
JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = sys.ResourceID

WHERE

    -- Include only Windows workstation operating systems
    os.Caption0 LIKE '%Windows%'

    -- Exclude Windows Server operating systems
    AND os.Caption0 NOT LIKE '%Server%'

ORDER BY

    -- Highest build first
    TRY_CAST(os.BuildNumber0 AS INT) DESC,

    -- Sort devices alphabetically
    sys.Name0;


-- ============================================================================
-- TABLE 2
-- Windows Build Summary Count
-- ============================================================================

SELECT

    -- Operating system name
    os.Caption0 AS OSCaption,

    -- Windows build number
    os.BuildNumber0 AS BuildNumber,

    -- Total devices per build
    COUNT(*) AS DeviceCount

FROM v_R_System sys

-- Join operating system inventory data
JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = sys.ResourceID

WHERE

    -- Include only Windows workstation operating systems
    os.Caption0 LIKE '%Windows%'

    -- Exclude Windows Server operating systems
    AND os.Caption0 NOT LIKE '%Server%'

GROUP BY

    os.Caption0,
    os.BuildNumber0

ORDER BY

    -- Highest build first
    TRY_CAST(os.BuildNumber0 AS INT) DESC;