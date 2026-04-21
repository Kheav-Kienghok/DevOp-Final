# AUPP LMS DevOps CI/CD Pipeline (Jenkins + SonarQube + Trivy + Docker + Terraform + Prometheus + Grafana)

## Project Overview

This project implements a complete **CI/CD pipeline** for AUPP's internal Learning Management System (LMS) platform (similar to Canvas LMS).  
The goal is to ensure **fast feature delivery**, **secure deployments**, **automated infrastructure provisioning**, and **real-time monitoring**.

The CI/CD pipeline is implemented using **Jenkins**, with integrations including:

- SonarQube (Code Quality)
- Trivy (Security Scanning)
- Docker (Containerization)
- Terraform (Infrastructure as Code)
- AWS EC2 (Deployment Target)
- Prometheus + Grafana (Monitoring & Dashboard)

---

## Assignment Evidence Checklist

Place the screenshots in this order so the submission reads naturally from collaboration to deployment and monitoring.

### 1. Source Control & Collaboration (GitHub)

Capture the GitHub workflow first.

1. GitHub Branches + Pull Request
	- Show the feature branch, open PR, and source/target branches.
	- Place the screenshot under `1.3 Pull Request & Reviewer Approval`.
2. Reviewer Approval
	- Show at least 1 reviewer approval on the PR.
	- Place the screenshot directly after the PR screenshot.
3. Merge Conflict + Resolved
	- Show the merge conflict first, then the resolved file or resolved PR diff.
	- Place the screenshot under `1.4 Merge Conflict Demonstration & Resolution`.

### 2. Continuous Integration (CI)

Capture the pipeline script and the quality/security results.

4. Jenkins / GitHub Action full script
	- Show the complete Jenkinsfile or workflow YAML with checkout, SonarQube, Trivy, Docker build, Terraform, and deploy stages.
	- Place the screenshot under `2. Continuous Integration (CI) using Jenkins` or a dedicated `Jenkinsfile / Pipeline Script` subsection.
5. SonarQube report
	- Show the dashboard, quality gate, and main analysis results.
	- Place the screenshot under `3. Code Quality Scan (SonarQube)`.
6. Trivy scan result
	- Show the vulnerability scan output, especially any critical findings.
	- Place the screenshot under `4. Security Scanning (Trivy)`.
7. Quality Fail Pipeline Termination
	- Show the pipeline stopping because SonarQube failed or Trivy found critical vulnerabilities.
	- Place the screenshot under `10.2 Failed Pipeline Execution (Quality Gate / Trivy)`.

### 3. Infrastructure as Code (Terraform)

8. Terraform
	- Show `terraform init`, `terraform apply`, and the final EC2 public IP or instance ID.
	- Place the screenshot under `6. Infrastructure as Code (Terraform)`.

### 4. Continuous Deployment (CD)

9. Continuous Deployment
	- Show the deployment logs where Jenkins copies or runs the container on EC2.
	- Place the screenshot under `7. Continuous Deployment (CD)`.
10. Pipeline success graphical
	- Show the Jenkins pipeline view with all stages successful.
	- Place the screenshot under `10.1 Successful Pipeline Execution`.
11. Access running application from laptop
	- Show your browser accessing the running app through the EC2 public IP or domain.
	- Place the screenshot under `8. Application Access from Laptop`.

### 5. Monitoring & Observability

12. Grafana dashboard
	- Show dashboard panels such as CPU, memory, disk, or container health metrics.
	- Place the screenshot under `9.2 Grafana Dashboard`.

---

## Objectives

- Apply GitHub collaboration workflow (branches, PR, review, conflict resolution)
- Automate CI pipeline using Jenkins
- Enforce code quality gates using SonarQube
- Perform vulnerability scanning using Trivy
- Build Docker images for backend APIs
- Provision AWS EC2 automatically using Terraform
- Deploy Docker container automatically to EC2
- Access application from laptop
- Monitor server/container metrics using Prometheus + Grafana

---

## CI/CD Workflow Architecture

### Full DevOps Flow

```bash
Developer → GitHub → Pull Request → Reviewer Approval 
→ Merge Conflict Resolve → Merge to main  
→ Jenkins Pipeline Runs → SonarQube Scan → Trivy Scan 
→ Docker Build → Terraform Create EC2 → Deploy Docker Image 
→ Access Application → Prometheus Monitoring → Grafana Dashboard
```

---

## Tools & Technologies Used

|       Category         |    Tool    |
|------------------------|------------|
| Source Control         | GitHub     |
| CI/CD Pipeline         | Jenkins    |
| Code Quality           | SonarQube  |
| Security Scan          | Trivy      |
| Containerization       | Docker     |
| Infrastructure as Code | Terraform  |
| Cloud Provider         | AWS EC2    |
| Monitoring             | Prometheus |
| Visualization          | Grafana    |
