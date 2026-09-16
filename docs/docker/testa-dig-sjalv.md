---
title: Testa dig själv
parent: Docker
nav_order: 99
---

# Testa dig själv — Docker

1. Vad händer med layer-cachen om du lägger `COPY . .` före `RUN dotnet restore` i din Dockerfile?

<details>
<summary>Visa svar</summary>

Varje gång du ändrar en `.cs`-fil ogiltigförklaras `COPY . .`-lagret — och alla lager efter det byggs om från scratch, inklusive `dotnet restore`. Det kan ta 1–3 minuter per bygge. Rätt ordning: `COPY *.csproj ./` → `RUN dotnet restore` → `COPY . .` → `RUN dotnet publish`. Då cachas `dotnet restore` tills beroenden faktiskt ändras.

</details>

2. Varför ska du aldrig skriva `ENV ConnectionString="..."` i en Dockerfile?

<details>
<summary>Visa svar</summary>

`docker inspect [container-id]` visar alla ENV-variabler i klartext. Om imagen pushas till ett registry är credentials inbakade i imagen för alltid — de raderas inte när du tar bort containern. Injicera istället secrets vid körning (`docker run -e`) eller, ännu bättre, hämta dem från Key Vault via Managed Identity så att ingen secret lämnar Key Vault.

</details>

3. Vad gör en multi-stage build och varför är det standard i produktion?

<details>
<summary>Visa svar</summary>

En multi-stage build använder en SDK-image för att kompilera (Stage 1) och en minimal runtime-image för slutresultatet (Stage 2). Slutimagen innehåller bara binärerna — ingen SDK, ingen källkod, inga `.csproj`-filer. Resultatet är ~200 MB istället för flera GB, och attackytan minskar drastiskt. Det är inte en optimering att göra "om man hinner" — det är hur en produktions-Dockerfile ska se ut.

</details>

4. Vad händer om du inte har en HEALTHCHECK och deployer containern till Kubernetes?

<details>
<summary>Visa svar</summary>

Kubernetes anser containern "klar" att ta emot trafik så fort processen startat — oavsett om appen faktiskt svarar. Under en rolling update kan trafik skickas till den nya containern innan den är redo, vilket ger 502-fel för användare. Med HEALTHCHECK (eller readiness probe i K8s-YAMLn) väntar Kubernetes tills `/health` svarar 200 OK.

</details>

5. Varför ska du använda Managed Identity och rollen `AcrPull` istället för admin-credentials för att hämta images från ACR?

<details>
<summary>Visa svar</summary>

Admin-credentials är ett enda lösenord med full åtkomst till hela registret, roteras inte automatiskt och delas av alla. Med Managed Identity + `AcrPull`-rollen behöver resursen (ACI, AKS-nod, pipeline) inget lösenord alls — Azure hanterar autentiseringen. Principen för lägsta behörighet: pull-rätt, inget annat.

</details>
