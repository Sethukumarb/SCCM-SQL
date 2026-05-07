/*
===============================================================================
Script Name : Get-SCCMCitrixWorkspaceInventory-RegionalWorkstations.sql
Author      : Sethu Kumar B
Purpose     : Retrieve Citrix Workspace installation details from SCCM
              for Regional Workstation devices.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves Citrix Workspace software inventory from SCCM
- Displays:
    - Hostname
    - Software name
    - Software version
    - Manufacturer
    - Active Directory OU
    - Username
    - User email address

Use Cases:
- Citrix Workspace version audit
- Application compliance validation
- Software inventory reporting
- Targeted upgrade planning
- Endpoint application tracking

Main SCCM Views Used:
- v_R_System
- v_Add_Remove_Programs
- v_R_User

Important Notes:
- Query targets only workstation operating systems
- Filters devices located under Regional Workstation OU structure
- Currently filtered for:
    - Citrix Workspace 2402
    - Version 24.2.3001.9

===============================================================================
*/

SELECT DISTINCT

    -- Device hostname
    vrs.Name0 AS Hostname,

    -- Installed software name
    varp.DisplayName0 AS Software,

    -- Installed software version
    varp.Version0 AS Version,

    -- Software publisher/manufacturer
    varp.Publisher0 AS Manufacturer,

    -- Active Directory Organizational Unit
    vrs.Distinguished_Name0 AS OU,

    -- Primary username
    vru.DisplayName0 AS UserName,

    -- User email address
    vru.User_Principal_Name0 AS UserEmail

FROM v_R_System vrs

-- Join installed software inventory
JOIN v_Add_Remove_Programs varp
    ON varp.ResourceID = vrs.ResourceID

-- Join user information
JOIN v_R_User vru
    ON vru.User_Name0 = vrs.User_Name0

WHERE

    (
        -- Match Citrix Workspace software naming patterns
        varp.DisplayName0 LIKE '%Citrix Workspace 1%'
        OR varp.DisplayName0 LIKE '%Citrix Workspace 2%'
    )

    -- Filter Regional Workstation OU devices
    AND vrs.Distinguished_Name0 LIKE '%Regional%Workstation%'

    -- Include only workstation operating systems
    AND vrs.Operating_System_Name_and0 LIKE '%workstation%'

    -- Filter specific Citrix Workspace release
    AND varp.DisplayName0 LIKE 'Citrix Workspace 2402'

    -- Filter specific software version
    AND varp.Version0 LIKE '24.2.3001.9';