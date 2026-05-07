/*
===============================================================================
Script Name : Get-MBAMBitLockerRecoveryKeys.sql
Author      : Sethu Kumar B
Purpose     : Retrieve BitLocker recovery key information from the
              MBAM / BitLocker Recovery database.
Environment : Microsoft MBAM / BitLocker Recovery Database
Type        : Read-Only
===============================================================================

Description:
- Retrieves BitLocker recovery key information for devices
- Displays:
    - Device name
    - Volume ID
    - Recovery key
    - Recovery key ID
    - Last update time

Use Cases:
- BitLocker recovery operations
- Device recovery troubleshooting
- Security audit validation
- Recovery key verification
- MBAM database investigations

Main Tables Used:
- RecoveryAndHardwareCore.Machines
- RecoveryAndHardwareCore.Machines_Volumes
- RecoveryAndHardwareCore.Keys

Important Notes:
- Recovery keys are sensitive security information
- Access should be restricted to authorized administrators only
- Optional filters are available for:
    - Specific Recovery Key ID
    - Specific device name

===============================================================================
*/

SELECT

    -- Device hostname
    m.Name,

    -- BitLocker volume identifier
    mv.VolumeId,

    -- Last recovery key update timestamp
    k.LastUpdateTime,

    -- BitLocker recovery key
    k.RecoveryKey,

    -- Recovery key unique identifier
    k.RecoveryKeyId

FROM RecoveryAndHardwareCore.Machines m

-- Join device volumes
JOIN RecoveryAndHardwareCore.Machines_Volumes mv
    ON m.Id = mv.MachineId

-- Join recovery key information
JOIN RecoveryAndHardwareCore.Keys k
    ON mv.VolumeId = k.VolumeId

/*
===============================================================================
OPTIONAL FILTERS
Uncomment as needed
===============================================================================

-- Filter by specific Recovery Key ID
WHERE k.RecoveryKeyId = '4c007194-a526-40b6-bbf5-531dd30417fc'

-- Filter by specific device name
WHERE m.Name = 'J6NDW33'

*/

ORDER BY

    -- Latest recovery key updates first
    k.LastUpdateTime DESC;