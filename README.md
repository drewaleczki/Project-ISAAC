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
- **Infrastructure as Code (IaC):** Terraform
- **CI/CD:** GitHub Actions (Automated Deployment focused on DevOps)

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
- **Step 4: Distributed Processing with PySpark and AWS Glue 🚧**
  - Definition of properly orchestrated Glue Jobs without continuous dedicated servers.
- **Step 5: dbt & Data Contracts**
  - Creation of dbt models focused on quality testing to transform data into the Refined layer.
- **Step 6: Analytics & Serving**
  - Creation of crawlers and mapping via Amazon Athena to simulate analytical queries for the final data consumer.

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

## 🎓 Targeted Skills (Seniority Journey)

The core skills targeted during the coding of this project are:

1. **Connected AWS Ecosystem:** Optimizing the native relationship between Glue, S3, Lake Formation, Athena, and restrictive IAM Roles (Least Privilege).
2. **True Big Data:** Orchestrating large-scale Jobs with PySpark, managing efficient partitioning (.parquet / .iceberg).
3. **Data Quality as Code:** End-to-end use of dbt to build reliable Data Contracts and ensure a "Shift-left" architecture quality.
4. **Applied DevOps / SysAdmin:** Practical mastery of Terraform (clickless provisioning on the AWS Console) and CI/CD pipeline integration (CI via GitHub Actions).
5. **FinOps:** Documenting cost control for Serverless architecture choices (AWS pay-per-use) in every module.

---
> *“If I have seen further it is by standing on the shoulders of Giants.” — Isaac Newton*
