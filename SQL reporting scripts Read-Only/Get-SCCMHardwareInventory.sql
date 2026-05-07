/*
===============================================================================
Script Name : Get-SCCMHardwareInventory.sql
Author      : Sethu Kumar B
Purpose     : Retrieve hardware inventory details for Windows workstation
              devices from SCCM.
Environment : Microsoft SCCM / MECM SQL Database
Type        : Read-Only
===============================================================================
*/

-- ============================================================================
-- TABLE 1: Device-Level Hardware Inventory
-- ============================================================================

SELECT
    rs.Name0 AS ComputerName,
    rs.ResourceID,
    bios.SerialNumber0 AS SerialNumber,
    cs.Manufacturer0 AS Manufacturer,
    cs.Model0 AS Model,
    cpu.Name0 AS ProcessorName,
    CAST(cs.TotalPhysicalMemory0 / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS TotalMemoryGB,
    os.Caption0 AS OperatingSystem,
    os.Version0 AS OSVersion,
    os.BuildNumber0 AS BuildNumber,
    rs.User_Name0 AS LastLoggedOnUser,
    rs.AD_Site_Name0 AS ADSite,
    rs.Distinguished_Name0 AS ADDistinguishedName

FROM v_R_System rs

LEFT JOIN v_GS_PC_BIOS bios
    ON bios.ResourceID = rs.ResourceID

LEFT JOIN v_GS_COMPUTER_SYSTEM cs
    ON cs.ResourceID = rs.ResourceID

LEFT JOIN v_GS_PROCESSOR cpu
    ON cpu.ResourceID = rs.ResourceID

LEFT JOIN v_GS_OPERATING_SYSTEM os
    ON os.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

ORDER BY
    rs.Name0;


-- ============================================================================
-- TABLE 2: Hardware Model Summary
-- ============================================================================

SELECT
    cs.Manufacturer0 AS Manufacturer,
    cs.Model0 AS Model,
    COUNT(DISTINCT rs.ResourceID) AS DeviceCount

FROM v_R_System rs

LEFT JOIN v_GS_COMPUTER_SYSTEM cs
    ON cs.ResourceID = rs.ResourceID

WHERE
    rs.Operating_System_Name_and0 LIKE '%workstation%'

GROUP BY
    cs.Manufacturer0,
    cs.Model0

ORDER BY
    DeviceCount DESC;