---
title: Docker i produktion
description: "Docker i produktion i Docker — Azure studiebok av Marcus Ackre Medina"
parent: Docker
nav_order: 1
---

# Docker — containrar som fungerar i produktion

> Läsmaterial för vecka 36. Läs detta efter tisdagens föreläsning.

Ni vet vad en container är och hur Docker fungerar grundläggande. Det här materialet fokuserar på det som separerar en Dockerfile som fungerar lokalt från en som fungerar i produktion och CI/CD.

---

## Layer-caching — den dyraste missförståelsen

En Docker-image byggs lager för lager. Varje rad i Dockerfile är ett lager. Docker cachar varje lager — men om ett lager ändras, ogiltigförklaras **alla lager efter det**.

Det är avgörande för byggtider.

**Dålig ordning:**
```dockerfile
COPY . .                    # Hela källkoden
RUN dotnet restore          # Invalideras vid VARJE kodändring
RUN dotnet publish ...
```

Varje gång ni ändrar en `.cs`-fil: `dotnet restore` körs om. Det tar 1–3 minuter. I en pipeline som kör 20 gånger om dagen är det timmar i onödan.

**Rätt ordning:**
```dockerfile
COPY *.csproj ./            # Bara projektfilen — ändras sällan
RUN dotnet restore          # Cachas tills beroenden ändras

COPY . .                    # Resten av koden
RUN dotnet publish -c Release -o /app/publish
```

`*.csproj` ändras bara när ni lägger till eller tar bort NuGet-paket. Allt däremellan träffar cachen och hoppar `dotnet restore`. Byggtiden går från minuter till sekunder.

---

## .dockerignore — skapar alltid, glöms alltid

Docker skickar hela build-kontexten (mappen) till Docker-daemonen innan bygget startar. Utan `.dockerignore` ingår `bin/`, `obj/`, `.git/`, `node_modules/` — allt. Det kan vara hundratals MB som skickas varje gång.

```
# .dockerignore
bin/
obj/
.git/
.gitignore
*.md
.env
.vscode/
.vs/
```

**Viktigast av allt:** `.env`-filer kan aldrig råka hamna i imagen. En `.env` med databas-credentials som läcker via Docker Hub är ett välkänt säkerhetsproblem.

Skapa alltid `.dockerignore` i samma steg som `Dockerfile`.

---

## Multi-stage build — standarden

Inte en optimering ni gör när ni har tid. Det är hur en produktions-Dockerfile ska se ut.

```dockerfile
# Stage 1: Bygg
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MinApp.dll"]
```

**`ASPNETCORE_URLS=http://+:8080`** — utan den lyssnar .NET på port 80 (eller den port den konfigureras via launchSettings.json, som inte finns i en container). Sätt alltid explicit port.

**Slutimage:** ~200 MB. Ingen SDK. Ingen källkod. Ingen `.csproj`. Inga mellanfiler. Bara runtime och publicerade binärer.

---

## HEALTHCHECK — containrar som berättar om de mår bra

Kubernetes och ACI avgör om en container är redo att ta emot trafik via health checks. Utan en definierad health check: containern anses "klar" så fort processen startat — oavsett om appen faktiskt svarar på requests.

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

- `--interval=30s` — kolla var 30:e sekund
- `--timeout=10s` — om inget svar på 10 sekunder: fel
- `--start-period=15s` — vänta 15 sekunder innan första kontrollen (app behöver starta)
- `--retries=3` — tre misslyckanden i rad = unhealthy

Lägg till ett minimalt health-endpoint i .NET-appen:

```csharp
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));
```

Kubernetes använder det för **readiness** (redo att ta emot trafik) och **liveness** (fortfarande vid liv). Mer om det i vecka 37.

---

## Secrets i containers — ENV är inte säkert

En vanlig fälla:

```dockerfile
ENV ConnectionString="Server=prod.database.windows.net;Password=Hemlig123!"
```

Problemet: `docker inspect [container-id]` visar alla ENV-variabler i klartext. Images lagras med dessa värden — om imagen läcker till ett publikt registry är credentials exponerade.

**Injicera secrets vid körning, aldrig i imagen:**

```bash
docker run -e ConnectionString="Server=..." min-app:v1
```

**Bättre: hämta från Key Vault via Managed Identity.** Ingen secret lämnar Key Vault. Appen hämtar den vid start via `DefaultAzureCredential`. Imagen innehåller noll credentials.

```csharp
// I Program.cs — hämtar connection string vid appstart
var connectionString = await secretClient.GetSecretAsync("DbConnectionString");
```

---

## ACR — Managed Identity istället för admin-credentials

Admin-credentials på ACR fungerar men är inte bra:
- Ett enda lösenord med full åtkomst till hela registret
- Roteras inte automatiskt
- Delas av alla som behöver åtkomst

**Rätt sätt:** ge resursen (ACI, AKS-nod, pipeline) rollen `AcrPull`:

```bash
# Hämta ACR:s resource ID
ACR_ID=$(az acr show --name acriths[dittnamn] --query id -o tsv)

# Ge Managed Identity AcrPull-rollen
az role assignment create \
  --assignee [managed-identity-principal-id] \
  --role "AcrPull" \
  --scope "$ACR_ID"
```

Ingen `--registry-password` i `az container create`. Managed Identity hanterar autentiseringen.

---

## Vanliga felsökningskommandon

```bash
# Kolla loggarna för en container
docker logs [container-id]
docker logs -f [container-id]  # Följ i realtid

# Kör ett kommando inuti en körande container
docker exec -it [container-id] /bin/bash

# Inspektera imagen — se lager, ENV, ENTRYPOINT
docker inspect [image-id]

# Se vad som är annorlunda i en container vs imagen
docker diff [container-id]

# Kolla ACI-loggar i Azure
az container logs --name [aci-namn] --resource-group [rg]
```

**`docker exec -it ... /bin/bash`** fungerar bara om imagen innehåller bash. Minimal aspnet-image innehåller det inte. Använd `/bin/sh` istället, eller lägg till `curl` i Dockerfile för debugging (ta bort i prod).

---

## Terminologi v.36

| Term | Förklaring |
|------|------------|
| **image** | Oföränderlig mall — byggs en gång, körs många gånger |
| **container** | Körande instans av en image |
| **layer** | Ett Dockerfile-steg — cachelagras tills det ändras |
| **layer cache** | Docker återanvänder oförändrade lager — avgörande för byggtid |
| **multi-stage build** | Separerar byggmiljö från körmiljö — minimal slutimage |
| **.dockerignore** | Exkluderar filer från build-kontexten |
| **HEALTHCHECK** | Direktiv som definierar hur Docker kontrollerar containerns hälsa |
| **ASPNETCORE_URLS** | Miljövariabel som styr vilken port .NET lyssnar på |
| **ACR** | Azure Container Registry — privat image-registry |
| **ACI** | Azure Container Instances — kör containers utan servrar |
| **AcrPull** | RBAC-roll för att hämta images från ACR |
| **build context** | Filerna som skickas till Docker-daemonen vid bygge |
