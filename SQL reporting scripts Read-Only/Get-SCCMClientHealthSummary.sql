/*
===============================================================================
Script Name : Get-SCCMClientHealthSummary.sql
Author      : Sethu Kumar B
Purpose     : Get SCCM client health summary using policy request,
              heartbeat DDR, and hardware inventory status.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- Adjustable thresholds
DECLARE @PolicyDays    INT = 7;    -- Last policy request threshold
DECLARE @HeartbeatDays INT = 7;    -- Last heartbeat DDR threshold
DECLARE @HardwareDays  INT = 30;   -- Last hardware inventory threshold

-- ============================================================================
-- TABLE 1: Device-Level SCCM Client Health Details
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID AS ResourceID,

    ch.LastPolicyRequest,
    ch.LastDDR AS LastHeartbeatDDR,
    ch.LastHW AS LastHardwareInventory,

    CASE
        WHEN ch.LastPolicyRequest IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays THEN 'Old'
        ELSE 'OK'
    END AS PolicyStatus,

    CASE
        WHEN ch.LastDDR IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays THEN 'Old'
        ELSE 'OK'
    END AS HeartbeatStatus,

    CASE
        WHEN ch.LastHW IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays THEN 'Old'
        ELSE 'OK'
    END AS HardwareInventoryStatus,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS ClientActiveStatus,

    CASE
        WHEN ch.LastPolicyRequest IS NOT NULL
         AND DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) <= @PolicyDays
         AND ch.LastDDR IS NOT NULL
         AND DATEDIFF(DAY, ch.LastDDR, GETDATE()) <= @HeartbeatDays
         AND ch.LastHW IS NOT NULL
         AND DATEDIFF(DAY, ch.LastHW, GETDATE()) <= @HardwareDays
         AND ch.ClientActiveStatus = 1
            THEN 'Healthy'
        ELSE 'Needs Checking'
    END AS OverallHealthStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

ORDER BY
    OverallHealthStatus,
    ComputerName;


-- ============================================================================
-- TABLE 2: SCCM Client Health Summary Count
-- ============================================================================

SELECT
    OverallHealthStatus,
    COUNT(*) AS DeviceCount
FROM
(
    SELECT
        CASE
            WHEN ch.LastPolicyRequest IS NOT NULL
             AND DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) <= @PolicyDays
             AND ch.LastDDR IS NOT NULL
             AND DATEDIFF(DAY, ch.LastDDR, GETDATE()) <= @HeartbeatDays
             AND ch.LastHW IS NOT NULL
             AND DATEDIFF(DAY, ch.LastHW, GETDATE()) <= @HardwareDays
             AND ch.ClientActiveStatus = 1
                THEN 'Healthy'
            ELSE 'Needs Checking'
        END AS OverallHealthStatus
    FROM v_CH_ClientSummary ch
) AS SummaryData
GROUP BY
    OverallHealthStatus
ORDER BY
    OverallHealthStatus;