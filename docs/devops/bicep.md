---
title: Bicep och IaC
parent: DevOps & CI/CD
nav_order: 30
---

# Bicep och Infrastructure as Code

## Problemet med click-ops

Du konfigurerar VNet, NSG, storage account och App Service i Azure-portalen. Det tar timmar. Nästa vecka ska du sätta upp samma sak i en annan region — och du har bara skärmbilder att gå på.

Det är click-ops. Det skalar inte, det går inte att automatisera och det är omöjligt att verifiera.

Infrastructure as Code (IaC) löser det: du beskriver infrastrukturen i en textfil, versionshanterar den i git och reproducerar exakt samma miljö varje gång.

## ARM vs Bicep

Azure använder **ARM-templates** (Azure Resource Manager JSON) under huven. De fungerar men är ordrika och svårlästa — en enkel App Service kan bli hundratals rader JSON.

**Bicep** är ett kortare, läsbart språk som kompileras till ARM. Du skriver Bicep, Azure kör ARM.

```
main.bicep → az deployment group create → ARM → Resurser i Azure
```

Välj Bicep för all ny infrastruktur. Du stöter på ARM-templates i äldre projekt och dokumentation — bra att känna igen, men skriv inte nya.

## Grundstruktur

```bicep
// Parametrar — input med valfria defaultvärden
param location string = 'northeurope'
param appName string

// Variabel — beräknat värde
var planName = '${appName}-plan'

// Resurs — en Azure-resurs
resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  sku: { name: 'B1' }
}

// Output — returneras efter deploy
output url string = 'https://${app.properties.defaultHostName}'
```

| Byggsten | Syfte |
|----------|-------|
| `param` | Input utifrån — appnamn, region, miljö |
| `var` | Beräknade värden inom filen |
| `resource` | En Azure-resurs med typ och API-version |
| `output` | Värden som returneras när deployn är klar |

## Komplett exempel — App Service

```bicep
param location string = 'northeurope'
param appName string = 'app-iths-demo'

var planName = '${appName}-plan'

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
    }
  }
}

output url string = 'https://${app.properties.defaultHostName}'
```

`plan.id` är en referens — Bicep löser beroendet och skapar App Service Plan före App Service automatiskt.

## What-if

Förhandsgranska vad som händer utan att deploya:

```bash
az deployment group what-if \
  --resource-group rg-iths \
  --template-file main.bicep \
  --parameters appName=min-app
```

Outputen visar vad som skapas, ändras eller tas bort. Kör alltid `what-if` i produktion innan `create`.

## Deploy

```bash
az deployment group create \
  --resource-group rg-iths \
  --template-file main.bicep \
  --parameters appName=min-app
```

**Idempotens:** kör samma kommando tio gånger — resultatet är identiskt. Resurser som redan är korrekt konfigurerade rörs inte. Det gör Bicep-deployer trygga att köra om.
