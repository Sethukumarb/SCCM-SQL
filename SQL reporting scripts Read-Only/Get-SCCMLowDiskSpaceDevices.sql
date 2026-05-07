/*
===============================================================================
Script Name : Get-SCCMLowDiskSpaceDevices.sql
Author      : Sethu Kumar B
Purpose     : Identify Windows workstation devices with low free disk space
              on the C: drive.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- Adjustable threshold
DECLARE @FreeSpaceThresholdGB DECIMAL(10,2) = 20.00;

-- ============================================================================
-- TABLE 1: Device-Level Low Disk Space Report
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    ld.DeviceID0 AS DriveLetter,
    ld.Size0 AS TotalSizeMB,
    ld.FreeSpace0 AS FreeSpaceMB,

    CAST(ld.Size0 / 1024.0 AS DECIMAL(10,2)) AS TotalSizeGB,
    CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) AS FreeSpaceGB,

    CAST(
        100.0 * ld.FreeSpace0 / NULLIF(ld.Size0, 0)
        AS DECIMAL(5,1)
    ) AS FreeSpacePercentage

FROM v_R_System rs

INNER JOIN v_GS_LOGICAL_DISK ld
    ON ld.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND ld.DeviceID0 = 'C:'
    AND CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < @FreeSpaceThresholdGB

ORDER BY
    FreeSpaceGB ASC,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Low Disk Space Summary
-- ============================================================================

SELECT
    CASE
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 5 THEN 'Critical: Below 5 GB'
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 10 THEN 'High Risk: Below 10 GB'
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 20 THEN 'Warning: Below 20 GB'
        ELSE 'OK'
    END AS DiskSpaceCategory,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_GS_LOGICAL_DISK ld
    ON ld.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND ld.DeviceID0 = 'C:'

GROUP BY
    CASE
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 5 THEN 'Critical: Below 5 GB'
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 10 THEN 'High Risk: Below 10 GB'
        WHEN CAST(ld.FreeSpace0 / 1024.0 AS DECIMAL(10,2)) < 20 THEN 'Warning: Below 20 GB'
        ELSE 'OK'
    END

ORDER BY
    DeviceCount DESC;