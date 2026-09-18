---
title: Swagger och Swashbuckle
description: "Swagger och Swashbuckle i DevOps & CI/CD — Azure studiebok av Marcus Ackre Medina"
parent: DevOps & CI/CD
nav_order: 25
---

# Swagger och Swashbuckle

Swagger är ett av de mest spridda verktygen för att dokumentera REST API:er. I .NET-världen implementeras det via NuGet-paketet **Swashbuckle**, och du kommer stöta på det i de flesta äldre projekt och tutorials. Även om Scalar är det moderna valet för .NET 9, är Swashbuckle fortfarande standard i .NET 8 och bakåt — det är därför viktigt att känna igen och förstå det.

## Varför Swashbuckle?

Tänk dig att du ärvt ett projekt från 2022. Det har ett API med tjugo endpoints. Ingen dokumentation. Du vet inte vad de tar emot, vad de returnerar, eller vilka statuskoder som kan komma. Det är precis den situationen Swashbuckle löser — och varför det finns i nästan varje .NET-projekt du kommer jobba med yrkeslivet.

Swashbuckle genererar en OpenAPI-specifikation (JSON/YAML) automatiskt från din kod och renderar den som ett interaktivt webbgränssnitt på `/swagger`. Därifrån kan du läsa dokumentationen och skicka testanrop direkt i browsern.

## Setup i .NET 8 och äldre projekt

```bash
dotnet add package Swashbuckle.AspNetCore
```

I `Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer(); // behövs för minimal API
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();       // /swagger/v1/swagger.json
    app.UseSwaggerUI();     // /swagger
}

app.Run();
```

Starta appen och öppna `http://localhost:5000/swagger` — Swagger UI läser in spec-filen automatiskt och visar alla dina endpoints.

## URL-struktur

| Vad | URL |
|-----|-----|
| Swagger UI | `/swagger` |
| OpenAPI-spec (JSON) | `/swagger/v1/swagger.json` |

Spec-filen är det du delar med frontend-teamet, importerar i Postman, eller validerar mot i en CI/CD-pipeline.

## Dokumentera endpoints

I minimal API-stil fungerar Swashbuckle på samma sätt som Scalar — du använder `.WithTags()`, `.WithSummary()` och `.Produces<T>()`:

```csharp
app.MapGet("/api/produkter/{id}", (int id) =>
{
    var p = produkter.FirstOrDefault(p => p.Id == id);
    return p is null ? Results.NotFound() : Results.Ok(p);
})
.WithName("HamtaProdukt")
.WithTags("Produkter")
.WithSummary("Hämta en produkt på ID")
.Produces<Produkt>(200)
.Produces(404);
```

### XML-kommentarer i controller-stil

I äldre controller-baserade projekt (inte minimal API) är XML-kommentarer vanliga. De kräver lite extra konfiguration men ger rik dokumentation:

Lägg till i `.csproj`:
```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
</PropertyGroup>
```

Konfigurera Swagger att läsa XML:

```csharp
builder.Services.AddSwaggerGen(c =>
{
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    c.IncludeXmlComments(xmlPath);
});
```

Sedan kommenterar du dina actions direkt:

```csharp
/// <summary>
/// Hämtar en produkt på ID.
/// </summary>
/// <param name="id">Produktens ID</param>
/// <returns>Produktobjektet, eller 404 om den inte finns</returns>
[HttpGet("{id}")]
[ProducesResponseType(typeof(Produkt), 200)]
[ProducesResponseType(404)]
public IActionResult HamtaProdukt(int id) { ... }
```

I minimal API-projekt behövs inte XML-kommentarer — `.WithSummary()` och `.WithDescription()` fyller samma funktion på ett renare sätt.

## Swagger vs Scalar

| | Swagger UI (Swashbuckle) | Scalar |
|--|--|--|
| Status | Äldre, underhålls sämre | Aktivt underhållet |
| .NET 9 | Inte inbyggt | Microsofts rekommendation |
| Utseende | Klassiskt | Modernt, dark mode |
| Setup | Eget NuGet + konfiguration | Ett NuGet, tre rader |
| Finns i äldre projekt | ✓ Vanligt | Sällsynt |

Tumregeln: **Scalar för ny kod, Swashbuckle för att förstå och jobba med legacy-projekt**. Båda genererar OpenAPI-specifikationer i samma format — det är bara UI:t och setup-komplexiteten som skiljer.

## Importera spec i Postman

En av de praktiska sakerna med Swashbuckle är att OpenAPI-JSON-filen kan importeras direkt i Postman:

1. Starta appen
2. Öppna Postman → **Import** → välj **Link**
3. Klistra in `http://localhost:5000/swagger/v1/swagger.json`
4. Postman skapar en komplett collection med alla endpoints och exempeldata

Det sparar tid när du testar ett nytt API eller onboardar en kollega — de behöver inte bygga upp alla anrop för hand.

## Sammanfattning

Du stöter på Swashbuckle i äldre .NET-projekt — nu vet du hur det funkar. Setup är lite mer än Scalar, men principen är densamma: OpenAPI beskriver API:t, Swagger UI visar det. Spec-filen kan importeras i Postman och delas med konsumenter. För ny .NET 9-kod: välj Scalar. För legacy: lär dig läsa Swashbuckle-konfigurationen utan att bli förvirrad.
