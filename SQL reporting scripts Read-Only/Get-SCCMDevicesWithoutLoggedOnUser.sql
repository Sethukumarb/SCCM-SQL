/*
===============================================================================
Script Name : Get-SCCMDevicesWithoutLoggedOnUser.sql
Author      : Sethu Kumar B
Purpose     : Identify SCCM workstation devices missing last logged-on user
              information.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Devices Without Last Logged-On User
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    CASE
        WHEN rs.User_Name0 IS NULL OR LTRIM(RTRIM(rs.User_Name0)) = ''
            THEN 'Missing Last Logged-On User'
        ELSE 'User Available'
    END AS LoginUserStatus

FROM v_R_System rs

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND
    (
        rs.User_Name0 IS NULL
        OR LTRIM(RTRIM(rs.User_Name0)) = ''
    )

ORDER BY
    rs.Name0;


-- ============================================================================
-- TABLE 2: Last Logged-On User Summary
-- ============================================================================

SELECT
    CASE
        WHEN rs.User_Name0 IS NULL OR LTRIM(RTRIM(rs.User_Name0)) = ''
            THEN 'Missing Last Logged-On User'
        ELSE 'User Available'
    END AS LoginUserStatus,

    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

GROUP BY
    CASE
        WHEN rs.User_Name0 IS NULL OR LTRIM(RTRIM(rs.User_Name0)) = ''
            THEN 'Missing Last Logged-On User'
        ELSE 'User Available'
    END

ORDER BY
    DeviceCount DESC;