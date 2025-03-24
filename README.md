# AWS Cost Comparison: EC2 + CloudWatch vs. EC2 + Kinesis Firehose + S3 + Athena + CloudWatch Metrics

This project aims to demonstrate and compare the cost implications of two different architectures for data processing and monitoring on AWS:

1.  **Traditional Approach:** EC2 instance with CloudWatch metrics for monitoring.
2.  **Modern Data Pipeline:** EC2 instance sending data to Kinesis Firehose, which streams data to S3, and then uses Athena for querying and analysis, along with CloudWatch metrics for monitoring.

## Project Overview

The core objective is to:

* **Deploy both architectures** using Terraform.
* **Generate synthetic data** on the EC2 instances to simulate real-world workloads.
* **Collect and process metrics** using CloudWatch in both scenarios.
* **Ingest and store data** in S3 via Kinesis Firehose in the modern pipeline.
* **Query and analyze data** in S3 using Athena.
* **Compare the costs** associated with each architecture.
* **Provide insights** into the trade-offs between simplicity and scalability/analysis capabilities.

## Architecture

* **Traditional Approach:**
    * EC2 instance running an application.
    * CloudWatch metrics for CPU, memory, and disk usage.
* **Modern Data Pipeline:**
    * EC2 instance running an application and sending data to Kinesis Firehose.
    * Kinesis Firehose delivering data to S3.
    * Athena for querying and analyzing data in S3.
    * CloudWatch metrics for EC2, Kinesis Firehose, and S3.

## Technologies Used

* **Terraform:** Infrastructure as Code (IaC) for deploying AWS resources.
* **AWS EC2:** Virtual servers for running applications.
* **AWS CloudWatch:** Monitoring and observability service.
* **AWS Kinesis Firehose:** Real-time data streaming service.
* **AWS S3:** Object storage service.
* **AWS Athena:** Serverless interactive query service.


## Impact Premise and Cost Scenario

**Scenario:** We are processing and analyzing 40TB of log data over a 14-day period. Our goal is to assess the cost differences between a traditional CloudWatch-centric approach and a more modern, data lake-driven approach using Kinesis Firehose, S3, and Athena.

**Traditional Approach: EC2 + CloudWatch (14 Days)**

* **Log Ingestion:** 40TB of log data ingested into CloudWatch Logs.
* **Log Storage:** 40TB stored in CloudWatch Logs for 14 days.
* **Log Queries:** CloudWatch Logs Insights queries.

**Modern Data Pipeline: EC2 + Kinesis Firehose + S3 + Athena + CloudWatch Metrics (14 Days)**

* **Log Ingestion:** 40TB of log data ingested (via Kinesis Agent and Firehose).
    * 1% of the logs are sent to CloudWatch as metrics.
    * 99% of the logs are sent to S3.
* **Log Storage:**
    * Days 1-7: 20TB stored in S3 Standard.
    * Days 8-14: 20TB stored in S3 Infrequent Access (IA).
    * Cloudwatch metrics logs, 400GB stored for 14 days.
* **Log Queries:** Athena queries on S3 data.
* **Cloudwatch metrics:** Cloudwatch metrics storage and ingestion.

**Revised Cost Estimates (for 40TB, 14 days):**

* **Traditional Approach (EC2 + CloudWatch):**
    * **CloudWatch Logs Storage:** ~$560
    * **CloudWatch Logs Ingestion:** $20,000
    * **CloudWatch Logs Insights Queries:** ~$25 (estimated)
    * **Total Traditional Cost:** ~$20,585
* **Modern Data Pipeline (EC2 + Kinesis Firehose + S3 + Athena + CloudWatch Metrics):**
    * **S3 Storage (Standard):** ~$107.33
    * **S3 Storage (IA):** ~$58.33
    * **Kinesis Firehose Ingestion:** $140
    * **Athena Queries:** $50
    * **Cloudwatch metrics Ingestion:** $120
    * **Cloudwatch metrics Storage:** $5.6
    * **Total Modern Pipeline Cost:** ~$481.26

**Key Takeaways:**

* When ingestion is accounted for, CloudWatch becomes extremely expensive.
* The modern pipeline is still significantly cheaper.
* The largest cost driver in the traditional method is the ingestion of the logs to CloudWatch.
* The cost of queries in cloudwatch logs can vary wildly.