---
title: Testa dig själv
description: "Testa dig själv i DevOps & CI/CD — Azure studiebok av Marcus Ackre Medina"
parent: DevOps & CI/CD
nav_order: 99
---

# Testa dig själv — DevOps & CI/CD

1. Vad är skillnaden mellan Continuous Delivery och Continuous Deployment?

<details markdown="block">
<summary>Visa svar</summary>

**Continuous Delivery:** koden deployas automatiskt till staging men kräver ett manuellt godkännande för att gå vidare till produktion.

**Continuous Deployment:** grön pipeline = appen är live i produktion automatiskt, utan manuell åtgärd. Kräver hög testtäckning och mogna team. De flesta team börjar med Delivery och inför Deployment när förtroendet för testerna är tillräckligt högt.

</details>

2. Varför versionshanteras en Azure DevOps-pipeline som en YAML-fil i repot — inte i portalen?

<details markdown="block">
<summary>Visa svar</summary>

En YAML-pipeline i repot är versionshanterad precis som koden: du ser exakt vad som ändrades, när och av vem. Du kan code-reviewa pipeline-ändringar i en PR. Du kan rulla tillbaka till en tidigare version. En pipeline konfigurerad enbart i portalen är osynlig i git-historiken och svår att reproducera.

</details>

3. Vad är ett Deployment Slot och varför eliminerar ett swap downtime?

<details markdown="block">
<summary>Visa svar</summary>

Ett Deployment Slot är en separat "miljö" inom samma App Service (t.ex. `staging`). Du deployer och värmer upp appen i staging. När den är redo gör du ett **swap** som byter staging och production med en enda atomär operation — gamla production blir staging, nya versionen tar över production. Ingen omstart, ingen downtime.

</details>

4. Vad är skillnaden mellan ARM-mallar och Bicep — och varför väljer de flesta Bicep?

<details markdown="block">
<summary>Visa svar</summary>

**ARM** är Azures interna format — JSON-filer som är ordrika, svårlästa och svåra att skriva för hand. **Bicep** är ett DSL som kompileras till ARM. Du skriver läsbar Bicep, Azure kör ARM. Bicep ger parametrar, variabler, moduler och outputs med minimal boilerplate. Du behöver aldrig se ARM-JSON om du inte vill.

</details>

5. Vad är problemet med "click ops" — att bygga infrastruktur manuellt i Azure Portal?

<details markdown="block">
<summary>Visa svar</summary>

Click ops är inte reproducerbart: du kan inte exakt återskapa vad du klickade på. Det är inte reviderbart: det finns ingen git-historik för vad som ändrades. Det är inte skalbart: om en kollega ska göra samma sak i en annan region kan du bara visa skärmbilder. Infrastructure as Code löser alla tre problemen — samma infrastruktur, varje gång, från en fil du kan code-reviewa.

</details>

6. Du har en REST API-endpoint. Varför ska du lägga till `.Produces<T>(200).Produces(404)` i din Minimal API-definition?

<details markdown="block">
<summary>Visa svar</summary>

OpenAPI/Swagger läser de deklarerade statuskoderna och svarskropparna för att bygga den interaktiva dokumentationen. Utan dem vet Swagger UI inte vilka svar endpointen kan returnera. En väldekorerad endpoint ger API-konsumenter (frontend, mobilapp, annan tjänst) exakt det de behöver för att integrera korrekt — utan att gissa eller läsa källkoden.

</details>
