---
title: Scalar och OpenAPI
parent: DevOps & CI/CD
nav_order: 20
---

# Scalar och OpenAPI

När du bygger ett API behöver någon annan veta hur man använder det. Vilka endpoints finns? Vad returnerar de? Vad händer om ett värde saknas? Utan dokumentation uppstår frågor, långa Slack-trådar och misstag. OpenAPI och Scalar löser det — automatiskt och interaktivt.

## Vad är OpenAPI?

OpenAPI är ett öppet standardformat för att beskriva REST API:er. Det är en JSON- eller YAML-fil som exakt specificerar vilka endpoints som finns, vad de tar emot, vad de returnerar och vilka HTTP-statuskoder som kan dyka upp.

```json
{
  "paths": {
    "/api/produkter/{id}": {
      "get": {
        "summary": "Hämta en produkt på ID",
        "responses": { "200": {...}, "404": {...} }
      }
    }
  }
}
```

Den här filen genereras automatiskt av ditt .NET-projekt. Verktyg som Scalar renderar den sedan som en interaktiv webbsida där konsumenter kan läsa, utforska och testa ditt API direkt i browsern.

## Swagger UI vs Scalar

Du kommer stöta på båda verktygen i arbetslivet. Här är skillnaden:

| | Swagger UI (Swashbuckle) | Scalar |
|--|--|--|
| Status | Äldre, underhålls sämre | Aktivt underhållet |
| .NET 9 | Inte inbyggt | Microsofts rekommendation |
| Utseende | Klassiskt | Modernt, dark mode |
| Setup | Eget NuGet + konfiguration | Ett NuGet, tre rader |
| Finns i äldre projekt | Vanligt | Sällsynt |

Tumregel: välj **Scalar för ny kod** och lär dig läsa Swagger UI för att förstå äldre projekt.

## Setup — tre rader

Installera NuGet-paketet:

```bash
dotnet add package Scalar.AspNetCore
```

Lägg till tre rader i `Program.cs`:

```csharp
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();      // inbyggt i .NET 9 — ingen extra NuGet

var app = builder.Build();

app.MapOpenApi();                   // publicerar /openapi/v1.json
app.MapScalarApiReference();        // publicerar /scalar/v1

app.Run();
```

Starta appen och öppna `http://localhost:5000/scalar/v1` — Scalar UI visas direkt.

## Dokumentera endpoints

En odokumenterad endpoint visar bara sin URL i Scalar. Med några metodanrop får konsumenten full information om vad endpointen gör, vad den returnerar och vilka felfall som finns.

```csharp
// Utan dokumentation — Scalar visar bara URL:en
app.MapGet("/api/produkter/{id}", (int id) => ...);

// Med dokumentation — Scalar visar allt
app.MapGet("/api/produkter/{id}", (int id) =>
{
    var p = produkter.FirstOrDefault(p => p.Id == id);
    return p is null ? Results.NotFound() : Results.Ok(p);
})
.WithName("HamtaProdukt")
.WithTags("Produkter")                // grupperingslabel i UI
.WithSummary("Hämta en produkt")      // kort beskrivning
.Produces<Produkt>(200)               // visar response-schemat med alla fält
.Produces(404);                       // dokumenterar felfall
```

Vad de olika metoderna gör:

| Metod | Vad Scalar visar |
|-------|-----------------|
| `.WithTags("X")` | Grupperar endpoints under rubriken X |
| `.WithSummary("...")` | Kort beskrivning bredvid endpoint-namnet |
| `.WithDescription("...")` | Längre förklaring i expanderat läge |
| `.Produces<T>(200)` | Response-schema med alla fält och typer |
| `.Produces(404)` | Dokumenterar felkod utan schema |
| `.WithName("X")` | Unikt namn — används vid länkning och kodgenerering |

Använd alltid `.Produces<T>()` med en konkret typ för 200-svar — annars ser konsumenten bara "200 OK" utan att veta vilka fält som faktiskt returneras.

## Komplett exempel

```csharp
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();

var app = builder.Build();
app.MapOpenApi();
app.MapScalarApiReference();

var produkter = new List<Produkt>
{
    new(1, "Laptop", 12999),
    new(2, "Mus", 299)
};

app.MapGet("/api/produkter", () => Results.Ok(produkter))
    .WithTags("Produkter")
    .WithSummary("Hämta alla produkter")
    .Produces<List<Produkt>>(200);

app.MapGet("/api/produkter/{id}", (int id) =>
{
    var p = produkter.FirstOrDefault(p => p.Id == id);
    return p is null ? Results.NotFound() : Results.Ok(p);
})
.WithTags("Produkter")
.WithSummary("Hämta en produkt på ID")
.Produces<Produkt>(200)
.Produces(404);

record Produkt(int Id, string Namn, decimal Pris);

app.Run();
```

## Development vs produktion

För ett internt API som bara ni själva använder är det vanligt att bara exponera Scalar i Development-miljön:

```csharp
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}
```

För ett publikt API där externa konsumenter ska kunna läsa dokumentationen registreras det alltid — men kan skyddas med autentisering vid behov:

```csharp
// Alltid tillgänglig — skydda med auth om det behövs
app.MapOpenApi();
app.MapScalarApiReference();
```

## URL-översikt

| Vad | URL |
|-----|-----|
| Scalar UI | `/scalar/v1` |
| OpenAPI-spec (JSON) | `/openapi/v1.json` |
| Swagger UI (om Swashbuckle) | `/swagger` |
| OpenAPI-spec (Swashbuckle) | `/swagger/v1/swagger.json` |

OpenAPI JSON-filen är inte bara för visning. Du kan:

- **Importera i Postman** — testa alla endpoints direkt utan att skriva om dem
- **Generera klientkod** med Kiota eller NSwag — automatisk SDK för konsumenten
- **Validera mot kontraktet i CI/CD** — pipeline misslyckas om en ny version bryter mot specen

## Swashbuckle — för äldre projekt och .NET 8

Swashbuckle (Swagger) var standardverktyget i .NET 8 och tidigare och finns i de flesta äldre kodbasers. Det är viktigt att känna till:

```bash
dotnet add package Swashbuckle.AspNetCore
```

```csharp
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

app.UseSwagger();
app.UseSwaggerUI();   // öppnar /swagger
```

Swagger UI på `/swagger`, OpenAPI-spec på `/swagger/v1/swagger.json`. Fungerar fortfarande och du kommer se det i befintliga projekt — men välj Scalar för ny kod.

---

> *"En endpoint utan dokumentation är ett löfte ingen vet om."*
