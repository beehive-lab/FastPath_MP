## Address Editor in Vivado 2015.4

The current version of FastPath_MP assumes 4 FPGA-based paths.

| Component    | Address           |
| ------------------- | ----------------|
| fastpath_submit_mp | 0x53C0_0000 |
| fastpath_complete_0 | 0x53C0_1000 |
| fastpath_complete_1 | 0x53C0_3000 |
| fastpath_complete_2 | 0x53C0_5000 |
| fastpath_complete_3 | 0x53C0_7000 |
| fastpath_controller_mp | 0x53C3_0000 |

## Address Mapped Interface per FastPath_MP component 

The current version of FastPath_MP assumes 4 FPGA-based paths.

| fastpath_controller_mp    | Address           |
| ------------------- | ----------------|
| FastPath_MP Locker (ctx_reg)        | 0x3_0004 |
| Descriptor for write request        | 0x3_0008 |
| Size for write request              | 0x3_000C |
| Descriptor for read request         | 0x3_0010 |
| Size for read request               | 0x3_0014 |
| Number of commands per total size   | 0x3_0018 |


| fastpath_submit_mp    | Address           |
| ------------------- | ----------------|
| Submission Queue Address for FastPath queue 0 | 0x0000 |
| Doorbell Address for FastPath queue 0 | 0x0004 |
| DMA Address for FastPath queues | 0x0008 |
| Submission Queue Address for FastPath queue 1 | 0x000C |
| Doorbell Address for FastPath queue 1 | 0x0010 |
| Submission Queue Address for FastPath queue 2 | 0x0014 |
| Doorbell Address for FastPath queue 2 | 0x0018 |
| Submission Queue Address for FastPath queue 3 | 0x001C |
| Doorbell Address for FastPath queue 3 | 0x0020 |


| fastpath_complete    | Address           |
| ------------------- | ----------------|
| Completion Queue Address | 0x0000 |
