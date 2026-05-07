/*
===============================================================================
Script Name : Get-SCCMWorkstationsBelowWindows11-24H2.sql
Author      : Sethu Kumar B
Purpose     : Identify Windows workstation devices running builds lower
              than Windows 11 24H2.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves only Windows workstation operating systems
- Excludes all Windows Server operating systems
- Identifies devices running below Windows 11 24H2
- Useful for upgrade tracking, compliance reporting,
  and unsupported OS identification

Logic:
- Windows 11 24H2 build number = 26100
- Any workstation build below 26100 is considered non-compliant

Excluded:
- Windows Server 2012
- Windows Server 2016
- Windows Server 2019
- Windows Server 2022
- Any Server OS

Main SCCM Views Used:
- v_R_System
- v_GS_OPERATING_SYSTEM

===============================================================================
*/

SELECT DISTINCT

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

    -- Devices below Windows 11 24H2
    AND TRY_CAST(os.BuildNumber0 AS INT) < 26100

-- Sort devices alphabetically
ORDER BY sys.Name0;