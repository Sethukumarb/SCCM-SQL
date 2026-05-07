/*
===============================================================================
Script Name : Get-SCCMInstalledApplicationsByDevice.sql
Author      : Sethu Kumar B
Purpose     : Retrieve installed applications from SCCM inventory
              for specific devices using Add/Remove Programs data.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves installed software inventory from SCCM
- Displays:
    - Device name
    - Serial number
    - Last logged-on user
    - AD site
    - AD distinguished name
    - Operating system
    - Application name
    - Publisher
    - Application version
    - Install date

Use Cases:
- Software inventory audit
- Application compliance validation
- Device software troubleshooting
- Security software verification
- Asset management reporting
- License validation

Main SCCM Views Used:
- v_R_System
- v_GS_OPERATING_SYSTEM
- v_GS_PC_BIOS
- v_Add_Remove_Programs

Important Notes:
- Uses Add/Remove Programs inventory only
- Compatible with SCCM 2012 SP2 and newer
- Filters empty application names
- Includes optional filters for:
    - Specific applications
    - Specific publishers

===============================================================================
*/

SELECT

    -- Device hostname
    rs.Name0 AS DeviceName,

    -- Device serial number
    cs.SerialNumber0 AS SerialNumber,

    -- Last logged-on user
    rs.User_Name0 AS LastLoggedOnUser,

    -- Active Directory site
    rs.AD_Site_Name0 AS ADSite,

    -- Active Directory Distinguished Name
    rs.Distinguished_Name0 AS ADDistinguishedName,

    -- Operating system name
    os.Caption0 AS OperatingSystem,

    -- Installed application name
    arp.DisplayName0 AS AppName,

    -- Application publisher
    arp.Publisher0 AS Publisher,

    -- Installed application version
    arp.Version0 AS AppVersion,

    -- Application install date
    arp.InstallDate0 AS InstallDate

FROM v_R_System rs

-- Join operating system inventory
LEFT JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = rs.ResourceID

-- Join BIOS / serial number inventory
LEFT JOIN v_GS_PC_BIOS cs
    ON cs.ResourceID = rs.ResourceID

-- Join installed applications inventory
INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE

    -- Exclude empty application names
    ISNULL(arp.DisplayName0, '') <> ''

    -- Filter specific devices
    AND rs.Name0 IN
    (
        'WDAP-a27dFKILEQ',
        'WDAP-im7nawng2i',
        '68M21J3'
    )

/*
===============================================================================
OPTIONAL FILTERS
Uncomment as needed
===============================================================================

-- Filter applications containing "Tanium"
AND arp.DisplayName0 LIKE '%Tanium%'

-- Filter Microsoft published applications
AND arp.Publisher0 LIKE '%Microsoft%'

*/

ORDER BY

    -- Sort by device, application, and version
    DeviceName,
    AppName,
    AppVersion;