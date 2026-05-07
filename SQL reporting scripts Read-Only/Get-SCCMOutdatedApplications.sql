/*
===============================================================================
Script Name : Get-SCCMOutdatedApplications.sql
Author      : Sethu Kumar B
Purpose     : Identify devices with specific outdated application versions
              installed from SCCM Add/Remove Programs inventory.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- Define Applications and Minimum Approved Versions
-- Update these values based on your organization standard
-- ============================================================================

DECLARE @AppVersionBaseline TABLE
(
    ApplicationKeyword NVARCHAR(200),
    MinimumApprovedVersion NVARCHAR(100)
);

INSERT INTO @AppVersionBaseline
(
    ApplicationKeyword,
    MinimumApprovedVersion
)
VALUES
    ('Google Chrome', '120.0.0.0'),
    ('Microsoft Edge', '120.0.0.0'),
    ('Mozilla Firefox', '120.0'),
    ('Citrix Workspace', '24.2.3001.9'),
    ('7-Zip', '23.01'),
    ('Notepad++', '8.6');


-- ============================================================================
-- TABLE 1: Devices with Outdated Applications
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    arp.DisplayName0 AS ApplicationName,
    arp.Publisher0 AS Publisher,
    arp.Version0 AS InstalledVersion,
    avb.MinimumApprovedVersion,

    CASE
        WHEN arp.Version0 < avb.MinimumApprovedVersion THEN 'Outdated'
        ELSE 'OK'
    END AS VersionStatus

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

INNER JOIN @AppVersionBaseline avb
    ON arp.DisplayName0 LIKE '%' + avb.ApplicationKeyword + '%'

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND ISNULL(arp.Version0, '') <> ''
    AND rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.Version0 < avb.MinimumApprovedVersion

ORDER BY
    ApplicationName,
    InstalledVersion,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Outdated Application Summary
-- ============================================================================

SELECT
    avb.ApplicationKeyword AS ApplicationName,
    avb.MinimumApprovedVersion,
    arp.Version0 AS InstalledVersion,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

INNER JOIN v_Add_Remove_Programs arp
    ON arp.ResourceID = rs.ResourceID

INNER JOIN @AppVersionBaseline avb
    ON arp.DisplayName0 LIKE '%' + avb.ApplicationKeyword + '%'

WHERE
    ISNULL(arp.DisplayName0, '') <> ''
    AND ISNULL(arp.Version0, '') <> ''
    AND rs.Operating_System_Name_and0 LIKE '%workstation%'
    AND arp.Version0 < avb.MinimumApprovedVersion

GROUP BY
    avb.ApplicationKeyword,
    avb.MinimumApprovedVersion,
    arp.Version0

ORDER BY
    ApplicationName,
    DeviceCount DESC;