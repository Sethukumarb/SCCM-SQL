/*
===============================================================================
Script Name : Get-SCCMMissingSecurityUpdates.sql
Author      : Sethu Kumar B
Purpose     : Identify devices missing Security software updates in SCCM.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Devices Missing Security Updates
-- ============================================================================

SELECT DISTINCT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Operating_System_Name_and0 AS OperatingSystem,

    ui.ArticleID,
    ui.Title AS UpdateTitle,
    ui.DatePosted,
    ui.IsDeployed,
    ui.IsExpired,
    ui.IsSuperseded,

    ucs.Status AS ComplianceStatusCode,

    CASE ucs.Status
        WHEN 2 THEN 'Required / Missing'
        WHEN 3 THEN 'Installed'
        ELSE 'Other / Unknown'
    END AS ComplianceStatus

FROM v_UpdateComplianceStatus ucs

INNER JOIN v_UpdateInfo ui
    ON ui.CI_ID = ucs.CI_ID

INNER JOIN v_R_System rs
    ON rs.ResourceID = ucs.ResourceID

WHERE
    -- Status 2 = Required / Missing
    ucs.Status = 2

    -- Security update filter based on title
    AND ui.Title LIKE '%Security%'

ORDER BY
    ui.DatePosted DESC,
    ui.ArticleID,
    rs.Name0;


-- ============================================================================
-- TABLE 2: Missing Security Update Summary
-- ============================================================================

SELECT
    ui.ArticleID,
    ui.Title AS UpdateTitle,
    ui.DatePosted,
    ui.IsDeployed,
    ui.IsExpired,
    ui.IsSuperseded,
    COUNT(DISTINCT ucs.ResourceID) AS MissingDeviceCount

FROM v_UpdateComplianceStatus ucs

INNER JOIN v_UpdateInfo ui
    ON ui.CI_ID = ucs.CI_ID

WHERE
    -- Status 2 = Required / Missing
    ucs.Status = 2

    -- Security update filter based on title
    AND ui.Title LIKE '%Security%'

GROUP BY
    ui.ArticleID,
    ui.Title,
    ui.DatePosted,
    ui.IsDeployed,
    ui.IsExpired,
    ui.IsSuperseded

ORDER BY
    MissingDeviceCount DESC,
    ui.DatePosted DESC;