/*
===============================================================================
Script Name : Get-SCCMMSKSiteDomainJoinedDevices.sql
Author      : Sethu Kumar B

Purpose     :
This script retrieves all PCs and servers from the MSK site that are joined
to the Active Directory domain, based on SCCM device inventory.

The report includes:
    - Computer Name
    - Resource ID
    - Operating System
    - AD Site
    - AD Distinguished Name
    - Domain / Workgroup
    - Last Logged-On User
    - SCCM Client Status
    - Active / Inactive Status

Use Cases  :
    - MSK site device inventory
    - AD domain joined device validation
    - PC and server inventory reporting
    - SCCM asset tracking
    - Infrastructure audit

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/

DECLARE @ADSiteName NVARCHAR(100) = N'%MSK%';

-- ============================================================================
-- TABLE 1: MSK Site Domain Joined PCs and Servers
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.Operating_System_Name_and0 AS OperatingSystem,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Resource_Domain_OR_Workgr0 AS DomainOrWorkgroup,
    rs.User_Name0 AS LastLoggedOnUser,

    CASE rs.Client0
        WHEN 1 THEN 'Client Installed'
        WHEN 0 THEN 'Client Not Installed'
        ELSE 'Unknown'
    END AS SCCMClientStatus,

    CASE rs.Active0
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMActiveStatus

FROM v_R_System rs

WHERE
    -- Filter MSK AD site
    rs.AD_Site_Name0 LIKE @ADSiteName

    -- Include only AD domain joined devices
    AND ISNULL(rs.Resource_Domain_OR_Workgr0, '') <> ''

    -- Include both workstations and servers
    AND
    (
        rs.Operating_System_Name_and0 LIKE '%workstation%'
        OR rs.Operating_System_Name_and0 LIKE '%server%'
    )

ORDER BY
    rs.Operating_System_Name_and0,
    rs.Name0;
