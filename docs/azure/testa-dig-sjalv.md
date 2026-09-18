---
title: Testa dig själv
description: "Testa dig själv i Azure — Azure studiebok av Marcus Ackre Medina"
parent: Azure
nav_order: 99
---

# Testa dig själv — Azure

1. En studerande glömmer ta ned sitt Kubernetes-kluster över en helg. Vad händer med kostnaden — och varför?

<details markdown="block">
<summary>Visa svar</summary>

Azure debiterar för existens, inte bara trafik. Klustret kostar per timme det körs, oavsett om det tar emot noll requests. Utan budgetalerts och auto-shutdown kan kostnaden bli astronomisk — en känd historia landade på 50 000 kr på två dagar.

</details>

2. Vad är skillnaden mellan en Subscription och en Resource Group i Azure-hierarkin?

<details markdown="block">
<summary>Visa svar</summary>

En **Subscription** är faktureringsgränsen — alla kostnader samlas här, och det finns kvoter per subscription. En **Resource Group** är en livscykelenhet, åtkomstenhet och kostnadsvisningsenhet. Tar du bort en resource group raderas allt inuti utan bekräftelse per resurs. RBAC-roller sätts per resource group.

</details>

3. Varför är det ett problem att ha en enda resource group för alla resurser i ett projekt?

<details markdown="block">
<summary>Visa svar</summary>

Om allt ligger i `rg-allt` kan du inte städa dev-miljön utan att riskera att radera prod. Du kan inte ge en junior Contributor-åtkomst till dev utan att de får samma i prod. Cost Analysis visar en total summa du inte kan dela upp. Den robusta strukturen är separata grupper per miljö (`rg-projekt-dev`, `rg-projekt-prod`) plus en `rg-projekt-shared` för delat som Key Vault och Container Registry.

</details>

4. Vad är skillnaden mellan VNet Integration och Private Endpoint — och varför behöver man ofta båda?

<details markdown="block">
<summary>Visa svar</summary>

**VNet Integration** löser utgående trafik: appen kan nå resurser inuti VNet:et (t.ex. en databas med privat endpoint). **Private Endpoint** löser inkommande trafik till en resurs: databasen eller tjänsten får en privat IP i VNet:et och ingen publik adress. Utan båda: antingen kan appen inte nå databasen via det privata nätverket, eller så är databasen fortfarande publik och kan nås direkt från internet.

</details>

5. Vad är Managed Identity och varför är det bättre än att lagra credentials i kod eller appsettings?

<details markdown="block">
<summary>Visa svar</summary>

Managed Identity är en automatiskt hanterad identitet för en Azure-resurs (t.ex. App Service). Den autentiserar mot andra Azure-tjänster (Key Vault, ACR, SQL) utan lösenord eller connection strings i koden. Om ingen credential finns i koden kan ingen stjäla den. Den roteras automatiskt av Azure och behöver inte hanteras manuellt.

</details>

6. Du ska lagra en connection string till en produktionsdatabas. Var lagrar du den, och hur kommer appen åt den utan att skriva strängen i koden?

<details markdown="block">
<summary>Visa svar</summary>

Lagra den i **Key Vault** som en Secret. Ge App Service:n rollen **Key Vault Secrets User** via RBAC. Appen hämtar den via `DefaultAzureCredential` som automatiskt använder Managed Identity i Azure-miljö — ingen connection string i koden, ingen `.env`-fil, ingen risk att strängen läcker via git-historiken.

</details>
