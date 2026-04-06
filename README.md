# Project ISAAC 🚀

While awaiting the arrival of my son, Isaac, I decided to name my new data architecture project in his honor.

**Project ISAAC** is an End-to-End data platform on AWS, focused on solving real-world challenges in scalability and software engineering applied to data. The choice of the name reflects precision and the force of expected impact — echoing both the principles of Isaac Newton and my journey into fatherhood.

## 🎯 Project Rationale & Market Opportunity

This project was born out of the consolidation of my profile as a **Senior Data Engineer**. The focus is no longer just writing scripts to move data, but **designing Scalable Architectures** and minimizing human intervention through automation and software engineering.

In this platform, we apply practices demanded by the market (and by certifications such as *AWS Certified Data Engineer*), consolidating:
- Native Cloud Integration (AWS Ecosystem via IAM).
- Stable Processing for Big Data.
- Quality and Consistency (Data Contracts).
- Self-managed Infrastructure (DevOps and FinOps).

## 🛠️ Technology Stack

- **Cloud Provider:** Amazon Web Services (AWS)
- **Data Lake (Storage):** AWS S3 (Raw, Trusted, and Refined Layers)
- **Distributed Processing:** PySpark via AWS Glue
- **Analytics Engineering & Quality:** dbt (Data Build Tool)
- **Serving Layer:** Amazon Athena
- **Orchestration:** AWS Step Functions + EventBridge Scheduler
- **Infrastructure as Code (IaC):** Terraform
- **CI/CD:** GitHub Actions (Automated Deployment focused on DevOps)

## 🏛️ Architecture Decisions

This section documents the key design rationale driving this platform's architecture — the kind of decisions that separate a production-grade system from an academic exercise.

### dbt vs. Gold Refresher Lambda: Two Tools, Two Responsibilities

One of the most nuanced design patterns in this project is the intentional **dual-layer approach** to Gold table materialization:

| Layer | Tool | Trigger | Purpose |
|---|---|---|---|
| **Deployment** | `dbt-core` (GitHub Actions) | `git push` to `master` | Validates SQL logic, enforces Data Contracts (`not_null`, `unique`), and initializes Gold tables on first deploy |
| **Scheduling** | Gold Refresher Lambda (Step Functions) | Daily cron via EventBridge | Re-executes the same Athena CTAS queries to refresh Gold data with newly ingested records — zero infrastructure required |

**Why not run dbt daily?** Running `dbt-core` on a schedule would require either a dedicated EC2 instance (~$15-30/month) or a containerized ECS task — both breaking the project's FinOps-first principle. The Gold Refresher Lambda executes equivalent SQL via `boto3` + `Athena StartQueryExecution` for fractions of a cent per run.

**The architect's metaphor:** dbt is the *architect* — it draws the blueprints, enforces quality standards, and builds the structure initially. The Lambda is the *caretaker* — it refreshes the data daily without re-validating the entire structure.

### Airflow vs. AWS Step Functions

The original roadmap referenced Apache Airflow for orchestration. After evaluating the trade-offs, **AWS Step Functions** was selected:

| Dimension | Apache Airflow (MWAA/EC2) | AWS Step Functions |
|---|---|---|
| Infrastructure | Always-on server required | 100% Serverless |
| Cost | ~$15-30/month (idle time) | ~$0.09/month (pay per state transition) |
| Visual DAG | Airflow UI | Native AWS Console |
| AWS Integration | Operators + plugins | Native SDK (Lambda, Glue, SNS) |

Step Functions delivers the same visual DAG and error-handling capabilities while remaining fully aligned with the project's Serverless and FinOps principles.

## 🗺️ Step-by-Step Execution Plan

The execution is planned incrementally to ensure sustainable complexity evolution:

- **Step 1: Terraform Foundation (Completed) ✔️**
  - Initial implementation of Infrastructure as Code (IaC).
  - AWS provider setup in an environment-agnostic way (uses Local Profile on desktop, and Secrets Injection [IAM OIDC/EnvVars] in GitHub Actions).
  - Base files, robust `.gitignore`, and this documentation.
- **Step 2: Data Lake Storage Layer (S3 Layering) (Completed) ✔️**
  - Terraform provisioning of S3 buckets organized into Raw (bronze), Trusted (silver), and Refined (gold).
- **Step 3: Ingestion & Raw Data Simulation (Completed) ✔️**
  - Fetching the massive **Olist Brazilian E-commerce** dataset (combining customers, orders, payments, reviews, and products). *(Data is licensed under [CC BY-NC-SA 4.0](DATASET_LICENSE.md))*
  - 100% Cloud-Native AWS Lambda ingestion pipeline that fetches via API and pushes directly into the Bronze tier on S3 using Serverless infrastructure.
- **Step 4: Distributed Processing with PySpark and AWS Glue (Completed) ✔️**
  - Definition of properly orchestrated Glue Jobs without continuous dedicated servers.
- **Step 5: Analytics Engineering & Data Contracts (dbt + Athena) (Completed) ??**
  - GitOps-driven Serverless pipeline leveraging `dbt-core` over GitHub Actions Ubuntu runners.
  - Transformation of Silver tables into C-Level Business models (Gold Layer KPIs).
  - Validation via `schema.yml` contracts ensuring zero degradation over aggregations natively queried by Amazon Athena.
- **Step 6: Business Intelligence & Serving ??**
  - Surfacing the Gold analytical views in dynamic dashboards for final data consumers.

## 📸 Architecture Showcase

A picture is worth a thousand lines of code. Below are the functional demonstrations of this highly-coupled cloud automation working seamlessly.

### 1. Serverless Ingestion (AWS Lambda)
*Showcasing the zero-dependency Python script deployed automatically by Terraform, pulling Olist Dataset via API into AWS ecosystem in under a minute.*
![AWS Lambda Logs](docs/images/lambda_logs.png)

### 2. S3 Medallion Landing (Bronze Zone)
*Demonstrating the successful unzipping and cataloging of CSV objects precisely into the isolated Bronze storage boundary.*
![S3 Data Lake landing](docs/images/s3_bronze_landing.png)

### 3. Continuous Deployment (CI/CD)
*Demonstrating the full IaC GitOps pipeline where code changes synchronously reshape AWS infrastructure.*
![GitHub Actions Pipeline](docs/images/github_actions_pipeline.png)

### 4. Distributed Processing (PySpark via AWS Glue)
*Scaling compute horizontally across dual-node Spark architectures (G.1X FinOps cluster) to standardize datatypes and apply DAG execution.*
![AWS Glue Execution](docs/images/glue_pyspark_execution.png)

### 5. Silver Layer Optimization (Parquet)
*Showcasing the analytical optimization in the Data Lake. Raw CSVs successfully cast, compressed via Snappy, and landed as partitionable Parquet objects.*
![S3 Silver Storage](docs/images/s3_silver_parquet.png)

### 6. Relational Metastore (AWS Glue Catalog)
*Dynamic discovery generating strict schema contracts. Flat files parsed into searchable SQL tables bounded into the `isaac_silver` database.*
![AWS Glue Data Catalog](docs/images/glue_data_catalog.png)

## 🎓 Targeted Skills (Seniority Journey)

The core skills targeted during the coding of this project are:

1. **Connected AWS Ecosystem:** Optimizing the native relationship between Glue, S3, Lake Formation, Athena, and restrictive IAM Roles (Least Privilege).
2. **True Big Data:** Orchestrating large-scale Jobs with PySpark, managing efficient partitioning (.parquet / .iceberg).
3. **Data Quality as Code:** End-to-end use of dbt to build reliable Data Contracts and ensure a "Shift-left" architecture quality.
4. **Applied DevOps / SysAdmin:** Practical mastery of Terraform (clickless provisioning on the AWS Console) and CI/CD pipeline integration (CI via GitHub Actions).
5. **FinOps:** Documenting cost control for Serverless architecture choices (AWS pay-per-use) in every module.

---
> *“If I have seen further it is by standing on the shoulders of Giants.” — Isaac Newton*


## 💰 FinOps: Enterprise Cost Extrapolation

While Project ISAAC operates on a Kaggle dataset designed to fit within the AWS Free Tier, the architecture was intentionally designed using pure **Serverless Pay-Per-Use** models. If a mid-sized company deployed this exact pipeline to process **500 GB of new data per month** (running the pipeline daily), the unit economics would theoretically scale as follows:

| Infrastructure Layer | AWS Service | Pricing Metric | Extrapolated Monthly Cost |
|---|---|---|---|
| **Storage (Data Lake)** | Amazon S3 | 500 GB (Active Standard Tier) | ~ $11.50 |
| **Bronze Ingestion** | AWS Lambda | 30 daily runs (300 sec duration) | ~ $0.10 |
| **Silver Processing** | AWS Glue (PySpark) | 10 DPUs running 30 hours/month | ~ $132.00 |
| **Gold Aggregation** | Amazon Athena | Scanning 3 TB/month (Parquet optimized) | ~ $15.00 |
| **Orchestration** | AWS Step Functions | 300 state transitions/month | ~ $0.00 |
| **GitOps/CI-CD** | GitHub Actions | 120 deployment minutes | ~ $0.00 |
| **Total** | | | **~ $158.60 / month** |

> **The Architectural Impact:** A traditional architecture hosting an always-on Apache Airflow cluster (EC2), a persistent Spark Master Node (EMR), and a continuous Data Warehouse instance (e.g., Redshift/Snowflake) would cost upwards of **$800 - $1,500/month** just to keep the servers turned on, even if zero data was processed. Project ISAAC drops this baseline to **$0.00** when idle, scaling purely linearly with data volume.

## 📸 Architecture Showcase

![AWS Step Functions DAG Success](docs/images/step_functions_dag_success.png)
*Fully Serverless Data Pipeline orchestrated via AWS Step Functions (Event-Driven execution of Lambda, Glue, and Athena).*

## ⚠️ Troubleshooting & Gotchas

Real-world Cloud Engineering is paved with platform nuances. Below are documented anomalies faced during the architectural build of Project ISAAC and their respective resolutions.

### AWS Glue 4.0: `AnalysisException: Database not found`
When programming pure PySpark logic leveraging `.saveAsTable(db.table)` and submitting it to AWS Glue, the Spark engine natively boots utilizing an isolated, ephemeral Hive Metastore stored in temporary memory. Consequentially, it will crash stating the Terraform-created database catalogs (e.g., `isaac_silver`) do not exist.

**Resolution:**
The cluster's execution parameters must explicitly intercept the SparkSession builder. In Terraform, ensure the `aws_glue_job` resource allocates the targeted argument to override this behavior:
```hcl
default_arguments = {
  "--enable-glue-datacatalog" = "true"
}
```
This forces the Spark clusters to sync with the permanent AWS Glue Data Catalog infrastructure seamlessly.


### Step Functions Orchestration (InvalidRequestException & AccessDeniedException)
When substituting dbt scheduling with an automated `boto3` Athena-based Python Lambda (Gold Refresher), executing `DROP TABLE` and `CREATE TABLE AS SELECT` (CTAS) requires a much broader set of IAM permissions than a standard query.

**Common Errors Encountered:**
1. `Unable to verify/create output bucket project-isaac-dev-gold`: Athena requires `s3:GetBucketLocation` and broad multipart upload privileges (`s3:ListMultipartUploadParts`) on the output target, not just explicit `s3:GetObject/PutObject` actions.
2. `AccessDeniedException: glue:DeleteTable`: Dropping an Athena table logically delegates to the AWS Glue Data Catalog. The IAM Role requires explicit `glue:DeleteTable`, `glue:CreateTable`, and `glue:UpdateTable` to execute DDL statements.
3. `Step Functions Error: The resource provided arn:aws:states:::glue:startJobRun.sync:2 is not recognized`: Unlike standard server-based synchronous integrations, the AWS Glue Step Functions native integration strictly requires `.sync` (not `.sync:2`). Additionally, EventBridge `events:PutTargets` rules govern the behind-the-scenes state tracking.

**Resolution:**
Elevated the IAM Role boundaries via Terraform to explicitly authorize native AWS Glue DDL metadata manipulation and broadened S3 boundaries (`arn:aws:s3:::*`) to safely allow the Serverless query engine to distribute execution data seamlessly.


