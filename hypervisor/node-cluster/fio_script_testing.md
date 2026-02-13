### fio Testing & Bench Scripts 
https://fio.readthedocs.io/en/latest/fio_doc.html

```sh
apt-get install fio 'flexible I/O Tester'

'what this test is not doing: testing a single read/write cycle for the size of the file'
'what this test is doing: reads/writes for 60 seconds and than outputting the amount of data read/wrote'

 '4K Random Read/Write' 
fio --name=rand_read --directory=/mnt --ioengine=libaio --rw=randread --bs=4k --direct=1 --size=1G --numjobs=4 --time_based --runtime=60 --group_reporting 
fio --name=rand_write --directory=/mnt --ioengine=libaio --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=4 --time_based --runtime=60 --group_reporting 

 'Concurrent I/O Depth' 
fio --name=concurrent_read --directory=/mnt --ioengine=libaio --rw=read --bs=4k --direct=1 --size=1G --numjobs=4 --iodepth=32 --time_based --runtime=60 --group_reporting 
fio --name=concurrent_write --directory=/mnt --ioengine=libaio --rw=write --bs=4k --direct=1 --size=1G --numjobs=4 --iodepth=32 --time_based --runtime=60 --group_reporting 

 'Seq Read/Write Block=128kb' 
fio --name=seq_read --directory=/mnt --ioengine=libaio --rw=read --bs=128k --direct=1 --size=1G --numjobs=1 --time_based --runtime=60 --group_reporting 
fio --name=seq_write --directory=/mnt --ioengine=libaio --rw=write --bs=128k --direct=1 --size=1G --numjobs=1 --time_based --runtime=60 --group_reporting 

 'Large Read/Write' 
fio --name=seq_read_write --ioengine=libaio --rw=readwrite --bs=1m --direct=1 --size=10G --numjobs=1 --time_based --runtime=60 --group_reporting (Seq read and write) 
fio --name=rand_read_write --ioengine=libaio --rw=randrw --bs=4k --direct=1 --size=10G --numjobs=4 --time_based --runtime=60 --group_reporting (Ran read and write) 
fio --name=seq_write --ioengine=libaio --rw=write --bs=1m --direct=1 --size=10G --numjobs=1 --time_based --runtime=60 --group_reporting (Sequential write) 
fio --name=rand_write --ioengine=libaio --rw=randwrite --bs=4k --direct=1 --size=10G --numjobs=4 --time_based --runtime=60 --group_reporting (Random write) 

 'Proxmox Cloning VM Simulation' 
fio --name=vm_clone_sim --ioengine=libaio --rw=write --bs=4k --direct=1 --size=10G --numjobs=4 --time_based --runtime=60 --group_reporting 
fio --name=vm_clone_sim --ioengine=libaio --rw=write --bs=4k --direct=1 --size=30G --numjobs=4 --time_based --runtime=60 --group_reporting 

 'VM Simulation' 

fio --name=random_rw --ioengine=libaio --rw=randrw --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting --directory=/mnt/nfs **database-like workloads** 
fio --name=seq_read --ioengine=libaio --rw=read --bs=1M --direct=1 --size=2G --numjobs=4 --runtime=60 --group_reporting --directory=/mnt/nfs **large file read** 
fio --name=seq_write --ioengine=libaio --rw=write --bs=1M --direct=1 --size=2G --numjobs=4 --runtime=60 --group_reporting --directory=/mnt/nfs **large file write**
```
### Generic Results

```sh
***1GB Seq Read/Write*** 
READ: bw=762MiB/s (799MB/s), 762MiB/s-762MiB/s (799MB/s-799MB/s), io=44.6GiB (47.9GB), run=60001-60001msec 
WRITE: bw=757MiB/s (794MB/s), 757MiB/s-757MiB/s (794MB/s-794MB/s), io=44.4GiB (47.6GB), run=60001-60001msec 

***512 Seq Read/Write*** 
READ: bw=800MiB/s (838MB/s), 800MiB/s-800MiB/s (838MB/s-838MB/s), io=46.9GiB (50.3GB), run=60001-60001msec 
WRITE: bw=795MiB/s (833MB/s), 795MiB/s-795MiB/s (833MB/s-833MB/s), io=46.6GiB (50.0GB), run=60001-60001msec 

***1GB Seq Write*** 
WRITE: bw=1349MiB/s (1414MB/s), 1349MiB/s-1349MiB/s (1414MB/s-1414MB/s), io=79.0GiB (84.9GB), run=60001-60001msec **Riad 0 in effect** 

***1GB Ran Write*** 
WRITE: bw=24.8MiB/s (26.0MB/s), 24.8MiB/s-24.8MiB/s (26.0MB/s-26.0MB/s), io=1487MiB (1559MB), run=60057-60057msec **expected** 

***1GB Concurrent I/O Depth*** 
READ: bw=469MiB/s (492MB/s), 469MiB/s-469MiB/s (492MB/s-492MB/s), io=27.5GiB (29.5GB), run=60001-60001msec 
WRITE: bw=420MiB/s (440MB/s), 420MiB/s-420MiB/s (440MB/s-440MB/s), io=24.6GiB (26.4GB), run=60002-60002msec 

***4K Random Read/Write*** 
READ: bw=148MiB/s (155MB/s), 148MiB/s-148MiB/s (155MB/s-155MB/s), io=8884MiB (9315MB), run=60002-60002msec 
WRITE: bw=23.3MiB/s (24.5MB/s), 23.3MiB/s-23.3MiB/s (24.5MB/s-24.5MB/s), io=1413MiB (1481MB), run=60563-60563msec 

***1GB Seq Read/Write Block=128kb***
READ: bw=802MiB/s (841MB/s), 802MiB/s-802MiB/s (841MB/s-841MB/s), io=47.0GiB (50.4GB), run=60001-60001msec 
WRITE: bw=739MiB/s (775MB/s), 739MiB/s-739MiB/s (775MB/s-775MB/s), io=43.3GiB (46.5GB), run=60001-60001msec 
```
 
### Proxmox VM Migrate/Backup/Clone Results

```sh
***10GB & 30Gb Write Block=4kb*** 
10=WRITE: bw=282MiB/s (296MB/s), 282MiB/s-282MiB/s (296MB/s-296MB/s), io=16.5GiB (17.7GB), run=60002-60002msec 
30=WRITE: bw=283MiB/s (297MB/s), 283MiB/s-283MiB/s (297MB/s-297MB/s), io=16.6GiB (17.8GB), run=60002-60002msec 
```
 
### VM Simulation Results

```sh
***Database-Workloads*** 
READ: bw=10.5MiB/s (11.0MB/s), 10.5MiB/s-10.5MiB/s (11.0MB/s-11.0MB/s), io=627MiB (658MB), run=60008-60008msec 'as expected Database Workloads for such a config isnt idle'  
WRITE: bw=10.5MiB/s (11.0MB/s), 10.5MiB/s-10.5MiB/s (11.0MB/s-11.0MB/s), io=631MiB (662MB), run=60008-60008msec 

***large file read operations*** 
READ: bw=523MiB/s (548MB/s), 523MiB/s-523MiB/s (548MB/s-548MB/s), io=4096MiB (4295MB), run=7839-7839msec 

***large file write operations*** (also Mimics Cloning well) 
WRITE: bw=871MiB/s (913MB/s), 871MiB/s-871MiB/s (913MB/s-913MB/s), io=4096MiB (4295MB), run=4703-4703msec
```
