/*
===============================================================================
Script Name : Get-SCCMStaleDevices.sql
Author      : Sethu Kumar B
Purpose     : Identify stale SCCM workstation devices based on old heartbeat,
              policy request, or hardware inventory activity.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- Adjustable threshold
DECLARE @StaleDays INT = 90;

-- ============================================================================
-- TABLE 1: Stale Device Details
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
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
    END AS ClientActiveStatus,

    CASE
        WHEN ch.LastDDR IS NULL THEN 'Missing Heartbeat'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @StaleDays THEN 'Stale Heartbeat'
        ELSE 'Review'
    END AS StaleReason

FROM v_R_System rs

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND
    (
        ch.LastDDR IS NULL
        OR DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @StaleDays
        OR ch.LastPolicyRequest IS NULL
        OR DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @StaleDays
        OR ch.LastHW IS NULL
        OR DATEDIFF(DAY, ch.LastHW, GETDATE()) > @StaleDays
    )

ORDER BY
    ch.LastDDR ASC,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Stale Device Summary
-- ============================================================================

SELECT
    CASE
        WHEN ch.LastDDR IS NULL THEN 'Missing Heartbeat'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @StaleDays THEN 'Stale Heartbeat'
        ELSE 'Other Stale Activity'
    END AS StaleCategory,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

LEFT JOIN v_CH_ClientSummary ch
    ON ch.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND
    (
        ch.LastDDR IS NULL
        OR DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @StaleDays
        OR ch.LastPolicyRequest IS NULL
        OR DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @StaleDays
        OR ch.LastHW IS NULL
        OR DATEDIFF(DAY, ch.LastHW, GETDATE()) > @StaleDays
    )

GROUP BY
    CASE
        WHEN ch.LastDDR IS NULL THEN 'Missing Heartbeat'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @StaleDays THEN 'Stale Heartbeat'
        ELSE 'Other Stale Activity'
    END

ORDER BY
    DeviceCount DESC;