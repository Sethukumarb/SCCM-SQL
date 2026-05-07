/*
===============================================================================
Script Name : Get-SCCMDuplicateDevices.sql
Author      : Sethu Kumar B
Purpose     : Identify duplicate SCCM device records based on hostname.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- IMPORTANT
-- Change database context to SCCM Site Database
-- Example: CM_ABC
-- ============================================================================

-- USE CM_ABC;
-- GO


-- ============================================================================
-- TABLE 1: Duplicate Device Summary
-- ============================================================================

SELECT

    -- Device hostname
    rs.Name0 AS ComputerName,

    -- Number of duplicate records
    COUNT(*) AS DuplicateRecordCount

FROM dbo.v_R_System rs

WHERE rs.Name0 IS NOT NULL

GROUP BY
    rs.Name0

HAVING COUNT(*) > 1

ORDER BY
    DuplicateRecordCount DESC,
    ComputerName;


-- ============================================================================
-- TABLE 2: Duplicate Device Detailed Information
-- ============================================================================

SELECT

    -- Device hostname
    rs.Name0 AS ComputerName,

    -- SCCM Resource ID
    rs.ResourceID,

    -- SCCM client installed status
    rs.Client0 AS ClientInstalled,

    -- Active status
    rs.Active0 AS ActiveStatus,

    -- Last logged-on user
    rs.User_Name0 AS LastLoggedOnUser,

    -- Active Directory site
    rs.AD_Site_Name0 AS ADSite,

    -- Distinguished Name
    rs.Distinguished_Name0 AS ADDistinguishedName,

    -- SCCM record creation date
    rs.Creation_Date0 AS SCCMRecordCreatedDate,

    -- Obsolete device status
    rs.Obsolete0 AS ObsoleteStatus,

    -- Decommissioned status
    rs.Decommissioned0 AS DecommissionedStatus,

    -- Operating system
    rs.Operating_System_Name_and0 AS OperatingSystem

FROM dbo.v_R_System rs

WHERE rs.Name0 IN
(
    SELECT
        Name0
    FROM dbo.v_R_System
    WHERE Name0 IS NOT NULL
    GROUP BY Name0
    HAVING COUNT(*) > 1
)

ORDER BY
    rs.Name0,
    rs.Creation_Date0 DESC;