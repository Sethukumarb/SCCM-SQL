/*
===============================================================================
Script Name : Get-SCCMWindowsBuildInventory.sql
Author      : Sethu Kumar B
Purpose     : Retrieve Windows workstation OS build inventory and device
              count per build number.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- IMPORTANT:
-- Make sure you are connected to the SCCM Site Database before running.
-- Example:
-- USE CM_ABC;
-- GO


-- ============================================================================
-- TABLE 1: Windows Workstation Device-Level Build Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    os.Caption0 AS OperatingSystem,
    os.Version0 AS FullOSVersion,
    os.BuildNumber0 AS BuildNumber
FROM v_R_System rs
INNER JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = rs.ResourceID
WHERE
    os.Caption0 LIKE '%Windows%'
    AND os.Caption0 NOT LIKE '%Server%'
ORDER BY
    TRY_CAST(os.BuildNumber0 AS INT) DESC,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Windows Build Summary Count
-- ============================================================================

SELECT
    os.Caption0 AS OperatingSystem,
    os.BuildNumber0 AS BuildNumber,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount
FROM v_R_System rs
INNER JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = rs.ResourceID
WHERE
    os.Caption0 LIKE '%Windows%'
    AND os.Caption0 NOT LIKE '%Server%'
GROUP BY
    os.Caption0,
    os.BuildNumber0
ORDER BY
    TRY_CAST(os.BuildNumber0 AS INT) DESC;