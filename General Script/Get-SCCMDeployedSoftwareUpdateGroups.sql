/*
===============================================================================
Script Name : Get-SCCMDeployedSoftwareUpdateGroups.sql
Author      : Sethu Kumar B
Purpose     : Retrieve all Software Update Groups (SUGs) marked as
              deployed in SCCM.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves all SCCM Software Update Groups where deployment exists
- Displays:
    - Software Update Group Title
    - Deployment status
    - Expired status
    - CI_ID
    - CI_UniqueID

Use Cases:
- Validate SUG deployment existence
- Confirm patch deployment activity
- Troubleshoot missing update deployments
- Audit Software Update Groups
- Verify SCCM deployment metadata consistency

Main SCCM Views Used:
- v_AuthListInfo

Important Notes:
- IsDeployed = 1 indicates the SUG has at least one deployment
- IsExpired = 1 indicates expired Software Update Groups
- Useful for validating whether monthly update groups
  were actually deployed

===============================================================================
*/

SELECT

    -- Software Update Group title
    Title,

    -- Deployment status
    -- 1 = Deployed
    -- 0 = Not deployed
    IsDeployed,

    -- Expired status
    -- 1 = Expired
    -- 0 = Active
    IsExpired,

    -- SCCM Configuration Item ID
    CI_ID,

    -- SCCM Unique Configuration Item Identifier
    CI_UniqueID

FROM v_AuthListInfo

WHERE

    -- Retrieve only deployed Software Update Groups
    IsDeployed = 1

ORDER BY

    -- Sort alphabetically by SUG title
    Title;