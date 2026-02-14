## DFS-R Wiki:

**Samba in its current state doesn't support SysVol replication via `DFS-R` (`Distributed File System Replication`) or the older `FRS` (`File Replication Service`) used in Windows Server 2000/2003 for Sysvol replication. You need to sync idmap.ldb from the DC holding the `PDC_Emulator` `FSMO` role to all other `DCs`.** This ensures that all DCs will use the same IDs. If you do not sync idmap.ldb, you can and will get different IDs on each DC. You need to sync idmap.ldb when you first join a new DC and then regularly, to ensure the IDs remain constant. You do not need to sync idmap.ldb every time you sync SysVol, but as stated, it should be done periodically.

**Everything stored inside the `AD` is replicated between `DCs`. For example: users, groups, and DNS records. In the current state, Samba does not support the distributed file system replication (`DFS-R`) protocol used for Sysvol replication.** its often viewed as a subfunction of DFS, and both are often used together, but they can also be used completely separately: DFS with multiple targets can be used without DFS-R (`if the folder contents are updated with some other method`), and DFS-R can replicate shared folders that are not DFS-targets.

**Everything stored inside the AD is replicated between DCs. For example: users, groups, and DNS records. In the current state, Samba does not support the distributed file system replication (`DFS-R`) protocol used for Sysvol replication.** You can't use another distributed filesystem like `GlusterFS` or `Lustre` for `SysVol` Replication because a cluster file system with Samba requires `CTDB` to be able to do it safely. And `CTDB` and AD DC are incompatible.


## Key Features:

- ***Data Synchronization*** -  DFS-R (Distributed File System Replication) allows for efficient data replication between Samba servers, ensuring consistency across multiple servers.
- ***Resilience and Redundancy*** - Provides fault tolerance by replicating data across different servers, enhancing data availability and reliability.
- ***Bandwidth Optimization*** - Uses remote differential compression to minimize the amount of data sent over the network during replication, optimizing bandwidth usage.
- ***Automatic Recovery*** - Capable of automatic recovery from interruptions, ensuring data integrity and continuity.


## Best Practice:

- Samba doesn't have a direct way of performing DFS-R. The best practice here depends on the environment, use case, as well as security policies and framework set in place. Once you have that, you may perform SysVol replication via one of the following:

   - Rsync based SysVol replication workaround (Samba DCs only): Quick setup, easy to configure.
   - Bidirectional Rsync/Unison based SysVol replication workaround (Samba DCs only): Complex, requires a third-party script, each DC requires a cron job against each other DC.
   - Bidirectional Rsync/osync based SysVol replication workaround (Samba DCs only): Complex, requires a third-party script, each DC requires a cron job against each other DC.
   - Robocopy based SysVol replication workaround (Samba DCs -> Windows DCs): Quick setup, easy to configure, uses MS Robocopy.



##
 > `TDB` files and `LDB` files using TDB have a maximum size of 4 GB because the databases use 32-bit structures. Previously, there was a project called NTDB that should address the size limit and other problems. However, the project has been stopped because of problems migrating the databases. `LDB` files based on LMDB, specifically the sam.ldb on the AD DC, have a size specified by the --backend-store-size=SIZE parameter to samba-tool domain provision and samba-tool domain join which controls the maximum DB size. The default is 8GB. As LMDB is a true 64-bit database, the maximum is limited only by the storage available on the system.