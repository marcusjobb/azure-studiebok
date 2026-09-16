---
title: Kubernetes — önskat tillstånd och självläkning
parent: Kubernetes
nav_order: 1
---

# Kubernetes — önskat tillstånd och självläkning

> Läsmaterial för vecka 37. Läs detta efter tisdagens föreläsning.

Kubernetes är komplext. Det här materialet fokuserar på det som faktiskt behövs för att deploya och köra en app — inte hela Kubernetes-universumet. Läs det noggrant, prova kommandona, och använd `kubectl explain [resurs]` när ni undrar vad något fält gör.

---

## Det viktigaste konceptet: önskat tillstånd

Kubernetes arbetar annorlunda mot det mesta annat ni jobbat med.

I Docker skriver ni kommandon: "Starta den här containern."
I Kubernetes beskriver ni ett **önskat tillstånd**: "Jag vill alltid ha tre kopior av den här appen."

Kubernetes läser beskrivningen, jämför med verkligheten, och agerar tills verkligheten matchar. Pod kraschar → Kubernetes startar en ny. Node dör → Kubernetes schemalägger om pods på andra noder. Ni ändrar replicas till 5 → Kubernetes skapar två till.

Det kallas **reconciliation loop** — den kör konstant i bakgrunden.

---

## Arkitektur

```
Cluster
├── Control Plane (hjärnan)
│   ├── API Server      — tar emot kubectl-kommandon, lagrar state
│   ├── Scheduler       — bestämmer vilken node en pod ska köra på
│   ├── Controller Manager — kör reconciliation loops (inkl. ReplicaSet-kontrollern)
│   └── etcd            — distributed key-value store, lagrar all konfiguration
│
└── Worker Nodes (musklerna)
    ├── kubelet         — agent på varje node, tar emot instruktioner från Control Plane
    ├── kube-proxy      — hanterar nätverksregler
    └── Container runtime (containerd) — kör faktiska containers
```

Med **AKS** sköter Azure Control Plane åt er. Ni ser det aldrig. Ni betalar bara för Worker Nodes.

---

## YAML-strukturen — alla resurser ser likadana ut

Alla Kubernetes-resurser har exakt samma grundstruktur:

```yaml
apiVersion: [grupp]/[version]   # Vilken API-grupp och version
kind: [ResursTyp]               # Deployment, Service, ConfigMap, etc.
metadata:
  name: [namn]                  # Unikt inom namespace
  namespace: [namespace]        # Valfritt, default = "default"
  labels:                       # Valfria etiketter — viktiga för selectors
    app: min-app
spec:                           # Det önskade tillståndet — skiljer sig per resurs
  ...
```

När ni är osäkra på vad som går i `spec`:

```bash
kubectl explain deployment.spec
kubectl explain deployment.spec.template.spec.containers
```

`kubectl explain` är er bästa vän när ni lär er Kubernetes.

---

## Pod

Den minsta deployable enheten i Kubernetes. En pod innehåller en eller flera containers som:
- Delar samma nätverksnamn (localhost fungerar mellan containers i samma pod)
- Delar volymer (lagring)
- Alltid körs på samma node

I praktiken: en pod = en körande instans av er app.

```yaml
# Ni skapar sällan pods direkt — men det ser ut så här
apiVersion: v1
kind: Pod
metadata:
  name: min-app-pod
spec:
  containers:
  - name: min-app
    image: nginx:alpine
    ports:
    - containerPort: 80
```

Problemet med direkta pods: ingen startar om dem om de kraschar. Därför använder ni Deployments.

---

## Deployment och ReplicaSet

En **Deployment** är det ni skapar i praktiken. Den hanterar:
1. En **ReplicaSet** — ser till att rätt antal pods alltid körs
2. **Rolling updates** — uppdateringar utan downtime
3. **Rollback** — tillbaka till förra versionen om något går fel

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: min-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: min-app              # Vilka pods äger denna deployment?
  template:                     # Mall för varje pod
    metadata:
      labels:
        app: min-app            # Måste matcha selector ovan
    spec:
      containers:
      - name: min-app
        image: acr.azurecr.io/min-app:v1
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "250m"         # 0.25 CPU-kärnor — Scheduler reserverar detta
            memory: "256Mi"
          limits:
            cpu: "500m"         # Max — överstigs aldrig
            memory: "512Mi"
```

**Varför `resources` är obligatoriskt i prod:**

Utan `requests` vet Schedulern inte hur mycket en pod behöver. Den kan packa 50 pods på en node tills den dör. Med `requests` kan Schedulern fördela pods jämt och säga "nej, den här noden har inte plats för fler."

Om en container överstiger sin `memory` limit: den termineras. `OOMKilled` i `kubectl describe pod`. Det är inte ett fel — det är Kubernetes som skyddar resten av klustret.

---

## Labels och Selectors — limmet som håller ihop allt

Labels är nyckel-värde-par som ni sätter på resurser. De har ingen inbyggd betydelse — ni bestämmer konventionen.

```yaml
labels:
  app: min-app
  version: v1
  environment: prod
```

**Selectors** hittar resurser med specifika labels. En Service med `selector: app: min-app` hittar alla pods med det labelet — oavsett hur många det är eller vilka IP-adresser de har.

Det är så Kubernetes kopplar ihop allt utan hårdkodade namn eller adresser.

---

## Service — stabil nätverksadress

Pods är förgängliga. Deras IP-adresser ändras varje gång de startas om. En Service ger en stabil adress som alltid pekar till rätt pods via labels.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: min-app-service
spec:
  selector:
    app: min-app              # Väljer pods med detta label
  ports:
  - port: 80                  # Porten servicen lyssnar på
    targetPort: 8080          # Porten containern lyssnar på
  type: LoadBalancer          # Publik IP från Azure
```

**Service-typer:**

| Typ | Tillgänglig från | Typisk användning |
|-----|-----------------|-------------------|
| `ClusterIP` | Bara inuti klustret | Intern kommunikation mellan tjänster |
| `NodePort` | Via node-IP + port | Testmiljöer, inte produktion |
| `LoadBalancer` | Publik IP | Internet-exponerade appar |

Med AKS skapar `LoadBalancer` en Azure Load Balancer automatiskt och tilldelar en publik IP.

---

## Liveness och Readiness probes

Två olika frågor som Kubernetes ställer om era containers:

**Liveness:** "Lever containern?" Om nej → starta om den.
**Readiness:** "Är containern redo att ta emot trafik?" Om nej → sluta skicka trafik dit.

```yaml
containers:
- name: min-app
  image: acr.azurecr.io/min-app:v1
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 15   # Vänta 15s efter start innan första kontrollen
    periodSeconds: 20         # Kolla var 20:e sekund
    failureThreshold: 3       # 3 misslyckanden → restart

  readinessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3       # 3 misslyckanden → ta bort från Service
```

**Varför båda?**

Utan readiness probe: under en rolling update skickas trafik till nya pods direkt när processen startar — innan appen är redo. Resulterar i 502-fel för användare.

Med readiness probe: Kubernetes väntar tills `/health` svarar 200 OK innan podden läggs till i Servicens rotation. Noll downtime.

---

## ConfigMap — config utan att röra imagen

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: min-app-config
data:
  ASPNETCORE_ENVIRONMENT: "Production"
  APP_LOG_LEVEL: "Warning"
  APP_REGION: "northeurope"
```

Injicera i deployment:

```yaml
# Som miljövariabler (alla nycklar från ConfigMap)
envFrom:
- configMapRef:
    name: min-app-config

# Eller selektivt
env:
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: min-app-config
      key: APP_LOG_LEVEL
```

Fördelen: ni kan uppdatera konfiguration utan att bygga om Docker-imagen. Ny ConfigMap → ny deploy → ny config.

---

## Rolling update och rollback

```bash
# Uppdatera imagen
kubectl set image deployment/min-app min-app=acr.azurecr.io/min-app:v2

# Eller via kubectl apply med uppdaterad YAML (föredraget i CI/CD)
kubectl apply -f deployment.yaml

# Följ processen
kubectl rollout status deployment/min-app

# Se historiken
kubectl rollout history deployment/min-app

# Rulla tillbaka ett steg
kubectl rollout undo deployment/min-app

# Rulla tillbaka till specifik revision
kubectl rollout undo deployment/min-app --to-revision=2
```

Kubernetes rolling update-strategi (default):
- Starta ny pod
- Vänta tills readiness probe svarar OK
- Ta bort en gammal pod
- Upprepa

`maxSurge: 1` — max 1 extra pod under update (default).
`maxUnavailable: 0` — inga pods får vara nere under update (default). Ändra om ni vill snabbare updates och accepterar kortare tillgänglighetsgap.

---

## Troubleshooting

Det tre vanligaste problemen och hur ni löser dem:

### Pod fastnar i `Pending`

```bash
kubectl describe pod [pod-name]
# Titta på Events-sektionen längst ner
```

Vanliga orsaker:
- `Insufficient cpu/memory` — noderna har inte resurser för pods. Lägg till noder eller minska `resources.requests`.
- `ImagePullBackOff` — k8s kan inte hämta imagen. Fel image-namn, fel credentials till ACR, image finns inte.

### Pod kraschar direkt (`CrashLoopBackOff`)

```bash
kubectl logs [pod-name]                  # Loggar från nuvarande körning
kubectl logs [pod-name] --previous       # Loggar från förra körningen (efter krasch)
kubectl describe pod [pod-name]          # Se exit code och events
```

Exit code 1 = appen kraschade. Exit code 137 = OOMKilled (för lite minne).

### Service når inga pods

```bash
# Verifiera att selector matchar pods
kubectl get pods --show-labels
kubectl describe service [service-name]   # Kolla Endpoints-sektionen

# Inga endpoints = selector matchar inga pods
```

Vanligaste orsaken: labels på pods matchar inte servicens selector. Stavfel.

---

## Namespaces — organisera klustret

Ett kluster kan ha många team och appar. Namespaces separerar dem:

```bash
# Skapa ett namespace
kubectl create namespace min-app-prod

# Applicera resurser till ett namespace
kubectl apply -f deployment.yaml -n min-app-prod

# Lista pods i ett namespace
kubectl get pods -n min-app-prod

# Lista pods i alla namespaces
kubectl get pods --all-namespaces
```

Default namespace är `default`. I produktion: separata namespaces per miljö eller team.

---

## Terminologi v.37

| Term | Förklaring |
|------|------------|
| **pod** | Minsta k8s-enhet — en eller flera containers |
| **node** | VM som kör pods |
| **cluster** | Alla nodes + control plane |
| **control plane** | Hjärnan — API Server, Scheduler, etcd |
| **Deployment** | Deklarerar önskat antal pods och hanterar updates |
| **ReplicaSet** | Håller rätt antal pods igång — hanteras av Deployment |
| **Service** | Stabil nätverksadress till pods via labels |
| **label** | Nyckel-värde-etikett på resurser |
| **selector** | Väljer resurser med specifika labels |
| **rolling update** | Uppdatering en pod i taget — noll downtime |
| **liveness probe** | Är appen vid liv? Om nej → restart |
| **readiness probe** | Är appen redo för trafik? Om nej → ta bort från Service |
| **ConfigMap** | K8s-resurs för konfiguration som injiceras i pods |
| **namespace** | Logisk separation av resurser i ett kluster |
| **resources.requests** | Resurser Scheduler reserverar för en pod |
| **resources.limits** | Max resurser en pod får använda |
| **OOMKilled** | Pod terminerad för att den överskred memory limit |
| **CrashLoopBackOff** | Pod kraschar upprepade gånger — k8s försöker och väntar |
| **reconciliation loop** | K8s konstanta process att matcha önskat mot faktiskt tillstånd |
| `kubectl explain` | Visa dokumentation för ett YAML-fält direkt i terminalen |
