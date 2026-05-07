/*
===============================================================================
Script Name : Get-SCCMClientVersionInventory.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM client version inventory and identify devices
              running different client versions.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level SCCM Client Version Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,
    rs.Client0 AS ClientInstalled,
    rs.Client_Version0 AS SCCMClientVersion,
    rs.Active0 AS ActiveStatus
FROM v_R_System rs
WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
ORDER BY
    rs.Client_Version0,
    rs.Name0;


-- ============================================================================
-- TABLE 2: SCCM Client Version Summary
-- ============================================================================

SELECT
    ISNULL(rs.Client_Version0, 'Missing / No Client') AS SCCMClientVersion,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount
FROM v_R_System rs
WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
GROUP BY
    ISNULL(rs.Client_Version0, 'Missing / No Client')
ORDER BY
    DeviceCount DESC;