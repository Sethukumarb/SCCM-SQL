/*
===============================================================================
Script Name : Find-SCCMDeploymentSource-ForApplication.sql
Author      : Sethu Kumar B

Purpose     :
This script checks whether a specific application exists in SCCM as:

    - Application
    - Package
    - Program
    - Deployment / Assignment

The script helps identify whether an application was deployed from SCCM
or simply detected through software inventory.

How To Use :
Update the @ApplicationName variable with the application name you want
to search for.

Examples:
    Google Chrome
    IBM System i Access
    Notepad++
    Citrix Workspace
    7-Zip

Use Cases  :
    - Validate SCCM deployment source
    - Troubleshoot unknown application installations
    - Identify legacy SCCM packages
    - Migration and cleanup projects
    - SCCM application audit

Environment :
    Microsoft SCCM / MECM SQL Database

Type        :
    Read-Only SQL Report
===============================================================================
*/

-- ============================================================================
-- Define Application Search Name
-- ============================================================================

DECLARE @ApplicationName NVARCHAR(200) = N'%Google Chrome%';


-- ============================================================================
-- TABLE 1: Check SCCM Applications
-- ============================================================================

SELECT
    'Application' AS SourceType,

    app.DisplayName AS Name,

    app.ModelName,

    app.SoftwareVersion,

    app.Manufacturer,

    app.DateCreated,

    app.DateLastModified

FROM fn_ListApplicationCIs(1033) app

WHERE
    app.DisplayName LIKE @ApplicationName

ORDER BY
    app.DisplayName;


-- ============================================================================
-- TABLE 2: Check SCCM Packages
-- ============================================================================

SELECT
    'Package' AS SourceType,

    pkg.PackageID,

    pkg.Name AS PackageName,

    pkg.Manufacturer,

    pkg.Version,

    pkg.Language,

    pkg.Description

FROM v_Package pkg

WHERE
    pkg.Name LIKE @ApplicationName
    OR pkg.Description LIKE @ApplicationName

ORDER BY
    pkg.Name;


-- ============================================================================
-- TABLE 3: Check SCCM Programs
-- ============================================================================

SELECT
    'Program' AS SourceType,

    prog.PackageID,

    pkg.Name AS PackageName,

    prog.ProgramName,

    prog.CommandLine

FROM v_Program prog

LEFT JOIN v_Package pkg
    ON pkg.PackageID = prog.PackageID

WHERE
    prog.ProgramName LIKE @ApplicationName
    OR prog.CommandLine LIKE @ApplicationName
    OR pkg.Name LIKE @ApplicationName

ORDER BY
    pkg.Name,
    prog.ProgramName;


-- ============================================================================
-- TABLE 4: Check SCCM Deployments / Assignments
-- ============================================================================

SELECT
    'Deployment' AS SourceType,

    assign.AssignmentID,

    assign.AssignmentName,

    col.Name AS TargetCollection,

    assign.CreationTime,

    assign.StartTime,

    assign.EnforcementDeadline

FROM v_CIAssignment assign

LEFT JOIN v_Collection col
    ON col.CollectionID = assign.CollectionID

WHERE
    assign.AssignmentName LIKE @ApplicationName

ORDER BY
    assign.StartTime DESC;
