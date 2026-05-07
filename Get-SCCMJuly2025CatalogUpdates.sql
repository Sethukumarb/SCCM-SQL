/*
===============================================================================
Script Name : Get-SCCMJuly2025CatalogUpdates.sql
Author      : Sethu Kumar B
Purpose     : Retrieve all July 2025 software updates synchronized into
              the SCCM update catalog.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all July 2025 software updates available in SCCM
- Displays:
    - KB Article ID
    - Update title
    - Deployment status
    - Expired status
    - Superseded status

Use Cases:
- Validate SCCM Software Update synchronization
- Identify missing July 2025 KBs
- Compare expected vs available updates
- Security compliance investigations
- Monthly patch audit reporting

Main SCCM Views Used:
- v_UpdateInfo

Important Notes:
- Useful for proving which updates successfully synchronized
  into SCCM versus missing updates

- IsDeployed:
    1 = Update deployed
    0 = Not deployed

- IsExpired:
    1 = Update expired
    0 = Active update

- IsSuperseded:
    1 = Replaced by newer update
    0 = Current update

===============================================================================
*/

SELECT

    -- Microsoft KB Article Number
    ui.ArticleID,

    -- SCCM Software Update Title
    ui.Title,

    -- Date update was published/imported
    ui.DatePosted,

    -- Deployment status
    -- 1 = Deployed
    -- 0 = Not deployed
    ui.IsDeployed,

    -- Expired status
    -- 1 = Expired
    -- 0 = Active
    ui.IsExpired,

    -- Superseded status
    -- 1 = Superseded
    -- 0 = Current
    ui.IsSuperseded

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