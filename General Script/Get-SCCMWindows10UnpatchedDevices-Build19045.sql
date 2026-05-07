/*
===============================================================================
Script Name : Get-SCCMWindows10UnpatchedDevices-Build19045.sql
Author      : Sethu Kumar B
Purpose     : Identify Windows 10 22H2 devices running below the required
              patched build version.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves Windows 10 22H2 devices from SCCM
- Identifies systems running below the required patched OS version
- Useful for vulnerability validation, patch compliance reporting,
  and security remediation tracking

Target OS:
- Windows 10 22H2
- Build Number : 19045

Patched Version Threshold:
- 10.0.19045.6093

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

    -- Filter only Windows 10 22H2 devices
    os.BuildNumber0 = '19045'

    AND (

        -- Include devices with missing version data
        os.Version0 IS NULL

        -- Include devices below required patched build
        OR os.Version0 < '10.0.19045.6093'
    )

-- Sort devices alphabetically
ORDER BY sys.Name0;