/*
===============================================================================
Script Name : Get-SCCMInstalledApplicationsCountOnly.sql
Author      : Sethu Kumar B
Purpose     : Retrieve installed application inventory from SCCM using
              Add/Remove Programs data.
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
-- TABLE 1: Application Summary Count
-- ============================================================================

SELECT
    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0 AS Publisher,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

WHERE
    ISNULL(arp.DisplayName0, '') <> ''

GROUP BY
    arp.DisplayName0,
    arp.Publisher0

ORDER BY
    DeviceCount DESC,
    ApplicationName;