/*
===============================================================================
Script Name : Get-SCCMClientActiveVsInactiveSummary.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM client Active vs Inactive device status
              along with inventory and client activity details.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- Adjustable thresholds
DECLARE @PolicyDays    INT = 7;    -- Last policy request threshold
DECLARE @HeartbeatDays INT = 7;    -- Last heartbeat DDR threshold
DECLARE @HardwareDays  INT = 30;   -- Last hardware inventory threshold

-- ============================================================================
-- TABLE 1: Device-Level Active vs Inactive Status
-- ============================================================================

SELECT

    -- Device hostname
    rs.Name0 AS ComputerName,

    -- SCCM Resource ID
    ch.ResourceID,

    -- Last machine policy request
    ch.LastPolicyRequest,

    -- Last heartbeat DDR
    ch.LastDDR AS LastHeartbeatDDR,

    -- Last hardware inventory
    ch.LastHW AS LastHardwareInventory,

    -- SCCM active/inactive state
    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS ClientStatus,

    -- Policy request health
    CASE
        WHEN ch.LastPolicyRequest IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays THEN 'Old'
        ELSE 'OK'
    END AS PolicyStatus,

    -- Heartbeat DDR health
    CASE
        WHEN ch.LastDDR IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays THEN 'Old'
        ELSE 'OK'
    END AS HeartbeatStatus,

    -- Hardware inventory health
    CASE
        WHEN ch.LastHW IS NULL THEN 'Missing'
        WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays THEN 'Old'
        ELSE 'OK'
    END AS HardwareInventoryStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

ORDER BY

    -- Inactive devices first
    ClientStatus,

    -- Then device name
    ComputerName;


-- ============================================================================
-- TABLE 2: Active vs Inactive Summary
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


-- ============================================================================
-- TABLE 3: Inactive Devices by Issue Type
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

    WHERE ch.ClientActiveStatus = 0
      AND
      (
          ch.LastPolicyRequest IS NULL
          OR DATEDIFF(DAY, ch.LastPolicyRequest, GETDATE()) > @PolicyDays
      )

    UNION ALL

    SELECT
        ch.ResourceID,

        CASE
            WHEN ch.LastDDR IS NULL THEN 'Heartbeat Missing'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays THEN 'Heartbeat Old'
        END AS IssueType

    FROM v_CH_ClientSummary ch

    WHERE ch.ClientActiveStatus = 0
      AND
      (
          ch.LastDDR IS NULL
          OR DATEDIFF(DAY, ch.LastDDR, GETDATE()) > @HeartbeatDays
      )

    UNION ALL

    SELECT
        ch.ResourceID,

        CASE
            WHEN ch.LastHW IS NULL THEN 'Hardware Inventory Missing'
            WHEN DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays THEN 'Hardware Inventory Old'
        END AS IssueType

    FROM v_CH_ClientSummary ch

    WHERE ch.ClientActiveStatus = 0
      AND
      (
          ch.LastHW IS NULL
          OR DATEDIFF(DAY, ch.LastHW, GETDATE()) > @HardwareDays
      )

) AS InactiveIssues

GROUP BY
    IssueType

ORDER BY
    DeviceCount DESC;