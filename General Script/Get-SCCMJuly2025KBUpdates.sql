/*
===========================================================================
Script Name : Get-SCCMJuly2025KBUpdates.sql
Purpose     : Retrieve all July 2025 KB updates known to SCCM/MECM
Author      : Sethu Kumar B
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only Reporting Query
===========================================================================

Description:
- Retrieves all software updates published during July 2025
- Displays KB Article ID, update title, release date, and deployment status
- Useful for patch validation, compliance review, and vulnerability tracking

Main SCCM View Used:
- v_UpdateInfo

Notes:
- Only updates with valid KB Article IDs are included
- IsDeployed:
    1 = Update has deployment created
    0 = No deployment exists
===========================================================================
*/

SELECT
    -- Microsoft KB Article Number
    ui.ArticleID,

    -- Full update title from SCCM catalog
    ui.Title,

    -- Date the update was posted/imported
    ui.DatePosted,

    -- Deployment status
    -- 1 = Deployed
    -- 0 = Not deployed
    ui.IsDeployed

FROM v_UpdateInfo ui

WHERE
    -- Filter updates posted during July 2025
    ui.DatePosted >= '2025-07-01'
    AND ui.DatePosted < '2025-08-01'

    -- Exclude updates without KB numbers
    AND ui.ArticleID IS NOT NULL

-- Sort results by KB number
ORDER BY ui.ArticleID;