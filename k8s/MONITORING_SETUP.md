# 📊 Guide d'Installation de Prometheus et Grafana

Ce guide explique comment déployer et configurer Prometheus et Grafana pour surveiller votre infrastructure et applications.

## 🎯 Architecture

```
Spring Boot App (Actuator) ──┐
                              ├──> Prometheus ──> Grafana
Jenkins (Metrics) ────────────┘
Node Exporter (System) ───────┘
```

## 📋 Prérequis

- Kubernetes (Minikube) en cours d'exécution
- `kubectl` configuré
- Namespace `devops` créé

## 🚀 Installation

### Option 1 : Via Pipeline Jenkins (Recommandé)

Le pipeline Jenkins déploie automatiquement Prometheus et Grafana. Il suffit de relancer le pipeline.

### Option 2 : Installation Manuelle

```bash
# Déployer Prometheus
kubectl apply -f k8s/prometheus-config.yaml
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus-service.yaml

# Déployer Node Exporter (métriques système)
kubectl apply -f k8s/node-exporter-deployment.yaml

# Déployer Grafana
kubectl apply -f k8s/grafana-datasources.yaml
kubectl apply -f k8s/grafana-dashboards.yaml
kubectl apply -f k8s/grafana-deployment.yaml
kubectl apply -f k8s/grafana-service.yaml

# Vérifier le déploiement
kubectl get pods -n devops
kubectl get services -n devops
```

## 🌐 Accès aux Services

### Obtenir les URLs

```bash
export MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
export PROMETHEUS_PORT=$(kubectl get service prometheus -n devops -o jsonpath='{.spec.ports[0].nodePort}')
export GRAFANA_PORT=$(kubectl get service grafana -n devops -o jsonpath='{.spec.ports[0].nodePort}')

echo "Prometheus: http://${MINIKUBE_IP}:${PROMETHEUS_PORT}"
echo "Grafana: http://${MINIKUBE_IP}:${GRAFANA_PORT}"
```

### Utiliser Minikube Service (Tunnel)

```bash
# Prometheus
minikube service prometheus -n devops

# Grafana
minikube service grafana -n devops
```

## 🔐 Connexion Grafana

- **URL** : `http://<MINIKUBE_IP>:30300` (ou via tunnel)
- **Username** : `admin`
- **Password** : `admin`
- ⚠️ **Changez le mot de passe au premier login !**

## 📊 Dashboards Disponibles

### 1. Spring Boot Application Metrics

**Métriques surveillées :**
- Taux de requêtes HTTP
- Temps de réponse HTTP (percentiles 50 et 95)
- Utilisation mémoire JVM
- Threads actifs
- Connexions base de données (HikariCP)
- Utilisation CPU des pods

### 2. System Metrics (Node Exporter)

**Métriques surveillées :**
- Utilisation CPU
- Utilisation mémoire
- I/O disque
- Traffic réseau
- Load average
- Espace disque utilisé

### 3. Jenkins Metrics

Pour intégrer Jenkins, vous devez installer le plugin Prometheus dans Jenkins :
1. Jenkins → Manage Jenkins → Plugins
2. Rechercher "Prometheus Metrics Plugin"
3. Installer et redémarrer Jenkins
4. Les métriques seront disponibles sur `http://<jenkins-url>/prometheus`

## 🔍 Vérification

### Vérifier que Prometheus scrape les métriques

1. Accéder à Prometheus : `http://<MINIKUBE_IP>:30909`
2. Aller dans **Status → Targets**
3. Vérifier que tous les targets sont `UP` :
   - `spring-boot-app`
   - `node-exporter`
   - `prometheus`

### Tester les métriques Spring Boot

```bash
# Depuis WSL
curl http://192.168.49.2:30080/student/actuator/prometheus | head -20
```

Vous devriez voir des métriques au format Prometheus comme :
```
http_server_requests_seconds_count{application="student-management",...}
jvm_memory_used_bytes{application="student-management",...}
```

## 📈 Créer un Dashboard Personnalisé dans Grafana

1. Se connecter à Grafana
2. Cliquer sur **+** → **Create Dashboard**
3. Ajouter des panels avec des requêtes PromQL

### Exemples de Requêtes PromQL

**Requêtes HTTP par seconde :**
```promql
rate(http_server_requests_seconds_count{application="student-management"}[5m])
```

**Temps de réponse 95e percentile :**
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="student-management"}[5m]))
```

**Mémoire JVM utilisée :**
```promql
jvm_memory_used_bytes{application="student-management", area="heap"}
```

## 🔧 Configuration Prometheus

Le fichier `k8s/prometheus-config.yaml` contient la configuration Prometheus. Les principales sections :

- **scrape_interval** : Fréquence de collecte (15s)
- **scrape_configs** : Liste des cibles à scraper

Pour modifier la configuration :
1. Modifier `k8s/prometheus-config.yaml`
2. Appliquer : `kubectl apply -f k8s/prometheus-config.yaml`
3. Recharger Prometheus : `kubectl exec -n devops -it <prometheus-pod> -- wget --post-data="" http://localhost:9090/-/reload`

## 🐛 Dépannage

### Prometheus ne scrape pas l'application

1. Vérifier que l'application expose les métriques :
   ```bash
   kubectl exec -n devops <app-pod> -- wget -qO- http://localhost:8089/student/actuator/prometheus | head -10
   ```

2. Vérifier la configuration Prometheus :
   ```bash
   kubectl get configmap prometheus-config -n devops -o yaml
   ```

3. Vérifier les logs Prometheus :
   ```bash
   kubectl logs -n devops -l app=prometheus --tail=50
   ```

### Grafana ne peut pas se connecter à Prometheus

1. Vérifier que Prometheus est accessible depuis Grafana :
   ```bash
   kubectl exec -n devops <grafana-pod> -- wget -qO- http://prometheus:9090/api/v1/status/config
   ```

2. Vérifier la configuration de la datasource :
   ```bash
   kubectl get configmap grafana-datasources -n devops -o yaml
   ```

### Node Exporter ne fonctionne pas

Node Exporter nécessite des permissions spéciales. Si les métriques système ne s'affichent pas :

1. Vérifier que le DaemonSet est déployé :
   ```bash
   kubectl get daemonset node-exporter -n devops
   ```

2. Vérifier les logs :
   ```bash
   kubectl logs -n devops -l app=node-exporter --tail=50
   ```

## 📚 Ressources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer Prometheus](https://micrometer.io/docs/registry/prometheus)

