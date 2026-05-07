/*
===============================================================================
Script Name : Get-SCCMJuly2025KBDeploymentStatus.sql
Author      : Sethu Kumar B
Purpose     : Retrieve July 2025 KB updates and deployment status
              from SCCM.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all SCCM software updates released during July 2025
- Displays:
    - KB Article ID
    - Update title
    - Date posted
    - Deployment status

Use Cases:
- Patch validation
- Monthly update audit
- Compliance reporting
- Vulnerability remediation tracking

Main SCCM Views Used:
- v_UpdateInfo

Deployment Status:
- 1 = Deployed
- 0 = Not deployed

===============================================================================
*/

SELECT DISTINCT

    -- Microsoft KB Article Number
    ui.ArticleID,

    -- SCCM Software Update Title
    ui.Title,

    -- Date update was published/imported
    ui.DatePosted,

    -- Deployment status
    -- 1 = Deployed
    -- 0 = Not deployed
    ui.IsDeployed

FROM v_UpdateInfo ui

WHERE

    -- Filter updates released during July 2025
    ui.DatePosted >= '2025-07-01'
    AND ui.DatePosted < '2025-08-01'

    -- Exclude updates without KB Article IDs
    AND ui.ArticleID IS NOT NULL

ORDER BY

    -- Sort by KB number
    ui.ArticleID;