---
title: Microsoft Learn
description: "Moduler och sandboxar kopplade till kursens övningar. Använd dem för hands-on-labbar och som referens."
parent: Resurser
nav_order: 2
---

# Microsoft Learn

Moduler och sandboxar kopplade till kursens övningar. Använd dem för hands-on-labbar och som referens.

---

## Molngrunder (v33)

| Ämne | Learn-modul |
|------|-------------|
| Azure-grunder | [Azure fundamentals – Cloud Concepts](https://learn.microsoft.com/training/paths/az-900-describe-cloud-concepts/) |
| Tjänstemodeller (IaaS/PaaS/SaaS) | Ingår i AZ-900-sökvägen ovan |
| Azure Portal | [Manage services with the Azure portal](https://learn.microsoft.com/training/modules/tour-azure-portal/) |

---

## Compute & Storage (v34)

| Ämne | Learn-modul |
|------|-------------|
| App Service | [Host a web application with Azure App Service](https://learn.microsoft.com/training/modules/host-a-web-app-with-azure-app-service/) |
| Azure Functions | [Create serverless logic with Azure Functions](https://learn.microsoft.com/training/modules/create-serverless-logic-with-azure-functions/) |
| Azure Storage | [Store data in Azure](https://learn.microsoft.com/training/paths/store-data-in-azure/) |
| Azure SQL | [Provision an Azure SQL database](https://learn.microsoft.com/training/modules/provision-azure-sql-db/) |
| CosmosDB | [Work with NoSQL data in Azure Cosmos DB](https://learn.microsoft.com/training/paths/work-with-nosql-data-in-azure-cosmos-db/) |

---

## Nätverk & Säkerhet (v35)

| Ämne | Learn-modul |
|------|-------------|
| VNet | [Introduction to Azure Virtual Networks](https://learn.microsoft.com/training/modules/introduction-to-azure-virtual-networks/) |
| NSG | [Secure network connectivity on Azure](https://learn.microsoft.com/training/modules/secure-network-connectivity-azure/) |
| Entra ID & RBAC | [Secure Azure resources with Azure role-based access control](https://learn.microsoft.com/training/modules/secure-azure-resources-with-rbac/) |
| Easy Auth / App Service Auth | [Authenticate users with App Service authentication](https://learn.microsoft.com/training/modules/authenticate-users-with-app-service-auth/) |

---

## Docker & Containerisering (v36)

| Ämne | Learn-modul |
|------|-------------|
| Docker intro | [Introduction to Docker containers](https://learn.microsoft.com/training/modules/intro-to-docker-containers/) |
| Azure Container Registry | [Build and store container images with Azure Container Registry](https://learn.microsoft.com/training/modules/build-and-store-container-images/) |
| Azure Container Instances | [Run Docker containers with Azure Container Instances](https://learn.microsoft.com/training/modules/run-docker-with-azure-container-instances/) |

---

## Kubernetes (v37)

| Ämne | Learn-modul |
|------|-------------|
| Kubernetes-grunder | [Introduction to Kubernetes](https://learn.microsoft.com/training/modules/intro-to-kubernetes/) |
| AKS | [Deploy a containerized application on Azure Kubernetes Service](https://learn.microsoft.com/training/modules/aks-deploy-container-app/) |

> AKS är inte tillgängligt i studerandekonton. Övningarna körs mot Container Apps — AKS används som konceptreferens.

---

## CI/CD & OpenAPI (v38)

| Övning | Rekommenderad modul |
|--------|---------------------|
| Övning 1 — Swagger/OpenAPI | Inget sandbox behövs — körs lokalt |
| Övning 2 — Azure DevOps Pipeline | [Build a continuous deployment pipeline by using Azure Pipelines](https://learn.microsoft.com/training/modules/create-a-build-pipeline/) |

### Aktivera sandbox

Azure DevOps är gratis att skapa på [dev.azure.com](https://dev.azure.com) med ditt Microsoft-konto.

App Service-målet i Övning 2 behöver en Azure-miljö. Aktivera en gratis sandbox via Learn-modulen ovan:

1. Gå till modulen via länken
2. Logga in med ditt Microsoft-konto
3. Klicka **"Activate sandbox"** i första övningssteget
4. Kombinera DevOps-kontot med sandboxens App Service som deploy-mål

> Sandboxen lever i ~4 timmar. Spara dina YAML-filer lokalt — du kan behöva skapa om resursen om sessionen tar slut.

---

## IaC & Azure ML (v39)

| Ämne | Learn-modul |
|------|-------------|
| Bicep intro | [Introduction to infrastructure as code using Bicep](https://learn.microsoft.com/training/modules/introduction-to-infrastructure-as-code-using-bicep/) |
| Deploy med Bicep | [Deploy Azure resources by using Bicep templates](https://learn.microsoft.com/training/paths/deploy-manage-resource-manager-templates/) |
| Azure ML Studio | [Build and operate machine learning solutions with Azure Machine Learning](https://learn.microsoft.com/training/paths/build-ai-solutions-with-azure-ml-service/) |

---

## Teamlabb (v40)

| Ämne | Learn-modul |
|------|-------------|
| Azure Boards | [Manage agile software delivery plans across teams](https://learn.microsoft.com/training/modules/manage-agile-software-delivery-plans-across-teams/) |
| Git i team | [Collaborate with Git](https://learn.microsoft.com/training/modules/collaborate-with-git/) |
| Pull Requests | Ingår i Azure DevOps-modulerna från v38 |
