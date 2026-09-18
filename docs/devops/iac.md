---
title: IaC och Azure ML
description: "IaC och Azure ML i DevOps — Azure studiebok av Marcus Ackre Medina"
parent: DevOps
nav_order: 2
---

# IaC och Azure ML — klick-ops är historia

> Läsmaterial för vecka 39. Läs detta efter tisdagens föreläsning.

---

## Del 1: Infrastructure as Code

### Problemet med att klicka i portalen

Du har skapat ett VNet, tre subnets, två NSG:er, ett storage account och en App Service. Det tog tre timmar. Kollegan ska göra exakt samma sak i en annan region. Du kan inte beskriva exakt vad du gjorde — du kan visa skärmbilder.

Det kallas **click ops**. Det är inte reproducerbart, inte reviderbart och inte skalbart.

**Infrastructure as Code (IaC)** beskriver infrastrukturen som text. Exakt samma infrastruktur, varje gång, från en fil du kan code-reviewa och versionshantere i git.

### ARM vs Bicep

Azure har ett eget format för IaC: **ARM-mallar** (Azure Resource Manager), skrivna i JSON. De fungerar — men JSON är ordrik och svår att läsa.

**Bicep** är Azures svar på det problemet. Det är ett DSL (domain-specific language) som kompileras till ARM. Du skriver Bicep, Azure kör ARM. Du behöver aldrig se ARM-JSON om du inte vill.

```
Bicep (.bicep) → kompileras → ARM JSON → Azure Resource Manager → resurser
```

### Bicep-syntax

En Bicep-fil kan innehålla parametrar, variabler, resurser och outputs:

```bicep
// Parameter med standardvärde
param location string = 'northeurope'
param appServiceName string

// Variabel
var appServicePlanName = '${appServiceName}-plan'

// Resurs
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
    }
  }
}

// Output
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
```

### Deployta

```bash
# Installera Bicep CLI (om du inte har det)
az bicep install

# Förhandsgranska vad som händer utan att deploya
az deployment group what-if \
  --resource-group rg-iths-[dittnamn] \
  --template-file main.bicep \
  --parameters appServiceName=app-iths-[dittnamn]

# Deploya
az deployment group create \
  --resource-group rg-iths-[dittnamn] \
  --template-file main.bicep \
  --parameters appServiceName=app-iths-[dittnamn]
```

**`what-if`** är guld. Du ser exakt vad som skapas, ändras eller tas bort innan du bekräftar. Kör alltid `what-if` innan `create` i produktionsmiljöer.

### Parameterfiler

Istället för att skicka parametrar i kommandoraden kan du skapa en parameterfil:

```json
// main.parameters.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appServiceName": {
      "value": "app-iths-demo"
    },
    "location": {
      "value": "northeurope"
    }
  }
}
```

```bash
az deployment group create \
  --resource-group rg-iths-[dittnamn] \
  --template-file main.bicep \
  --parameters main.parameters.json
```

---

## Del 2: Azure Machine Learning Studio

### Vad är det?

Azure Machine Learning Studio är Azures plattform för att bygga, träna och deploya maskininlärningsmodeller. Du behöver inte kunna ML för att sätta upp infrastrukturen — det är det kursen täcker.

Som molnlösare är din roll: provisiona rätt resurser, konfigurera åtkomst och se till att ML-teamet har en fungerande miljö att arbeta i.

### De tre grundresurserna

**Workspace**
Allt i Azure ML lever i ett workspace. Det är behållaren — experiment, modeller, datastores, compute targets. En workspace per projekt eller team.

**Compute**
Azure ML behöver beräkningskraft för att träna modeller. Du konfigurerar compute targets:

| Typ | Används för |
|-----|-------------|
| **Compute Instance** | Interaktivt arbete, notebooks |
| **Compute Cluster** | Träningsjobb — skalas ut och in |
| **Inference Cluster** | Köra färdiga modeller (AKS-baserat) |

**Datastores**
Var datan finns. Azure ML kan kopplas till Blob Storage, Azure Data Lake, SQL, etc. ML-kod refererar till datastores med ett namn — inte en connection string.

### Sätta upp workspace

Via CLI:
```bash
# Installera ML-tillägget
az extension add -n ml

# Skapa workspace
az ml workspace create \
  --name ws-iths-[dittnamn] \
  --resource-group rg-iths-ml \
  --location northeurope
```

Via portalen: sök "Azure Machine Learning" → Create → fyll i namn, resource group, region.

### Skapa en Compute Instance

I Studio (ml.azure.com):
1. Välj workspace
2. **Compute** → **Compute instances** → **New**
3. Välj VM-storlek (Standard_DS1_v2 räcker för övning)
4. Starta inte automatiskt (spara kostnader)

Via CLI:
```bash
az ml compute create \
  --name ci-iths-[dittnamn] \
  --type ComputeInstance \
  --size Standard_DS1_v2 \
  --workspace-name ws-iths-[dittnamn] \
  --resource-group rg-iths-ml
```

### Koppla Blob Storage som Datastore

```bash
# Skapa storage account och container
az storage account create --name stmliths[dittnamn] --resource-group rg-iths-ml --location northeurope --sku Standard_LRS
az storage container create --name ml-data --account-name stmliths[dittnamn]

# Koppla som datastore
az ml datastore create \
  --name ds_blob \
  --type AzureBlob \
  --account-name stmliths[dittnamn] \
  --container-name ml-data \
  --workspace-name ws-iths-[dittnamn] \
  --resource-group rg-iths-ml
```

---

## Terminologi

| Term | Förklaring |
|------|------------|
| **IaC** | Infrastructure as Code — infrastruktur beskriven som text |
| **ARM** | Azure Resource Manager — Azures deploymentmotor + JSON-format |
| **Bicep** | DSL för Azure IaC, kompileras till ARM |
| **`what-if`** | Förhandsgranska ändringar utan att deploya |
| **parameterfil** | JSON-fil med värden till Bicep-parametrar |
| **idempotent** | Kör 10 gånger, samma resultat — IaC är idempotent |
| **workspace** | Behållare för allt i Azure ML |
| **compute instance** | Interaktiv VM för ML-arbete |
| **compute cluster** | Skalbar beräkning för träningsjobb |
| **datastore** | Koppling till datakälla (Blob, SQL, etc.) |
