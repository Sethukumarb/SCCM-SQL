/*
===============================================================================
Script Name : Get-SCCMCollectionMembers.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM collection membership details for a specific
              collection ID.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- IMPORTANT:
-- Make sure you are connected to the SCCM Site Database before running.
-- Example:
-- USE CM_ABC;
-- GO

-- Target SCCM Collection ID
DECLARE @CollectionID NVARCHAR(8) = N'CAS231234E';


-- ============================================================================
-- TABLE 1: Collection Member Device Details
-- ============================================================================

SELECT
    fcm.CollectionID,
    col.Name AS CollectionName,
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,
    rs.Client0 AS ClientInstalled,
    rs.Active0 AS ActiveStatus
FROM v_FullCollectionMembership fcm

LEFT JOIN v_R_System rs
    ON rs.ResourceID = fcm.ResourceID

LEFT JOIN v_Collection col
    ON col.CollectionID = fcm.CollectionID

WHERE
    fcm.CollectionID = @CollectionID

ORDER BY
    rs.Name0;


-- ============================================================================
-- TABLE 2: Collection Member Count Summary
-- ============================================================================

SELECT
    fcm.CollectionID,
    col.Name AS CollectionName,
    COUNT(DISTINCT fcm.ResourceID) AS DeviceCount
FROM v_FullCollectionMembership fcm

LEFT JOIN v_Collection col
    ON col.CollectionID = fcm.CollectionID

WHERE
    fcm.CollectionID = @CollectionID

GROUP BY
    fcm.CollectionID,
    col.Name;