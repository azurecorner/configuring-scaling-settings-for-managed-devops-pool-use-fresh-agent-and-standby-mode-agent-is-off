
# Configuring Scaling Settings for Managed DevOps Pool : Fresh agent for every job and Standby Agents Mode is Off

To manage the performance and cost of your **Managed DevOps Pool**, I should configure the scaling settings appropriately. For more details on pricing and performance, refer to the official documentation:

 [Configure Scaling for Managed DevOps Pools](https://learn.microsoft.com/en-us/azure/devops/managed-devops-pools/configure-scaling?view=azure-devops&tabs=azure-portal)

## Scaling Configuration
In this tutorial, I have configured the **Azure DevOps Managed DevOps Pool** with the following scaling settings:
- **Pool Maximum Agents**: 5  
- **Agent State**: Fresh agent for every job  
- **Standby Agents Mode**: Off (agents are provisioned on-demand when jobs are queued)  
- **Parallel Jobs Capacity**: 5 (enabled)  
- **Running Builds**: 5

  ![scaling](https://github.com/user-attachments/assets/5d5356d9-55bc-4690-a95f-ffaffb128968)


With this setup, each build runs on a newly provisioned agent, ensuring a clean environment for execution. The use of **5 parallel self-hosted agents** allows all builds to queue simultaneously , as long as the number of concurrent builds does not exceed the available capacity.  

This configuration provides insights into key performance metrics such as **queue delay, build duration, and machine reuse**, which will be analyzed further to evaluate the overall efficiency of the setup.

## A.  WINDOWS : Azure Pipelines Windows Server 2022 image

###  Azure DevOps Build Analysis

## **1. Queue Delay (Queue Time → Start Time)**
Queue delay is the time between when a build is queued and when an agent starts running it.

| Build ID | Queue Time | Start Time | Queue Delay |
|----------|------------|------------|-------------|
| 1615     | 19:13:28   | 19:17:34   | **4 min 6 sec** |
| 1616     | 19:13:31   | 19:17:40   | **4 min 9 sec** |
| 1617     | 19:13:33   | 19:17:53   | **4 min 20 sec** |
| 1618     | 19:13:35   | 19:17:59   | **4 min 24 sec** |
| 1619     | 19:13:36   | 19:18:04   | **4 min 28 sec** |

 **Queue delay is consistently around 4 to 4.5 minutes**.  
This suggests that:
- **Fresh agent provisioning is the main bottleneck**.
- **No standby agents available** leads to **provisioning delay for every build**.

---

## **2. Build Duration (Start Time → Finish Time)**
Build duration is the time between when a build starts and when it completes.

| Build ID | Start Time | Finish Time | Build Duration |
|----------|------------|------------|---------------|
| 1615     | 19:17:34   | 19:18:58   | **1 min 24 sec** |
| 1616     | 19:17:40   | 19:19:04   | **1 min 24 sec** |
| 1617     | 19:17:53   | 19:19:17   | **1 min 24 sec** |
| 1618     | 19:17:59   | 19:19:38   | **1 min 39 sec** |
| 1619     | 19:18:04   | 19:19:37   | **1 min 33 sec** |

 **Most builds complete in ~1.5 minutes**, which is **much shorter than the queue delay**.  
 This confirms that **agent provisioning is a bigger issue than the build execution itself**.

---

## **3. Machine Reuse**
Since **Agent State = Fresh Agent Every Time** and **Standby Agents Mode = Off**, each build runs on a **brand new VM**.  
- **There is no machine reuse.**  
- **Every build waits for a new VM to be provisioned, causing a ~4-minute delay**.  

---

## **4. Key Takeaways**
 **Your builds are efficient once they start (~1.5 min per build).**  
**Queue delay (~4.5 min) is much longer than build time.**  
 **Fresh agent mode without standby agents is the root cause of high delays.**  

---



## B. UBUNTU : Azure Pipelines Ubuntu 22.04 image

### Azure DevOps Build Analysis (Ubuntu)

## **1. Queue Delay (Queue Time → Start Time)**
Queue delay is the time between when a build is queued and when an agent starts running it.

| Build ID | Queue Time | Start Time | Queue Delay |
|----------|------------|------------|-------------|
| 1620     | 19:33:31   | 19:35:39   | **2 min 8 sec** |
| 1621     | 19:33:33   | 19:35:49   | **2 min 16 sec** |
| 1622     | 19:33:35   | 19:36:02   | **2 min 27 sec** |
| 1623     | 19:33:37   | 19:36:36   | **2 min 59 sec** |
| 1624     | 19:33:38   | 19:36:17   | **2 min 39 sec** |

 **Queue delay is consistently around 2 to 3 minutes**, which is **shorter than the Windows queue delay (~4.5 min)**.  
This suggests that **Ubuntu agent provisioning is faster than Windows**.

---

## **2. Build Duration (Start Time → Finish Time)**
Build duration is the time between when a build starts and when it completes.

| Build ID | Start Time | Finish Time | Build Duration |
|----------|------------|------------|---------------|
| 1620     | 19:35:39   | 19:36:30   | **51 sec** |
| 1621     | 19:35:49   | 19:36:40   | **51 sec** |
| 1622     | 19:36:02   | 19:36:55   | **53 sec** |
| 1623     | 19:36:36   | 19:37:51   | **1 min 15 sec** |
| 1624     | 19:36:17   | 19:37:10   | **53 sec** |

 **Ubuntu builds complete faster (~50 sec) than Windows (~1.5 min).**  
 **Queue delay + build time is still dominated by agent provisioning.**

---

## **3. Machine Reuse**
Since **Agent State = Fresh Agent Every Time** and **Standby Agents Mode = Off**, each build runs on a **brand new VM**.  
- **There is no machine reuse.**  
- **Every build waits for a new VM to be provisioned, causing a ~2.5-minute delay**.

---

## **4. Key Takeaways**
 **Ubuntu builds are faster than Windows (~50 sec vs. ~1.5 min).**  
 **Queue delay is lower for Ubuntu (~2.5 min) compared to Windows (~4.5 min).**  
**Agent provisioning is still the main bottleneck.**  

---


## C. COMPARISON : Azure Pipelines Windows Server 2022 image vs   Azure Pipelines Ubuntu 22.04 image

### Windows vs Ubuntu Build Performance in Azure DevOps

## **1. Queue Delay (Queue Time → Start Time)**
Queue delay measures how long a build waits before execution.

| OS       | Build ID | Queue Time | Start Time | Queue Delay |
|----------|----------|------------|------------|-------------|
| **Windows** | 1615  | 19:13:28   | 19:17:34   | **4 min 6 sec** |
| **Windows** | 1616  | 19:13:31   | 19:17:40   | **4 min 9 sec** |
| **Windows** | 1617  | 19:13:33   | 19:17:53   | **4 min 20 sec** |
| **Windows** | 1618  | 19:13:35   | 19:17:59   | **4 min 24 sec** |
| **Windows** | 1619  | 19:13:36   | 19:18:04   | **4 min 28 sec** |
| **Ubuntu**  | 1620  | 19:33:31   | 19:35:39   | **2 min 8 sec** |
| **Ubuntu**  | 1621  | 19:33:33   | 19:35:49   | **2 min 16 sec** |
| **Ubuntu**  | 1622  | 19:33:35   | 19:36:02   | **2 min 27 sec** |
| **Ubuntu**  | 1623  | 19:33:37   | 19:36:36   | **2 min 59 sec** |
| **Ubuntu**  | 1624  | 19:33:38   | 19:36:17   | **2 min 39 sec** |

**Ubuntu has a much shorter queue delay (~2.5 min) than Windows (~4.3 min).**  
**Windows provisioning is slower, possibly due to OS startup overhead.**

---

## **2. Build Duration (Start Time → Finish Time)**
Build duration is the actual time a build takes to complete.

| OS       | Build ID | Start Time | Finish Time | Build Duration |
|----------|----------|------------|------------|---------------|
| **Windows** | 1615  | 19:17:34   | 19:18:58   | **1 min 24 sec** |
| **Windows** | 1616  | 19:17:40   | 19:19:04   | **1 min 24 sec** |
| **Windows** | 1617  | 19:17:53   | 19:19:17   | **1 min 24 sec** |
| **Windows** | 1618  | 19:17:59   | 19:19:38   | **1 min 39 sec** |
| **Windows** | 1619  | 19:18:04   | 19:19:37   | **1 min 33 sec** |
| **Ubuntu**  | 1620  | 19:35:39   | 19:36:30   | **51 sec** |
| **Ubuntu**  | 1621  | 19:35:49   | 19:36:40   | **51 sec** |
| **Ubuntu**  | 1622  | 19:36:02   | 19:36:55   | **53 sec** |
| **Ubuntu**  | 1623  | 19:36:36   | 19:37:51   | **1 min 15 sec** |
| **Ubuntu**  | 1624  | 19:36:17   | 19:37:10   | **53 sec** |

 **Ubuntu builds complete faster (~50 sec) compared to Windows (~1.5 min).**  
 **Ubuntu's lower queue delay + shorter build time make it more efficient overall.**

---

## **3. Key Differences**
| Metric            | Windows Avg. | Ubuntu Avg. |  Faster OS |
|------------------|-------------|------------|------------|
| **Queue Delay**   | **4 min 17 sec** | **2 min 30 sec** |  Ubuntu |
| **Build Duration** | **1 min 29 sec** | **54 sec** |  Ubuntu |
| **Total Time (Queue Delay + Build)** | **5 min 46 sec** | **3 min 24 sec** |  Ubuntu |

 **Ubuntu consistently outperforms Windows in queue delay and build duration.**  
 **Windows builds take ~2 min longer per build.**



