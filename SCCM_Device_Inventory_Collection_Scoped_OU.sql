-- ============================================================
-- Script Name  : SCCM_Device_Inventory_Collection_Scoped_OU.sql
-- Version      : 1.3
-- Author       : Sethu Kumar B
-- Date         : March 2026
-- Database     : CAS (Central Administration Site)
-- ============================================================
--
-- DESCRIPTION:
-- ------------
-- This script generates a comprehensive Device Inventory Report
-- for a specific SCCM Collection. It is designed to run against
-- the CAS (Central Administration Site) database and returns
-- one row per device with full hardware, OS, serial number,
-- and user identity details.
--
-- ============================================================
-- DATA SOURCES:
-- ============================================================
--
--  View                            Purpose
--  ------------------------------  ---------------------------------
--  v_FullCollectionMembership      Scopes query to target collection
--  v_R_System                      Core device record & last logon user
--  v_GS_COMPUTER_SYSTEM            Manufacturer, Model, Domain, Processors
--  v_GS_WORKSTATION_STATUS         Last Hardware Scan timestamp
--  v_GS_SYSTEM                     System Role (Workstation / Server)
--  v_GS_PC_BIOS                    BIOS Serial Number
--  v_GS_OPERATING_SYSTEM           OS Name / Caption
--  v_GS_COMPUTER_SYSTEM_PRODUCT    System Serial Number, UUID, Model Version
--  v_GS_SYSTEM_ENCLOSURE           Chassis Type & Chassis Serial Number
--  v_GS_BASEBOARD                  Baseboard / Motherboard Serial Number
--  v_CH_ClientSummary              SCCM Client Health (Policy, Heartbeat)
--  v_R_User                        AD User attributes (UPN, Name, Department, Office)
--  v_RA_System_SystemOUName        Full OU / container path
--
-- ============================================================
-- CONFIG:
-- ============================================================
DECLARE @CollectionID NVARCHAR(8) = N'CAS01490';

;WITH CTE_OU AS
(
    SELECT
        ResourceID,
        MAX(System_OU_Name0) AS FullOUAddress
    FROM v_RA_System_SystemOUName
    GROUP BY ResourceID
)

SELECT
    rs.Name0                            AS [Device Name],
    cs.Domain0                          AS [Domain],
    rs.AD_Site_Name0                    AS [AD Site],
    rs.Distinguished_Name0              AS [AD Distinguished Name],
    ou.FullOUAddress                    AS [Full OU Address],

    cs.Manufacturer0                    AS [Manufacturer],
    cs.Model0                           AS [Model],
    csp.Version0                        AS [Model Version],
    cs.NumberOfProcessors0              AS [No. of Processors],
    enc.ChassisTypes0                   AS [Chassis Type],
    sys.SystemRole0                     AS [System Role],

    bios.SerialNumber0                  AS [BIOS Serial Number],
    csp.IdentifyingNumber0              AS [System Serial Number],
    csp.UUID0                           AS [UUID],
    enc.SerialNumber0                   AS [Chassis Serial Number],
    bb.SerialNumber0                    AS [Baseboard Serial Number],

    os.Caption0                         AS [OS Name],

    rs.User_Name0                       AS [Employee ID],
    usr.User_Name0                      AS [Username (SAMAccountName)],
    usr.Full_User_Name0                 AS [Full Name],
    usr.User_Principal_Name0            AS [User UPN Email],
    usr.physicalDeliveryOfficeNam0      AS [Office Location],
    usr.department0                     AS [Department],
    usr.title0                          AS [Job Title],

    ws.LastHWScan                       AS [Last HW Scan],
    ch.LastPolicyRequest                AS [Last Policy Request],
    ch.LastDDR                          AS [Last Heartbeat (DDR)],

    CASE ch.ClientActiveStatus
        WHEN 1 THEN 'Active'
        WHEN 0 THEN 'Inactive'
        ELSE       'Unknown'
    END                                 AS [Client Status]

FROM v_FullCollectionMembership fcm
INNER JOIN v_R_System rs
    ON rs.ResourceID = fcm.ResourceID

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

LEFT JOIN v_R_User usr
    ON usr.employeeID0 = rs.User_Name0

LEFT JOIN CTE_OU ou
    ON ou.ResourceID = rs.ResourceID

WHERE fcm.CollectionID = @CollectionID
  AND fcm.IsAssigned = 1

ORDER BY rs.Name0 ASC;