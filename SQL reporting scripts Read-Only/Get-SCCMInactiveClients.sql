/*
===============================================================================
Script Name : Get-SCCMInactiveClients.sql
Author      : Sethu Kumar B
Purpose     : Identify inactive SCCM clients with last policy request,
              heartbeat DDR, and hardware inventory details.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- IMPORTANT:
-- Make sure you are connected to the SCCM Site Database before running.
-- Example:
-- USE CM_ABC;
-- GO

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    ch.LastPolicyRequest,
    ch.LastDDR AS LastHeartbeatDDR,
    ch.LastHW AS LastHardwareInventory,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS ClientActiveStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

WHERE
    ch.ClientActiveStatus = 0

ORDER BY
    ch.LastDDR ASC,
    rs.Name0;