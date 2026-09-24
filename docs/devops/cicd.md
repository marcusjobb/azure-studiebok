---
title: CI/CD och OpenAPI
description: "> Läsmaterial för vecka 38. Läs detta efter tisdagens föreläsning."
parent: DevOps
nav_order: 1
---

# CI/CD och OpenAPI — automatisera vägen till produktion

> Läsmaterial för vecka 38. Läs detta efter tisdagens föreläsning.

---

## Problemet med manuell deployment

```
Kod → ZIP:a → FTP till server → be att det funkar → hoppas
```

Det är inte ett flöde. Det är ett lotteri. Och när något går fel vet ingen exakt vad som hände eller varför.

**CI/CD** ersätter det med ett deterministiskt, automatiskt flöde.

---

## CI/CD — vad är det?

**Continuous Integration (CI):**
Varje gång någon pushar kod till main — bygg automatiskt, kör tester automatiskt. Om något är trasigt vet du det inom minuter, inte dagar.

**Continuous Delivery (CD):**
Den byggda och testade koden deployar automatiskt till en miljö. Till staging direkt, till produktion efter ett manuellt godkännande.

**Continuous Deployment:**
Samma som Delivery, men utan manuellt godkännande. Grön pipeline = appen är ute. Kräver hög testtäckning och mogna team.

| | CI | Delivery | Deployment |
|--|----|---------|----|
| Bygg + test | Auto | Auto | Auto |
| Till staging | Auto | Auto | Auto |
| Till produktion | Manuell | Manuell | **Auto** |

---

## Azure DevOps Pipeline

En pipeline i Azure DevOps definieras som en YAML-fil i repot — `azure-pipelines.yml`. Versionshanteras med koden. Code review på pipeline-ändringar.

### Grundstruktur

```yaml
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  jobs:
  - job: BuildAndTest
    steps:
    - task: UseDotNet@2
      inputs:
        version: '8.x'

    - script: dotnet restore
      displayName: 'Restore NuGet'

    - script: dotnet build --configuration $(buildConfiguration)
      displayName: 'Build'

    - script: dotnet test --no-build --configuration $(buildConfiguration)
      displayName: 'Test'

    - task: DotNetCoreCLI@2
      displayName: 'Publish'
      inputs:
        command: publish
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'

    - task: PublishBuildArtifacts@1
      displayName: 'Spara artifact'
      inputs:
        pathtoPublish: '$(Build.ArtifactStagingDirectory)'
```

### Deploy till App Service

```yaml
- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployToAppService
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy till App Service'
            inputs:
              azureSubscription: 'Min Azure-koppling'
              appName: 'app-iths-minapp'
              package: '$(Pipeline.Workspace)/**/*.zip'
```

### Nyckelbegrepp

| Begrepp | Förklaring |
|---------|-----------|
| `trigger` | Vad startar pipelinen — branch, tag, PR |
| `pool` | Vilken typ av agent som kör bygget |
| `stage` | Logisk gruppering — Build, Test, Deploy |
| `job` | Kör på en agent, parallella jobs möjliga |
| `step` | Enskilt steg — script eller task |
| `task` | Inbyggd Azure DevOps-uppgift (`AzureWebApp@1`) |
| `artifact` | Byggresultatet som sparas och skickas vidare |
| `environment` | Deployment-mål med godkännandeflöde |

---

## Deployment Slots — noll downtime

App Service har **Deployment Slots** — separata "miljöer" inom samma app. Du deployer till staging-sloten, värmer upp appen, sedan gör du ett **swap** som byter staging och production med en enda operation.

```bash
# Lägg till staging-slot
az webapp deployment slot create \
  --name app-iths-minapp \
  --resource-group rg-iths \
  --slot staging

# Swap — staging → production, ingen downtime
az webapp deployment slot swap \
  --name app-iths-minapp \
  --resource-group rg-iths \
  --slot staging \
  --target-slot production
```

I pipelinen:
```yaml
- task: AzureAppServiceManage@0
  displayName: 'Swap till production'
  inputs:
    azureSubscription: 'Min Azure-koppling'
    Action: 'Swap Slots'
    WebAppName: 'app-iths-minapp'
    SourceSlot: staging
```

---

## OpenAPI och Swagger

När du bygger ett API behöver konsumenterna (frontend, mobilapp, andra tjänster) veta exakt vilka endpoints som finns, vad de tar emot och vad de returnerar. **OpenAPI** är ett standardformat för den dokumentationen. **Swagger UI** och **Scalar** renderar den som en interaktiv webbsida.

### Sätta upp i .NET

```bash
# Swashbuckle (klassisk Swagger UI)
dotnet add package Swashbuckle.AspNetCore

# Scalar (nyare, snyggare UI)
dotnet add package Scalar.AspNetCore
```

I `Program.cs`:

```csharp
// Services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "MinApp API",
        Version = "v1",
        Description = "REST API för MinApp"
    });
});

// Middleware (bara i Development eller alltid om det är ett publikt API)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "MinApp API v1");
    c.RoutePrefix = "swagger";
});
```

Öppna `/swagger` — du ser alla dina endpoints, kan testa dem direkt, och kan exportera OpenAPI-specifikationen som JSON.

### Dokumentera endpoints

```csharp
app.MapGet("/api/produkter/{id}", (int id, IProduktRepository repo) =>
{
    var produkt = repo.HamtaById(id);
    return produkt is null ? Results.NotFound() : Results.Ok(produkt);
})
.WithName("HamtaProdukt")
.WithTags("Produkter")
.WithSummary("Hämta en produkt på ID")
.Produces<Produkt>(200)
.Produces(404);
```

### URL-översikt

| Tjänst | URL |
|--------|-----|
| Swagger UI | `/swagger` |
| OpenAPI JSON | `/swagger/v1/swagger.json` |
| Scalar | `/scalar/v1` |

---

## Terminologi

| Term | Förklaring |
|------|------------|
| **CI** | Continuous Integration — bygg och testa automatiskt vid varje push |
| **CD** | Continuous Delivery/Deployment — automatisera vägen till produktion |
| **pipeline** | Automatiserat flöde av steg — build, test, deploy |
| **artifact** | Byggresultatet som sparas och skickas vidare i pipelinen |
| **stage** | Logisk fas i pipelinen (Build, Deploy) |
| **environment** | Deployment-mål med godkännandeflöde |
| **deployment slot** | Parallell app-miljö för noll-downtime deploys |
| **swap** | Byter staging och production — ingen downtime |
| **OpenAPI** | Standard för att beskriva REST API:er |
| **Swagger UI** | Interaktiv dokumentation för OpenAPI |
| **Scalar** | Modernare alternativ till Swagger UI |
