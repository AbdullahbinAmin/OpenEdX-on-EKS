Technical Assessment: Production-Grade OpenEdX Deployment on AWS EKS
====================================================================

Overview
--------

This documentation provides a comprehensive, step-by-step guide for deploying a production-ready OpenEdX Learning Management System (LMS) on AWS EKS. This project is a mandatory hiring test for Al Nafi's 2026 global expansion, focusing on real execution capability. The goal is to demonstrate architectural clarity and enterprise discipline by utilizing AWS-managed services, secure traffic management, and automated scalability.

* * * * *

Prerequisites
-------------

-   **AWS Account:** All operations must be performed strictly on AWS.

-   **Technical Knowledge:** Familiarity with AWS EKS, Kubernetes, and Tutor.

-   **Tools:** AWS CLI, `kubectl`, `tutor`, and `helm` installed on a local machine or bastion host.

* * * * *

Step-by-Step Implementation
---------------------------

### Step 1: AWS Account and Admin User Setup

**Purpose of the Step:** To establish a secure administrative foundation for AWS resource management. **Detailed Explanation:** Instead of using the insecure Root account, a dedicated `admin-user` is created to handle all subsequent tasks. This follows the principle of least privilege.

-   **Actions:**

    1.  Log into the AWS Console as Root.

    2.  Create an IAM user named `admin-user`.

    3.  Attach the `AdministratorAccess` policy to this user.

    4.  Generate **Access Keys** for Command Line Interface (CLI) use. **Notes:** Ensure you download the `.csv` file containing the Secret Access Key immediately; it will not be shown again.

* * * * *

### Step 2: Configure AWS CLI

**Purpose of the Step:** To link your local terminal to your AWS account. **Detailed Explanation:** Configuring the CLI allows you to run commands that create and manage AWS resources directly from your computer.

-   **Commands:**

    Bash

    ```
    aws configure

    ```

    Enter your Access Key ID, Secret Access Key, Default region (`us-east-1`), and output format (`json`). **Notes:** After configuration, verify your identity using `aws sts get-caller-identity` to ensure you are no longer using the Root account.

* * * * *

### Step 3: Network Infrastructure Preparation (VPC)

**Purpose of the Step:** To build the "roads and buildings" for your cluster. **Detailed Explanation:** Using the "VPC and more" wizard in the AWS Console, you create an isolated network environment.

-   **Actions:**

    1.  Create a VPC named `alnafi-eks`.

    2.  Select **2 Availability Zones**.

    3.  Configure **2 Public subnets** and **2 Private subnets**.

    4.  Set up **1 NAT Gateway** (in 1 AZ) to allow private resources to access the internet safely.

    5.  Enable DNS hostnames and resolution.

* * * * *

### Step 4: Create IAM Roles for EKS

**Purpose of the Step:** To give Kubernetes the necessary permissions to interact with AWS services. **Detailed Explanation:** Two distinct roles are required: one for the Cluster (the brain) and one for the Nodes (the workers).

-   **Actions:**

    1.  **Cluster Role:** Create a role for the "EKS - Cluster" service with `AmazonEKSClusterPolicy`. Name it `Alnafi-EKS-Cluster-Role`.

    2.  **Node Role:** Create a role for the "EC2" service with `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, and `AmazonEKS_CNI_Policy`. Name it `Alnafi-EKS-Node-Role`.

* * * * *

### Step 5: Provision the EKS Cluster

**Purpose of the Step:** To launch the managed Kubernetes control plane. **Detailed Explanation:** This step creates the "Brain" of the system that will manage your OpenEdX containers.

-   **Actions:**

    1.  In the EKS console, create a cluster named `alnafi-cluster`.

    2.  Select the `Alnafi-EKS-Cluster-Role`.

    3.  Attach it to the `alnafi-eks-vpc` and its subnets.

    4.  Set the Cluster endpoint access to **Public**. **Notes:** This process typically takes 10 to 15 minutes to reach an "Active" state.

* * * * *

### Step 6: Install Local Control Tools (kubectl & Helm)

**Purpose of the Step:** To install the software needed to manage the cluster. **Detailed Explanation:** `kubectl` is the primary tool for Kubernetes, and `Helm` is used for package management.

-   **Commands:**

    1.  Download and install `kubectl`.

    2.  Install `Helm` using the official automated script:

        Bash

        ```
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

        ```

* * * * *

### Step 7: Connect Terminal to EKS Cluster

**Purpose of the Step:** To authorize your terminal to send commands to the new cluster. **Detailed Explanation:** Updating the `kubeconfig` file links your local `kubectl` to the AWS EKS cluster.

-   **Commands:**

    Bash

    ```
    aws eks update-kubeconfig --region us-east-1 --name alnafi-cluster

    ```

**Notes:** Verify the connection by running `kubectl get nodes`. You should see your worker nodes listed as "Ready."

* * * * *

### Step 8: Install Nginx Ingress Controller

**Purpose of the Step:** To manage incoming web traffic and replace the default Caddy server. **Detailed Explanation:** Nginx acts as the reverse proxy and entry point for all OpenEdX services.

-   **Commands:**

    Bash

    ```
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

    ```

**Notes:** This step triggers the creation of an AWS Load Balancer. Use `kubectl get svc -n ingress-nginx` to find your Load Balancer's external DNS.

* * * * *

### Step 9: Install Tutor and tutor-k8s Plugin

**Purpose of the Step:** To install the OpenEdX management software. **Detailed Explanation:** Tutor is used to configure and deploy OpenEdX, while the `tutor-k8s` plugin enables Kubernetes support.

-   **Commands:**

    1.  Install pip: `sudo dnf install -y python3-pip`

    2.  Install Tutor: `pip3 install "tutor[full]"`

    3.  Install Plugin: `pip3 install tutor-k8s`

* * * * *

### Step 10: Provision External Database Server (Offloaded)

**Purpose of the Step:** To host databases outside of Kubernetes as per mandatory requirements. **Detailed Explanation:** A dedicated EC2 instance is created to host MySQL, MongoDB, Redis, and Elasticsearch.

-   **Actions:**

    1.  Launch an Ubuntu EC2 instance (`t3.large`) named `alnafi-db-server`.

    2.  Place it in a **Private Subnet**.

    3.  Configure a Security Group (`alnafi-db-sg`) allowing **All TCP** from the VPC range (`10.0.0.0/16`).

    4.  Install Docker on this server and use `docker-compose` to run MySQL, MongoDB, Redis, and Elasticsearch.

* * * * *

### Step 11: Configure Tutor for External Databases

**Purpose of the Step:** To point the OpenEdX application to the external database server. **Detailed Explanation:** You must disable internal databases in Tutor and provide the IP address of your `alnafi-db-server`.

-   **Commands:**

    Bash

    ```
    tutor config save\
      --set MYSQL_HOST=[DB-SERVER-IP]\
      --set RUN_MYSQL=false\
      --set RUN_MONGODB=false\
      --set RUN_REDIS=false\
      --set RUN_ELASTICSEARCH=false

    ```

    (Followed by equivalent sets for MongoDB, Redis, and Elasticsearch).

* * * * *

### Step 12: Deployment and Security (CloudFront & WAF)

**Purpose of the Step:** To deploy the app and add a global security/performance layer. **Detailed Explanation:** Run `tutor k8s launch` to deploy the pods. Then, create an AWS CloudFront distribution pointing to your Nginx Load Balancer.

-   **Actions:**

    1.  Set Viewer Protocol Policy to **Redirect HTTP to HTTPS**.

    2.  Enable **AWS WAF** protections on the distribution.

    3.  Set Cache Policy to **CachingDisabled** to avoid session issues.

* * * * *

### Step 13: Enable Scaling (HPA) and Monitoring

**Purpose of the Step:** To ensure high availability and observability. **Detailed Explanation:** The Metrics Server must be installed for Kubernetes to understand when to scale the LMS and CMS pods.

-   **Commands:**

    1.  Install Metrics Server: `kubectl apply -f [metrics-server-url]`

    2.  Enable HPA: `kubectl autoscale deployment lms -n openedx --cpu-percent=50 --min=1 --max=3`

* * * * *

Final Summary
-------------

This project successfully transitions a standard OpenEdX installation into an enterprise-grade AWS EKS deployment. By offloading databases to dedicated infrastructure, implementing Nginx as the Ingress Controller, and layering AWS WAF and CloudFront for security, the platform is now ready for production use and global scaling.
