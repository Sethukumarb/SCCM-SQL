/*
===============================================================================
Script Name : Get-SCCMDevicesByADSite.sql

Purpose:
List SCCM-managed devices from a specific AD Site.

TABLE 1
- Windows Workstations (Clients)

TABLE 2
- Windows Servers

Type:
Read-Only SQL Report
===============================================================================
*/

DECLARE @ADSite NVARCHAR(50) = 'ABC';


-- ============================================================================
-- TABLE 1 : WINDOWS WORKSTATIONS (CLIENTS)
-- ============================================================================

SELECT
    rs.Name0 AS DeviceName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem

FROM v_R_System rs

WHERE
    rs.AD_Site_Name0 LIKE '%' + @ADSite + '%'
    AND rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    rs.Name0 ASC;


-- ============================================================================
-- TABLE 2 : WINDOWS SERVERS
-- ============================================================================

SELECT
    rs.Name0 AS DeviceName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem

FROM v_R_System rs

WHERE
    rs.AD_Site_Name0 LIKE '%' + @ADSite + '%'
    AND rs.Operating_System_Name_and0 NOT LIKE '%workstation%'

ORDER BY
    rs.Name0 ASC;
