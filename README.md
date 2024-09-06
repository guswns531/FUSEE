# FUSEE Setup and Performance Testing

This project details the process of setting up and testing FUSEE (Fully Memory-Disaggregated Key-Value Store) on multiple nodes, using Infiniband for network communication and YCSB workloads for benchmarking. The setup focuses on efficient memory usage, hugepages, and performance tests for latency and throughput.

## Node Information

The following nodes are used for testing:

- **inv03**: Client node 1
- **inv05**: Client node 2
- **inv06**: Server node 1
- **inv07**: Server node 2

## Initial Setup (Single Node)

1. Navigate to the setup directory and run the environment preparation script:
   ```bash
   cd setup
   bash setup-env-prepare.sh
   ```

2. If installing Miniforge on a single node, you will be prompted to accept the license and confirm the installation location. Follow these instructions:
   ```
   Do you accept the license terms? [yes|no] 
   => yes
   Mambaforge will now be installed into this location:
   /home/hjang/mambaforge
   - Press ENTER to confirm the location
   => ENTER
   You can undo this by running `conda init --reverse $SHELL`? [yes|no]
   => yes
   ```

3. Download the workload:
   ```bash
   cd setup
   sh download_workload.sh
   ```

## Package Installation on All Nodes

Run the following commands on each node to install the necessary packages:
```bash
cd setup
bash setup-env-install.sh
```

Note: The installed MLNX_OFED version is **MLNX_OFED_LINUX-4.9-5.1.0.0**, which supports **ConnectX-3**.

https://docs.nvidia.com/networking/display/mlnxofedv495100/introduction

> As of MLNX_OFED version v5.1-0.6.6.0, the following are no longer supported.     
> ConnectX-3   
> ConnectX-3 Pro   
> Connect-IB   
> RDMA experimental verbs libraries (mlnx_lib)   
> To utilize the above devices/libraries, refer to version 4.9 long-term support (LTS).


## Infiniband Testing

1. Run the following tests on **inv06** (server) and **inv03** (client):
   ```
   # inv06 server
   ib_send_lat
   ib_atomic_lat

   # inv03 client
   ib_send_lat inv06
   ib_atomic_lat inv06
   ```

2. Check for any CPU frequency issues:
   ```
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

## Compile FUSEE on Single Node - inv06)

1. Compile FUSEE:
   ```bash
   mkdir build && cd build
   /usr/local/bin/cmake ..
   make -j
   ```

2. For debug mode:
   ```bash
   cd ..
   rm -rf build
   mkdir build && cd build
   /usr/local/bin/cmake -DCMAKE_CXX_FLAGS="-D_DEBUG" --build ..
   make -j
   ```

## Running the Server for Memory Mode (inv06, inv07)

1. Configure and run the server on **inv06**:
   ```bash
   sudo su
   echo 7168 > /proc/sys/vm/nr_hugepages
   mkdir -p /data/hjang
   cp -rp /home/hjang/storage/FUSEE/build/ /data/hjang
   cd /data/hjang/build
   cp /home/hjang/storage/FUSEE/server_config1.json /data/hjang/build/server_config.json
   numactl -N 0 -m 0 ./ycsb-test/ycsb_test_server 0 
   ```

2. Configure and run the server on **inv07**:
   ```bash
   sudo su
   echo 7168 > /proc/sys/vm/nr_hugepages
   mkdir -p /data/hjang
   cp -rp /home/hjang/storage/FUSEE/build/ /data/hjang
   cd /data/hjang/build
   cp /home/hjang/storage/FUSEE/server_config2.json /data/hjang/build/server_config.json
   numactl -N 0 -m 0 ./ycsb-test/ycsb_test_server 1
   ```

### Server Output Example

- **inv06**:
  ```
  ===== Starting Server 0 =====
  kv_area_addr: 18000000, block_size: 4000000
  my_sid_: 0, num_memory_: 2
  num_rep_blocks: 26, num_blocks: 26, limit: 90000000
  press to exit
  ===== Ending Server 0 =====
  ```

- **inv07**:
  ```
  ===== Starting Server 1 =====
  kv_area_addr: 18000000, block_size: 4000000
  my_sid_: 1, num_memory_: 2
  num_rep_blocks: 26, num_blocks: 26, limit: 90000000
  press to exit
  ===== Ending Server 1 =====
  ```

## Running the Client for Computing node (inv03, inv05)

### Prepare Client for Computing node (inv03, inv05) 
1. Configure and run the client on **inv03**:
   ```bash
   sudo su
   echo 2048 > /proc/sys/vm/nr_hugepages
   mkdir -p /data/hjang
   cp -rp /home/hjang/storage/FUSEE/build/ /data/hjang
   cp /home/hjang/storage/FUSEE/client_config1.json /data/hjang/build/client_config.json
   cd /data/hjang/build
   ```

2. Configure and run the client on **inv05**:
   ```bash
   sudo su
   echo 2048 > /proc/sys/vm/nr_hugepages
   mkdir -p /data/hjang
   cp -rp /home/hjang/storage/FUSEE/build/ /data/hjang
   cp /home/hjang/storage/FUSEE/client_config2.json /data/hjang/build/client_config.json
   cd /data/hjang/build
   ```

### Micro Latency Test (inv03)

1. Run the micro latency test:
   ```bash
   mkdir results
   numactl -N 0 -m 0 ./micro-test/latency_test_client ./client_config.json
   ```

2. Results will be saved in the `./results` directory.

### Micro Throughput Test (inv03, inv05)

Run the micro throughput test simultaneously on **inv03** and **inv05**:
```bash
numactl -N 0 -m 0 ./micro-test/micro_test_multi_client ./client_config.json 4
```

Output example:
- **inv03**:
  ```
  insert total: 257140 ops
  insert failed: 0 ops
  insert tpt: 514280 ops/s
  ```

- **inv05**:
  ```
  insert total: 251175 ops
  insert failed: 0 ops
  insert tpt: 502350 ops/s
  ```

## YCSB Workload Testing (inv03)

1. Copy workload files to **inv03**:
   ```bash
   cp -rp /home/hjang/storage/FUSEE/setup/workloads /data/hjang/build/ycsb-test/workloads
   cp /home/hjang/storage/FUSEE/ycsb-test/split-workload-ycsb.py /data/hjang/build/ycsb-test/
   cd /data/hjang/build/ycsb-test
   ```

2. Run the YCSB workload:
   ```bash
   python split-workload-ycsb.py 4
   numactl -N 0 -m 0 ./ycsb_test_multi_client ../client_config.json workloada 4
   ```

Output example:
```
thread: 0 128871 ops/s
thread: 1 133409 ops/s
total: 5229704 ops
tpt: 522970 ops/s
```

# FUSEE: A Fully Memory-Disaggregated Key-Value Store


This is the implementation repository of our FAST'23 paper: **FUSEE: A Fully Memory-Disaggregated Key-Value Store**.



## Description

We proposes ***FUSEE***, a <em><strong>FU</strong>lly memory-di<strong>S</strong>aggr<strong>E</strong>gated</em> KV Stor***E*** that brings disaggregation to metadata management. *FUSEE* replicates metadata, *i.e.*, the index and memory management information, on memory nodes, manages them directly on the client side, and handles complex failures under the DM architecture. To scalably replicate the index on clients, *FUSEE* proposes a client-centric replication protocol that allows clients to concurrently access and modify the replicated index. To efficiently manage disaggregated memory, *FUSEE* adopts a two-level memory management scheme that splits the memory management duty among clients and memory nodes. Finally, to handle the metadata corruption under client failures, *FUSEE* leverages an embedded operation log scheme to repair metadata with low log maintenance overhead.


## Environment

* For hardware, each machine should be equipped with one **8-core Intel processer**(*e.g.*, Intel Xeon E5-2450),  **16GB DRAM**  and one **RDMA NIC card** (*e.g.*, Mellanox ConnectX-3). Each RNIC should be connected to an **Infiniband or Ethernet switch** (*e.g.*, Mellanox SX6036G). All machines are separated into memory nodes and compute nodes. At maximum 5 memory nodes and 17 compute nodes are used for the experiments in our paper. If you do not have such testbed, consider using [CloudLab](https://www.cloudlab.us/).

* For software, **Ubuntu 18.04** is recommended for each machine.  In our experiments, **7168 HugePages** of 2MB size in each memory node and **2048** ones in compute nodes is need to be allocated. You can set up this with  `echo 7168 > /proc/sys/vm/nr_hugepages` command for memory nodes and `echo 2048 > /proc/sys/vm/nr_hugepages` for compute nodes.



## Configurations

Configuration files for servers and clients should be provided to the program. Here are two example configuration files below.

#### 1. Servers configuration

For each memory node, you should provide a configuration file `server_config.json`  where you can flexibly configure the server:

```json
{
    "role": "SERVER",
    "conn_type": "IB",
    "server_id": 0,
    "udp_port": 2333,
    "memory_num": 3,
    "memory_ips": [
        "10.10.10.1",
        "10.10.10.2",
        "10.10.10.3"
    ],
    "ib_dev_id": 0,
    "ib_port_id": 1,
    "ib_gid_idx": 0,

    "server_base_addr":  "0x10000000",
    "server_data_len":   15032385536,
    "block_size":        67108864,
    "subblock_size":     256,
    "client_local_size": 1073741824,

    "num_replication": 3,

    "main_core_id": 0,
    "poll_core_id": 1,
    "bg_core_id": 2,
    "gc_core_id": 3
}
```

For briefness, we call each memory node as "server `i`" (`i` = 0, 1, ...).

#### 2. Clients configuration

For each compute node, you should provide a configuration file `client_config.json` where you can flexibly configure the client:

```json
{
    "role": "CLIENT",
    "conn_type": "IB",
    "server_id": 2,
    "udp_port": 2333,
    "memory_num": 2,
    "memory_ips": [
        "128.110.96.102",
        "128.110.96.81"
    ],
    "ib_dev_id": 0,
    "ib_port_id": 1,
    "ib_gid_idx": 0,

    "server_base_addr":  "0x10000000",
    "server_data_len":   15032385536,
    "block_size":        67108864,
    "subblock_size":     1024,
    "client_local_size": 1073741824,

    "num_replication": 2,
    "num_idx_rep": 1,
    "num_coroutines": 10,
    "miss_rate_threash": 0.1,
    "workload_run_time": 10,
    "micro_workload_num": 10000,

    "main_core_id": 0,
    "poll_core_id": 1,
    "bg_core_id": 2,
    "gc_core_id": 3
}
```

For briefness, we call each compute node as "client `i`" (`i` = 0, 1, 2, ...).

It should be noted that, the `server_id` parameter of client `i` should be set to `2+i*8`. For example, the `server_id` of the first three client is 2, 10, 18 respectively.



## Experiments

For each node, execute the following commands to compile the entire program:

```shell
mkdir build && cd build
cmake ..
make -j
```

We test *FUSEE* with **micro-benchmark** and **YCSB benchmarks** respectively. For each experiments, you should put `server_config.json` in directory `./build`, and then use the following command in memory nodes to set up servers:

```shell
numactl -N 0 -m 0 ./ycsb-test/ycsb_test_server [SERVER_NUM]
```

`[SERVER_NUM]` should be the serial number of this memory node, counting from 0.



#### 1. Micro-benchmark

* **Latency**

    To evaluate the latency of each operation, we use a single client to iteratively execute each operation (**INSERT**, **DELETE**, **UPDATE**, and **SEARCH**) for 10,000 times.

    Enter `./build/micro-test` and use the following command in client `0`：

    ```shell
    numactl -N 0 -m 0 ./latency_test_client [PATH_TO_CLIENT_CONFIG]
    ```

    Test results will be saved in `./build/micro-test/results`.

* **Throughput**

    To evaluate the throughput of each operations, each client first iteratively INSERTs different keys for 0.5 seconds. UPDATE and SEARCH operations are then executed on these keys for 10 seconds. Finally, each client executes DELETE for 0.5 seconds.

    Enter `./build/micro-test` and execute the following command on all client nodes at the same time:

    ```shell
    numactl -N 0 -m 0 ./micro_test_multi_client [PATH_TO_CLIENT_CONFIG] 8
    ```

    Number `8` indicates there are 8 client threads in each client node. You will need to use the keyboard to simultaneously send space signals to each client node for starting each operation testing synchronously.

    Test results will be displayed on each client terminal.



#### 2. YCSB benchmarks 

* **Workload preparation**

    Firstly, download all the testing workloads using `sh download_workload.sh` in directory `./setup` and unpack the workloads you want to `./build/ycsb-test/workloads`.

    Here is the description of the YCSB workloads:

    | Workload | SEARCH | UPDATE | INSERT |
    | -------- | ------ | ------ | ------ |
    | A        | 0.5    | 0.5    | 0      |
    | B        | 0.95   | 0.95   | 0      |
    | C        | 1      | 0      | 0      |
    | D        | 0.95   | 0      | 0.05   |
    | upd[X]   | 1-[X]% | [X]%   | 0      |

    Then, you should execute the following command in `./build/ycsb-test` to split the workloads into N parts(N is the total number of client threads):

    ```shell
    python split-workload.py [N]
    ```

    And then we can  start testing *FUSEE* using YCSB benchmarks.

* **Throughput**

    To show the **scalability** of *FUSEE*，we can test the throughput of *FUSEE* with different number of client nodes. Besides, we can evaluate the **read-write performance** of *FUSEE* by testing the throughput of *FUSEE* using workloads with different search-update ratios `X`. Here is the command of testing the throughput of *FUSEE*:

    ```shell
    numactl -N 0 -m 0 ./ycsb_test_multi_client [PATH_TO_CLIENT_CONFIG] [WORKLOAD-NAME] 8
    ```

    Execute the command on all the client nodes at the same time. `[WORKLOAD-NAME]` can be chosen from `workloada ~ workloadd` or `workloadudp0 ~ workloadudp100` (indicating different search-update ratios) .  Number `8` indicates there are 8 client threads in each client node. You will need to use the keyboard to simultaneously send space signals to each client node for starting each operation testing synchronously.

    Test results will be displayed on each client terminal.


