-- ============================================================
-- Script Name  : SCCM_Device_Inventory_Multi_User_Filtered.sql
-- Version      : 1.6
-- Author       : Sethu Kumar B
-- Date         : April 2026
-- Database     : CAS (Central Administration Site)
-- ============================================================
--
-- DESCRIPTION:
-- ------------
-- This script returns SCCM device inventory for multiple users
-- based on email address (UPN). It includes:
--   - Device identity
--   - Hardware and serial details
--   - User identity
--   - Location details
--   - Laptop / Desktop Y/N flags
--
-- Paste all required email IDs in the @Users table section.
--
-- ============================================================
-- USER INPUT LIST
-- ============================================================

DECLARE @Users TABLE
(
    UserEmail NVARCHAR(256)
);

INSERT INTO @Users (UserEmail)
VALUES
    (N'user1@company.com'),
    (N'user2@company.com'),
    (N'user3@company.com');
    -- Add remaining users here
    -- (N'user4@company.com'),
    -- (N'user5@company.com');

;WITH CTE_OU AS
(
    SELECT
        ResourceID,
        MAX(System_OU_Name0) AS FullOUAddress
    FROM v_RA_System_SystemOUName
    GROUP BY ResourceID
)

SELECT
    -- Input Email
    u.UserEmail                         AS [Input Email],

    -- Device Identity
    rs.Name0                            AS [Device Name],
    cs.Domain0                          AS [Domain],
    rs.AD_Site_Name0                    AS [AD Site],
    rs.Distinguished_Name0              AS [AD Distinguished Name],
    ou.FullOUAddress                    AS [Full OU Address],

    -- Location Details
    usr.physicalDeliveryOfficeNam0      AS [Office Location],
    rs.AD_Site_Name0                    AS [Site],
    ou.FullOUAddress                    AS [OU],

    -- Device Type Flags
    CASE
        WHEN enc.ChassisTypes0 IN (8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32)
            THEN 'Y'
        ELSE 'N'
    END                                 AS [Laptop Y/N],

    CASE
        WHEN enc.ChassisTypes0 IN (3, 4, 5, 6, 7, 15, 16)
            THEN 'Y'
        ELSE 'N'
    END                                 AS [Desktop Y/N],

    -- Hardware Details
    cs.Manufacturer0                    AS [Manufacturer],
    cs.Model0                           AS [Model],
    csp.Version0                        AS [Model Version],
    cs.NumberOfProcessors0              AS [No. of Processors],
    enc.ChassisTypes0                   AS [Chassis Type],
    sys.SystemRole0                     AS [System Role],

    -- Serial Numbers
    bios.SerialNumber0                  AS [BIOS Serial Number],
    csp.IdentifyingNumber0              AS [System Serial Number],
    csp.UUID0                           AS [UUID],
    enc.SerialNumber0                   AS [Chassis Serial Number],
    bb.SerialNumber0                    AS [Baseboard Serial Number],

    -- OS Details
    os.Caption0                         AS [OS Name],

    -- User Identity
    rs.User_Name0                       AS [Employee ID],
    usr.User_Name0                      AS [Username (SAMAccountName)],
    usr.Full_User_Name0                 AS [Full Name],
    usr.User_Principal_Name0            AS [User UPN Email],
    usr.department0                     AS [Department],
    usr.title0                          AS [Job Title],

    -- Client Health
    ws.LastHWScan                       AS [Last HW Scan],
    ch.LastPolicyRequest                AS [Last Policy Request],
    ch.LastDDR                          AS [Last Heartbeat (DDR)],

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE       'Unknown'
    END                                 AS [Client Status]

FROM @Users u

INNER JOIN v_R_User usr
    ON usr.User_Principal_Name0 = u.UserEmail

INNER JOIN v_R_System rs
    ON usr.employeeID0 = rs.User_Name0

LEFT JOIN v_GS_COMPUTER_SYSTEM cs
    ON rs.ResourceID = cs.ResourceID

LEFT JOIN v_GS_WORKSTATION_STATUS ws
    ON rs.ResourceID = ws.ResourceID

LEFT JOIN v_GS_SYSTEM sys
    ON rs.ResourceID = sys.ResourceID

LEFT JOIN v_GS_PC_BIOS bios
    ON rs.ResourceID = bios.ResourceID

LEFT JOIN v_GS_OPERATING_SYSTEM os
    ON rs.ResourceID = os.ResourceID

LEFT JOIN v_GS_COMPUTER_SYSTEM_PRODUCT csp
    ON rs.ResourceID = csp.ResourceID

LEFT JOIN v_GS_SYSTEM_ENCLOSURE enc
    ON rs.ResourceID = enc.ResourceID

LEFT JOIN v_GS_BASEBOARD bb
    ON rs.ResourceID = bb.ResourceID

LEFT JOIN v_CH_ClientSummary ch
    ON rs.ResourceID = ch.ResourceID

LEFT JOIN CTE_OU ou
    ON ou.ResourceID = rs.ResourceID

ORDER BY
    u.UserEmail ASC,
    rs.Name0 ASC;