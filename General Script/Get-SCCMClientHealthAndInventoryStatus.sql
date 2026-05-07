/*
===============================================================================
Script Name : Get-SCCMClientHealthAndInventoryStatus.sql
Author      : Sethu Kumar B
Purpose     : Evaluate SCCM client health status for devices within a
              specific collection using policy, heartbeat DDR, and
              hardware inventory activity.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Evaluates SCCM client health based on:
    - Policy Request activity
    - Heartbeat DDR activity
    - Hardware Inventory activity
    - Client active/inactive state

- Generates:
    1. Detailed device-level health report
    2. Summary report with counts and percentages

Use Cases:
- SCCM client health monitoring
- Inventory troubleshooting
- Device communication validation
- Compliance health reporting
- Collection-based operational review

Main SCCM Views Used:
- v_CH_ClientSummary
- v_R_System
- v_FullCollectionMembership

Important Notes:
- Devices are marked "Healthy" only when:
    - Policy = OK
    - Heartbeat = OK
    - Hardware Inventory = OK

- Thresholds are adjustable

===============================================================================
*/


-- ============================================================================
-- Adjustable Thresholds
-- ============================================================================

DECLARE @PolicyDays    INT = 7;    -- Recent policy request threshold
DECLARE @HeartbeatDays INT = 7;    -- Recent heartbeat DDR threshold
DECLARE @HwDays        INT = 30;   -- Recent hardware inventory threshold

-- Target SCCM Collection
DECLARE @CollectionID NVARCHAR(8) = N'CAS000AE';


-- ============================================================================
-- BASE DATASET
-- Retrieve SCCM client activity details
-- ============================================================================

WITH Base AS
(
    SELECT

        -- Device hostname
        rs.Name0 AS ComputerName,

        -- SCCM Resource ID
        ch.ResourceID AS MachineID,

        -- Last machine policy request
        ch.LastPolicyRequest,

        -- Last heartbeat DDR
        ch.LastDDR,

        -- Last hardware inventory scan
        ch.LastHW,

        -- SCCM active/inactive state
        ch.ClientActiveStatus

    FROM v_CH_ClientSummary AS ch

    -- Join device information
    LEFT JOIN v_R_System AS rs
        ON rs.ResourceID = ch.ResourceID

    -- Limit devices to selected collection
    JOIN v_FullCollectionMembership AS fcm
        ON fcm.ResourceID = ch.ResourceID
       AND fcm.CollectionID = @CollectionID
),


-- ============================================================================
-- STATUS CLASSIFICATION
-- Convert raw timestamps into friendly health states
-- ============================================================================

Statusified AS
(
    SELECT

        b.*,

        -- =========================================================================
        -- Policy Status Evaluation
        -- =========================================================================
        CASE

            WHEN b.LastPolicyRequest IS NULL
                THEN 'Missing'

            WHEN DATEDIFF(DAY, b.LastPolicyRequest, GETDATE()) > @PolicyDays
                THEN 'Old (>' + CAST(@PolicyDays AS VARCHAR(10)) + 'd)'

            ELSE 'OK'

        END AS PolicyStatus,


        -- =========================================================================
        -- Heartbeat DDR Status Evaluation
        -- =========================================================================
        CASE

            WHEN b.LastDDR IS NULL
                THEN 'Missing'

            WHEN DATEDIFF(DAY, b.LastDDR, GETDATE()) > @HeartbeatDays
                THEN 'Old (>' + CAST(@HeartbeatDays AS VARCHAR(10)) + 'd)'

            ELSE 'OK'

        END AS HeartbeatStatus,


        -- =========================================================================
        -- Hardware Inventory Status Evaluation
        -- =========================================================================
        CASE

            WHEN b.LastHW IS NULL
                THEN 'Missing'

            WHEN DATEDIFF(DAY, b.LastHW, GETDATE()) > @HwDays
                THEN 'Old (>' + CAST(@HwDays AS VARCHAR(10)) + 'd)'

            ELSE 'OK'

        END AS HardwareInvStatus

    FROM Base AS b
)


-- ============================================================================
-- FINAL DEVICE HEALTH EVALUATION
-- ============================================================================

SELECT

    s.ComputerName,
    s.MachineID,
    s.LastPolicyRequest,
    s.LastDDR,
    s.LastHW,
    s.PolicyStatus,
    s.HeartbeatStatus,
    s.HardwareInvStatus,

    -- SCCM Client Active State Mapping
    CASE s.ClientActiveStatus

        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'

        ELSE 'Unknown'

    END AS ClientActiveStatusText,

    s.ClientActiveStatus AS ClientActiveStatusCode,

    -- Final overall health evaluation
    CASE

        WHEN s.PolicyStatus = 'OK'
         AND s.HeartbeatStatus = 'OK'
         AND s.HardwareInvStatus = 'OK'

            THEN 'Healthy'

        ELSE 'Needs Checking'

    END AS Evaluation

INTO #Final

FROM Statusified AS s;


-- ============================================================================
-- TABLE 1
-- Detailed Device-Level Health Report
-- ============================================================================

SELECT

    f.ComputerName,
    f.MachineID,
    f.LastPolicyRequest,
    f.LastDDR,
    f.LastHW,
    f.PolicyStatus,
    f.HeartbeatStatus,
    f.HardwareInvStatus,
    f.ClientActiveStatusText,
    f.ClientActiveStatusCode,
    f.Evaluation

FROM #Final AS f

ORDER BY

    f.ComputerName,
    f.MachineID;


-- ============================================================================
-- TABLE 2
-- Summary Report with Counts and Percentages
-- ============================================================================

;WITH Tot AS
(
    SELECT COUNT(*) AS TotalDevices
    FROM #Final
)

SELECT

    Metric,
    Value,
    DeviceCount,
    TotalDevices,

    -- Percentage of total devices
    CAST
    (
        100.0 * DeviceCount / NULLIF(TotalDevices, 0)
        AS DECIMAL(5,1)
    ) AS PctOfTotal

FROM
(
    -- Overall evaluation summary
    SELECT
        'Evaluation' AS Metric,
        f.Evaluation AS Value,
        COUNT(*) AS DeviceCount
    FROM #Final AS f
    GROUP BY f.Evaluation

    UNION ALL

    -- SCCM active/inactive summary
    SELECT
        'ClientActiveStatusText',
        f.ClientActiveStatusText,
        COUNT(*)
    FROM #Final AS f
    GROUP BY f.ClientActiveStatusText

    UNION ALL

    -- Hardware inventory summary
    SELECT
        'HardwareInvStatus',
        f.HardwareInvStatus,
        COUNT(*)
    FROM #Final AS f
    GROUP BY f.HardwareInvStatus

    UNION ALL

    -- Heartbeat status summary
    SELECT
        'HeartbeatStatus',
        f.HeartbeatStatus,
        COUNT(*)
    FROM #Final AS f
    GROUP BY f.HeartbeatStatus

) d

CROSS JOIN Tot

ORDER BY

    Metric,
    Value;


-- ============================================================================
-- Cleanup Temporary Table
-- ============================================================================

IF OBJECT_ID('tempdb..#Final') IS NOT NULL
    DROP TABLE #Final;