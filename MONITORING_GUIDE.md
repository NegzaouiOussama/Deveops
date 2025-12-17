# 📊 Guide Complet : Prometheus et Grafana

Ce guide explique comment utiliser Prometheus et Grafana pour surveiller votre infrastructure complète.

## 🎯 Vue d'Ensemble

L'architecture de monitoring inclut :

- **Prometheus** : Collecte et stocke les métriques
- **Grafana** : Visualise les métriques avec des dashboards
- **Spring Boot Actuator** : Expose les métriques de l'application
- **Node Exporter** : Collecte les métriques système (CPU, mémoire, disque, réseau)
- **Jenkins** : Expose ses métriques via le plugin Prometheus

## 🚀 Installation Rapide

### Via Script Automatique

```bash
chmod +x deploy-monitoring.sh
./deploy-monitoring.sh
```

### Via Pipeline Jenkins

Le pipeline Jenkins déploie automatiquement Prometheus et Grafana lors de l'exécution.

## 🌐 Accès aux Interfaces

### 1. Prometheus

**URL** : `http://<MINIKUBE_IP>:30909`

**Ou via tunnel** :
```bash
minikube service prometheus -n devops
```

**Fonctionnalités** :
- Rechercher des métriques : Graph → Entrer une métrique → Execute
- Vérifier les targets : Status → Targets
- Exécuter des requêtes PromQL

### 2. Grafana

**URL** : `http://<MINIKUBE_IP>:30300`

**Ou via tunnel** :
```bash
minikube service grafana -n devops
```

**Connexion** :
- Username : `admin`
- Password : `admin`
- ⚠️ Changez le mot de passe au premier login !

## 📊 Métriques Disponibles

### Spring Boot Application

**Endpoint** : `http://<MINIKUBE_IP>:30080/student/actuator/prometheus`

**Métriques principales** :
- `http_server_requests_seconds_count` - Nombre de requêtes HTTP
- `http_server_requests_seconds_sum` - Temps total de réponse
- `jvm_memory_used_bytes` - Mémoire JVM utilisée
- `jvm_threads_live_threads` - Threads actifs
- `hikari_connections_active` - Connexions DB actives
- `process_cpu_usage` - Utilisation CPU

### Système (Node Exporter)

**Métriques principales** :
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemTotal_bytes` - Mémoire totale
- `node_disk_io_time_seconds_total` - I/O disque
- `node_network_receive_bytes_total` - Traffic réseau entrant
- `node_load1`, `node_load5`, `node_load15` - Load average

### Jenkins

**Endpoint** : `http://localhost:8080/prometheus` (depuis la machine hôte)

**Métriques principales** :
- `jenkins_builds_total` - Nombre total de builds
- `jenkins_job_last_build_duration_seconds` - Durée des builds
- `jenkins_executor_count_value` - Nombre d'exécuteurs

## 🎨 Dashboards Grafana

### Dashboard 1 : Spring Boot Application

Visualise :
- Taux de requêtes HTTP
- Temps de réponse (50e et 95e percentile)
- Utilisation mémoire JVM
- Threads actifs
- Connexions base de données
- Utilisation CPU des pods

### Dashboard 2 : System Metrics

Visualise :
- Utilisation CPU
- Utilisation mémoire
- I/O disque
- Traffic réseau
- Load average
- Espace disque

### Dashboard 3 : Jenkins (à créer)

Pour créer un dashboard Jenkins dans Grafana :

1. Grafana → **+** → **Import Dashboard**
2. Utiliser ces requêtes PromQL :

**Builds par minute :**
```promql
rate(jenkins_builds_total[5m])
```

**Durée moyenne des builds :**
```promql
avg(jenkins_job_last_build_duration_seconds)
```

**Taux de réussite :**
```promql
sum(rate(jenkins_builds_total{result="SUCCESS"}[5m])) / sum(rate(jenkins_builds_total[5m])) * 100
```

## 🔍 Requêtes PromQL Utiles

### Application Spring Boot

**Taux de requêtes par endpoint :**
```promql
rate(http_server_requests_seconds_count{application="student-management"}[5m])
```

**Temps de réponse 95e percentile :**
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="student-management"}[5m]))
```

**Mémoire heap utilisée :**
```promql
jvm_memory_used_bytes{application="student-management", area="heap", id="G1 Old Gen"}
```

**Connexions DB actives :**
```promql
hikari_connections_active{application="student-management"}
```

### Système

**CPU usage :**
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Mémoire utilisée :**
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

**Espace disque utilisé :**
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})
```

## 🔧 Configuration Avancée

### Personnaliser la Configuration Prometheus

1. Modifier `k8s/prometheus-config.yaml`
2. Appliquer : `kubectl apply -f k8s/prometheus-config.yaml`
3. Recharger Prometheus :
   ```bash
   kubectl exec -n devops -it $(kubectl get pod -l app=prometheus -n devops -o jsonpath='{.items[0].metadata.name}') -- wget --post-data="" http://localhost:9090/-/reload
   ```

### Ajouter des Dashboards Grafana

1. Créer un dashboard dans Grafana UI
2. Exporter le dashboard (JSON)
3. Ajouter au ConfigMap `grafana-dashboards`

### Persister les Données Grafana

Pour persister les données Grafana entre les redémarrages, modifiez `grafana-deployment.yaml` pour utiliser un PVC au lieu d'`emptyDir`.

## 📋 Checklist de Vérification

- [ ] Prometheus est déployé et accessible
- [ ] Grafana est déployé et accessible
- [ ] Spring Boot expose les métriques sur `/actuator/prometheus`
- [ ] Prometheus peut scraper Spring Boot (Status → Targets)
- [ ] Node Exporter collecte les métriques système
- [ ] Grafana peut se connecter à Prometheus (Configuration → Data Sources)
- [ ] Les dashboards s'affichent correctement
- [ ] Jenkins plugin Prometheus est installé (si applicable)

## 🔗 Liens Utiles

- **Prometheus** : `http://<MINIKUBE_IP>:30909`
- **Grafana** : `http://<MINIKUBE_IP>:30300`
- **Spring Boot Metrics** : `http://<MINIKUBE_IP>:30080/student/actuator/prometheus`
- **Jenkins Metrics** : `http://localhost:8080/prometheus`

## 📝 Notes

- Les métriques Prometheus sont stockées pendant 15 jours (configurable)
- Grafana utilise un volume temporaire (données perdues au redémarrage du pod)
- Pour une persistance, utilisez des PVCs
- Node Exporter nécessite des permissions spéciales (hostNetwork: true)

