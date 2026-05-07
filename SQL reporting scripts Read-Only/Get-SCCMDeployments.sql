/*
===============================================================================
Script Name : Get-SCCMDeployments.sql
Author      : Sethu Kumar B
Purpose     : Retrieve SCCM deployment information and target collections.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: SCCM Deployment Details
-- ============================================================================

SELECT DISTINCT

    -- Deployment name
    assign.AssignmentName AS DeploymentName,

    -- Target collection
    col.Name AS TargetCollection,

    -- Deployment creation time
    assign.CreationTime,

    -- Deployment start time
    assign.StartTime,

    -- Enforcement deadline
    assign.EnforcementDeadline,

    -- Assignment identifiers
    assign.AssignmentID,
    assign.Assignment_UniqueID

FROM v_CIAssignment assign

LEFT JOIN v_Collection col
    ON col.CollectionID = assign.CollectionID

WHERE
    assign.AssignmentName IS NOT NULL

ORDER BY
    assign.StartTime DESC,
    assign.AssignmentName;


-- ============================================================================
-- TABLE 2: Deployment Summary Count
-- ============================================================================

SELECT
    COUNT(DISTINCT assign.AssignmentID) AS TotalDeployments
FROM v_CIAssignment assign
WHERE
    assign.AssignmentName IS NOT NULL;