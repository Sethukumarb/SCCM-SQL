/*
===============================================================================
Script Name : Get-SCCMActiveVsInactiveClients-WithPercentage.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM Active vs Inactive client status report.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level Active vs Inactive Status
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID,

    ch.LastPolicyRequest,
    ch.LastDDR AS LastHeartbeatDDR,
    ch.LastHW AS LastHardwareInventory,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS ClientStatus,

    ch.ClientActiveStatus AS ClientStatusCode

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

ORDER BY
    ClientStatus,
    ComputerName;


-- ============================================================================
-- TABLE 2: Active vs Inactive Summary Count with Percentage
-- ============================================================================

SELECT
    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS ClientStatus,

    COUNT(*) AS DeviceCount,

    CAST
    (
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,1)
    ) AS Percentage

FROM v_CH_ClientSummary ch

GROUP BY
    ch.ClientActiveStatus

ORDER BY
    ClientStatus;
