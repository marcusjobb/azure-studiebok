---
title: Testa dig själv
parent: Kubernetes
nav_order: 99
---

# Testa dig själv — Kubernetes

1. Vad menas med att Kubernetes arbetar med "önskat tillstånd" — och vad är en reconciliation loop?

<details>
<summary>Visa svar</summary>

I stället för att skicka kommandon ("starta den här containern") beskriver du vad du vill ha ("jag vill alltid ha tre kopior"). Kubernetes jämför det önskade tillståndet med verkligheten och agerar tills de matchar. Det kallas reconciliation loop och kör konstant i bakgrunden. Pod kraschar → K8s startar en ny. Du ändrar `replicas: 5` → K8s skapar två till.

</details>

2. Varför skapar man sällan en Pod direkt — vad används istället och varför?

<details>
<summary>Visa svar</summary>

Direkta pods startas inte om om de kraschar. En **Deployment** hanterar en ReplicaSet som garanterar att rätt antal pods alltid körs, hanterar rolling updates utan downtime och gör rollback möjlig. I praktiken: skapa alltid en Deployment, aldrig en direktpod i produktion.

</details>

3. Vad är skillnaden mellan liveness probe och readiness probe?

<details>
<summary>Visa svar</summary>

**Liveness:** "Lever appen?" Om nej → starta om containern. Fångar upp att appen fastnat i ett trasigt tillstånd.

**Readiness:** "Är appen redo för trafik?" Om nej → ta bort containern från Servicens rotation. Kritiskt under rolling updates — trafik skickas inte till en ny pod förrän `/health` svarar 200 OK.

Utan readiness probe: 502-fel under uppdateringar. Utan liveness probe: fastnade containrar hänger kvar utan att startas om.

</details>

4. Vad händer om du glömmer `resources.requests` på en container i en Deployment?

<details>
<summary>Visa svar</summary>

Schedulern vet inte hur mycket resurser containern behöver och kan packa 50 pods på en nod tills den kollapsar. Med `requests` reserverar Schedulern utrymme och kan säga "den här noden har inte plats". Om `limits` sätts och en container överstiger minnesgränsen termineras den med `OOMKilled` — det är K8s som skyddar resten av klustret.

</details>

5. Pod-IP:er ändras varje gång en pod startas om. Hur hanterar Kubernetes det problemet?

<details>
<summary>Visa svar</summary>

Med en **Service** — en stabil nätverksadress som alltid pekar till rätt pods via labels/selectors. Servicen hittar pods med ett specifikt label (`app: min-app`) oavsett hur många de är eller vilka IP-adresser de har just nu. En `LoadBalancer`-service i AKS skapar en Azure Load Balancer med publik IP automatiskt.

</details>

6. En pod fastnar i `CrashLoopBackOff`. Vad är dina första tre felsökningssteg?

<details>
<summary>Visa svar</summary>

```bash
# 1. Se loggarna från förra körningen (innan kraschen)
kubectl logs [pod-name] --previous

# 2. Kolla exit-koden och events
kubectl describe pod [pod-name]
# Exit 1 = appen kraschade. Exit 137 = OOMKilled (för lite minne).

# 3. Kolla om imagen hämtas korrekt
# Events-sektionen visar ImagePullBackOff om det är ett credentials- eller namnproblem
```

Vanligaste orsaker: appen kraschar vid start (konfigurationsfel), OOMKilled (öka `resources.limits.memory`), eller imagen kan inte hämtas från ACR.

</details>
