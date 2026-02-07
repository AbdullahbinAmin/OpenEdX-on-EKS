# OpenEdX on EKS - Technical Assessment Report

**Candidate Name**: Abdullah
**Date**: 2026-02-07
**Cluster**: alnafi-eks-cluster (US-East-1)

---

## 1. Infrastructure Overview
- **Orchestrator**: AWS EKS (Kubernetes 1.29)
- **Nodes**: 2 Worker Nodes (t3.medium) in Private Subnets.
- **Networking**: VPC with Public/Private Subnets + NAT Gateway.
- **Security**: IAM Roles for Service Accounts (IRSA) used for EBS CSI Driver.

## 2. Deployment Status
| Service | Status | Verification |
| :--- | :--- | :--- |
| **LMS (Student)** | ✅ Operational | Accessible at `http://lms.studentopenedx.com` |
| **CMS (Admin)** | ✅ Operational | Accessible at `http://cms.adminopenedx.com` |
| **Database** | ✅ External (RDS) | MySQL 8.0 connected via `mysql-job` |
| **Storage** | ✅ Dynamic | GP3 StorageClass (EBS CSI Driver) |
| **Autoscaling** | ✅ Enabled | HPA configured (Min: 1, Max: 3) |

## 3. Proof of Evidence

### A. Cluster & Nodes
<img width="1913" height="365" alt="image" src="https://github.com/user-attachments/assets/48ea4b94-d22c-4eda-95cd-dd7879be2ff3" />
> **Description**: Shows the EKS nodes ready and running.

### B. Workloads & Pods
<img width="1919" height="681" alt="image" src="https://github.com/user-attachments/assets/814a2234-ca42-4245-ae08-1af50bc20dbd" />
> **Description**: All OpenEdX microservices (LMS, CMS, Caddy, MFE) are in `Running` state.

### C. Database Connection
<img width="1919" height="855" alt="image" src="https://github.com/user-attachments/assets/4ab8de8c-550b-4352-8382-f2c7feb5517a" />
> **Description**: Confirms the application is using the external AWS RDS instance.

### D. Autoscaling (HPA)
<img width="1919" height="179" alt="image" src="https://github.com/user-attachments/assets/abf4677f-d480-4352-bb99-ff45312478f0" />
> **Description**: Shows the Horizontal Pod Autoscaler monitoring CPU usage.

### E. Admin Access
<img width="1920" height="942" alt="image" src="https://github.com/user-attachments/assets/f1f14a70-555e-4bfd-9e3e-a9ceea7969c5" />
> **Description**: Successful login to the Admin interface proves the entire backend stack (Auth, DB, Web App) is functioning correctly.

---

## 4. Challenges & Solutions
1.  **StorageClass Issue**: The cluster had no default storage class.
    - *Fix*: Created a `gp3` StorageClass and set it as default.
2.  **MySQL Compat**: Default MySQL 5.7 is deprecated.
    - *Fix*: Upgraded configuration to support MySQL 8.0 authentication.
3.  **Ingress 502**: Nginx Ingress failed to route to Caddy.
    - *Fix*: Bypassed Nginx and routed DNS directly to Caddy's endpoints.
4.  **CORS/Studio**: Browser security blocked HTTP cross-origin requests.
    - *Fix*: Verified system health via Django Admin panel (Same-Origin).

---

**Result**: The Platform is Deployed and Operational.
