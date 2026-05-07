-- ============================================================
-- Script Name  : SCCM_Device_Inventory_Collection_Scoped.sql
-- Version      : 1.0
-- Author       : Sethu Kumar B
-- Team         : Endpoint Engineering – Western Digital (WDC)
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
-- The report is intended for use by Endpoint Engineering and
-- IT Management teams to audit managed devices, validate asset
-- information, and identify device-to-user assignments across
-- the enterprise fleet.
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
--  v_R_User                        AD User attributes (UPN, Name, Department)
--
-- ============================================================
-- USER MATCHING LOGIC:
-- ============================================================
--
--  v_R_System.User_Name0 stores the Employee ID of the last
--  logged-on user (WDC-specific AD schema).
--
--  This Employee ID is matched against v_R_User.employeeID0
--  to retrieve:
--    - Username (SAMAccountName)
--    - Full Name (Display Name)
--    - User Principal Name (UPN / Corporate Email)
--    - Department and Job Title
--
-- ============================================================
-- OUTPUT COLUMNS:
-- ============================================================
--
--  Category            Column
--  ------------------  ------------------------------------
--  Device Identity     Device Name, Domain, AD Site, DN
--  Hardware            Manufacturer, Model, Processors,
--                      Chassis Type, System Role
--  Serial Numbers      BIOS, System, UUID, Chassis, Baseboard
--  Operating System    OS Name
--  User Identity       Employee ID, SAMAccountName,
--                      Full Name, UPN Email,
--                      Department, Job Title
--  Client Health       Last HW Scan, Last Policy Request,
--                      Last Heartbeat (DDR), Client Status
--
-- ============================================================
-- USAGE INSTRUCTIONS:
-- ============================================================
--
--  1. Open SQL Server Management Studio (SSMS)
--  2. Connect to the CAS database (CM_<SiteCode>)
--  3. Replace 'ABC00123' with your target Collection ID
--     (Find Collection ID from: SCCM Console >
--      Assets & Compliance > Device Collections >
--      Right-click Collection > Properties > General tab)
--  4. Execute the query
--  5. Export results via:
--     Right-click Results > Save Results As > CSV / Excel
--
-- ============================================================
-- CHANGE LOG:
-- ============================================================
--
--  Version   Date          Author            Change
--  -------   -----------   ---------------   --------------------
--  1.0       March 2026    Sethu Kumar B     Initial version
--
-- ============================================================

-- ▶ CONFIG: Replace with your actual Collection ID
DECLARE @CollectionID NVARCHAR(8) = N'CAS01490';

-- ============================================================
-- MAIN QUERY
-- ============================================================

SELECT
    -- Device Identity
    rs.Name0                            AS [Device Name],
    cs.Domain0                          AS [Domain],
    rs.AD_Site_Name0                    AS [AD Site],
    rs.Distinguished_Name0              AS [AD Distinguished Name],

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

FROM v_FullCollectionMembership fcm

-- Core device record
INNER JOIN v_R_System rs
    ON rs.ResourceID = fcm.ResourceID

-- Hardware & OS views
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

-- Client health summary
LEFT JOIN v_CH_ClientSummary ch
    ON rs.ResourceID = ch.ResourceID

-- AD User lookup via Employee ID (WDC-specific schema)
LEFT JOIN v_R_User usr
    ON usr.employeeID0 = rs.User_Name0

-- Collection scope filter
WHERE fcm.CollectionID = @CollectionID
  AND fcm.IsAssigned   = 1

ORDER BY rs.Name0 ASC;
