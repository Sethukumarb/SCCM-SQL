/*
===============================================================================
Script Name : Get-SCCMClientHeartbeatActivitySummary-WithPercentage.sql
Author      : Sethu Kumar B

Purpose     :
This script provides a detailed SCCM client heartbeat activity report
based on the last Heartbeat DDR communication received from devices.

The report categorizes devices into:
    - Active within last 0 to 7 days
    - Active within last 8 to 15 days
    - Inactive within last 16 to 30 days
    - Not reported for more than 30 days
    - Never reported

The script generates:
    1. Device-level heartbeat activity details
    2. Summary count with percentage for each activity category

Use Cases  :
    - SCCM client health monitoring
    - Identify stale or inactive devices
    - SCCM cleanup planning
    - Compliance and reporting dashboards
    - Infrastructure health reporting
    - Management reporting

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/
-- ============================================================================
-- TABLE 1: Device-Level Client Activity Status
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    ch.ResourceID,

    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    ch.LastDDR AS LastHeartbeatDDR,

    DATEDIFF(DAY, ch.LastDDR, GETDATE()) AS DaysSinceLastHeartbeat,

    CASE
        WHEN ch.LastDDR IS NULL THEN 'Never Reported'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 0 AND 7
            THEN 'Active - 0 to 7 Days'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 8 AND 15
            THEN 'Active - 8 to 15 Days'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 16 AND 30
            THEN 'Inactive - 16 to 30 Days'
        WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > 30
            THEN 'Inactive - Not Reported More Than 30 Days'
        ELSE 'Unknown'
    END AS ActivityStatus,

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS SCCMClientActiveStatus

FROM v_CH_ClientSummary ch

LEFT JOIN v_R_System rs
    ON rs.ResourceID = ch.ResourceID

ORDER BY
    DaysSinceLastHeartbeat DESC,
    ComputerName;


-- ============================================================================
-- TABLE 2: Client Activity Summary Count with Percentage
-- ============================================================================

SELECT
    ActivityStatus,

    COUNT(*) AS DeviceCount,

    CAST
    (
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,1)
    ) AS Percentage

FROM
(
    SELECT
        CASE
            WHEN ch.LastDDR IS NULL THEN 'Never Reported'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 0 AND 7
                THEN 'Active - 0 to 7 Days'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 8 AND 15
                THEN 'Active - 8 to 15 Days'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) BETWEEN 16 AND 30
                THEN 'Inactive - 16 to 30 Days'
            WHEN DATEDIFF(DAY, ch.LastDDR, GETDATE()) > 30
                THEN 'Inactive - Not Reported More Than 30 Days'
            ELSE 'Unknown'
        END AS ActivityStatus

    FROM v_CH_ClientSummary ch

) AS ActivitySummary

GROUP BY
    ActivityStatus

ORDER BY
    DeviceCount DESC;
