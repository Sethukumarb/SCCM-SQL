/*
===============================================================================
Script Name : Get-SCCMDevicesMissingInventory.sql
Author      : Sethu Kumar B
Purpose     : Identify SCCM devices missing recent policy request,
              heartbeat DDR, or hardware inventory data.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- Adjustable thresholds
DECLARE @PolicyDays    INT = 7;    -- Last policy request threshold
DECLARE @HeartbeatDays INT = 7;    -- Last heartbeat DDR threshold
DECLARE @HardwareDays  INT = 30;   -- Last hardware inventory threshold

-- ============================================================================
-- TABLE 1: Devices Missing or Having Old Inventory / Client Activity
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID,
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
    END AS ClientActiveStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

WHERE
    ch.LastPolicyRequest IS NULL
    OR DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays
    OR ch.LastDDR IS NULL
    OR DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays
    OR ch.LastHW IS NULL
    OR DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays

ORDER BY
    ComputerName;


-- ============================================================================
-- TABLE 2: Missing / Old Inventory Summary Count
-- ============================================================================

SELECT
    IssueType,
    COUNT(*) AS DeviceCount
FROM
(
    SELECT
        ch.ResourceID,
        CASE
            WHEN ch.LastPolicyRequest IS NULL THEN 'Policy Missing'
            WHEN DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays THEN 'Policy Old'
        END AS IssueType
    FROM v_CH_ClientSummary ch
    WHERE ch.LastPolicyRequest IS NULL
       OR DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays

    UNION ALL

    SELECT
        ch.ResourceID,
        CASE
            WHEN ch.LastDDR IS NULL THEN 'Heartbeat Missing'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays THEN 'Heartbeat Old'
        END AS IssueType
    FROM v_CH_ClientSummary ch
    WHERE ch.LastDDR IS NULL
       OR DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays

    UNION ALL

    SELECT
        ch.ResourceID,
        CASE
            WHEN ch.LastHW IS NULL THEN 'Hardware Inventory Missing'
            WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays THEN 'Hardware Inventory Old'
        END AS IssueType
    FROM v_CH_ClientSummary ch
    WHERE ch.LastHW IS NULL
       OR DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays

) AS InventoryIssues

GROUP BY
    IssueType

ORDER BY
    IssueType;