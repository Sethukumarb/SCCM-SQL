/*
===============================================================================
Script Name : Get-SCCMCoManagedDevices.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM co-managed device inventory details.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Co-Managed Device Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,
    rs.Client0 AS SCCMClientInstalled,
    rs.Active0 AS SCCMActiveStatus,

    CASE rs.Client0
        WHEN 1 THEN 'SCCM Client Installed'
        WHEN 0 THEN 'SCCM Client Not Installed'
        ELSE 'Unknown'
    END AS SCCMClientStatus,

    CASE rs.Active0
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMDeviceStatus,

    CASE
        WHEN rs.Client0 = 1
         AND rs.Operating_System_Name_and0 LIKE '%workstation%'
            THEN 'Potential Co-Managed Candidate'
        ELSE 'Review Required'
    END AS CoManagementReviewStatus

FROM v_R_System rs

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    rs.Name0;


-- ============================================================================
-- TABLE 2: Co-Management Candidate Summary
-- ============================================================================

SELECT
    CASE
        WHEN rs.Client0 = 1
         AND rs.Operating_System_Name_and0 LIKE '%workstation%'
            THEN 'Potential Co-Managed Candidate'
        ELSE 'Review Required'
    END AS CoManagementReviewStatus,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

GROUP BY
    CASE
        WHEN rs.Client0 = 1
         AND rs.Operating_System_Name_and0 LIKE '%workstation%'
            THEN 'Potential Co-Managed Candidate'
        ELSE 'Review Required'
    END

ORDER BY
    DeviceCount DESC;