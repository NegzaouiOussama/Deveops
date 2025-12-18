# 📊 Guide Complet : Prometheus et Grafana - Démarrage Automatique

Ce guide explique comment configurer Prometheus et Grafana pour qu'ils démarrent automatiquement dans WSL sans ouvrir de PowerShell.

## 🎯 Vue d'Ensemble

L'architecture de monitoring inclut :

- **Prometheus** : Collecte et stocke les métriques (déployé dans Kubernetes)
- **Grafana** : Visualise les métriques avec des dashboards (déployé dans Kubernetes)
- **Node Exporter WSL** : Collecte les métriques système Ubuntu/WSL (service systemd)
- **Spring Boot Actuator** : Expose les métriques de l'application Spring Boot
- **Jenkins** : Expose ses métriques via le plugin Prometheus

## 🚀 Installation et Configuration

### Étape 1 : Installation du Démarrage Automatique

Dans WSL, exécutez :

```bash
cd ~/Documents/GitHub/Deveops
chmod +x install-auto-start.sh
./install-auto-start.sh
```

Ce script va :
1. ✅ Rendre le script de démarrage exécutable
2. ✅ Créer un service systemd `prometheus-grafana.service`
3. ✅ Activer le démarrage automatique au boot de WSL
4. ✅ Démarrer Prometheus et Grafana immédiatement

### Étape 2 : Vérification

Vérifiez que le service est actif :

```bash
sudo systemctl status prometheus-grafana
```

Vérifiez que Node Exporter WSL est actif :

```bash
sudo systemctl status node_exporter
```

Vérifiez que les pods Kubernetes sont prêts :

```bash
kubectl get pods -n devops | grep -E "prometheus|grafana|node-exporter"
```

## 📊 Accès aux Interfaces

### Prometheus

**URL** : `http://<MINIKUBE_IP>:30909`

**Ou via tunnel** :
```bash
minikube service prometheus -n devops
```

**Fonctionnalités** :
- Rechercher des métriques : Graph → Entrer une métrique → Execute
- Vérifier les targets : Status → Targets
- Exécuter des requêtes PromQL

### Grafana

**URL** : `http://<MINIKUBE_IP>:30300`

**Ou via tunnel** :
```bash
minikube service grafana -n devops
```

**Connexion** :
- Username : `admin`
- Password : `admin`
- ⚠️ Changez le mot de passe au premier login !

**Dashboards disponibles** :
1. **📊 Dashboard Complet - DevOps Monitoring** : Vue d'ensemble de toutes les métriques
2. **Spring Boot Application Metrics** : Métriques détaillées de l'application Spring Boot
3. **Jenkins Metrics** : Métriques Jenkins (builds, durée, succès/échecs)
4. **System Metrics (Node Exporter)** : Métriques système Ubuntu/WSL

## 🔧 Métriques Collectées

### 1. Métriques Ubuntu/WSL (Node Exporter)

- **CPU Usage** : Utilisation CPU de la machine WSL
- **Memory Usage** : Utilisation mémoire
- **Disk Usage** : Utilisation disque
- **Network Traffic** : Trafic réseau (réception/émission)
- **Load Average** : Charge système (1min, 5min, 15min)
- **Disk I/O** : Activité disque

**Endpoint** : `http://<WSL_IP>:9100/metrics`

### 2. Métriques Jenkins

- **Builds Rate** : Taux de builds par minute
- **Build Success Rate** : Taux de succès des builds
- **Build Duration** : Durée des builds
- **Total Builds** : Nombre total de builds
- **Failed Builds** : Nombre de builds échoués
- **Active Executors** : Nombre d'exécuteurs actifs

**Endpoint** : `http://<WSL_IP>:8080/prometheus`

**Prérequis** : Le plugin "Prometheus metrics plugin" doit être installé dans Jenkins.

### 3. Métriques Spring Boot (Actuator)

- **HTTP Requests Rate** : Taux de requêtes HTTP
- **HTTP Response Time** : Temps de réponse (50th, 95th percentile)
- **JVM Memory Usage** : Utilisation mémoire JVM
- **Active Threads** : Threads actifs
- **Database Connections** : Connexions DB (actives/idle)
- **CPU Usage** : Utilisation CPU du processus

**Endpoint** : `http://<MINIKUBE_IP>:30080/student/actuator/prometheus`

## 🛠️ Commandes Utiles

### Gestion du Service

```bash
# Vérifier le statut
sudo systemctl status prometheus-grafana

# Voir les logs
sudo journalctl -u prometheus-grafana -f

# Redémarrer le service
sudo systemctl restart prometheus-grafana

# Désactiver le démarrage automatique
sudo systemctl disable prometheus-grafana

# Activer le démarrage automatique
sudo systemctl enable prometheus-grafana
```

### Gestion de Node Exporter WSL

```bash
# Vérifier le statut
sudo systemctl status node_exporter

# Voir les logs
sudo journalctl -u node_exporter -f

# Redémarrer
sudo systemctl restart node_exporter
```

### Vérification des Pods Kubernetes

```bash
# Voir tous les pods de monitoring
kubectl get pods -n devops | grep -E "prometheus|grafana|node-exporter"

# Voir les logs Prometheus
kubectl logs -n devops -l app=prometheus --tail=50

# Voir les logs Grafana
kubectl logs -n devops -l app=grafana --tail=50

# Redémarrer Prometheus
kubectl rollout restart deployment/prometheus -n devops

# Redémarrer Grafana
kubectl rollout restart deployment/grafana -n devops
```

### Vérification des Targets Prometheus

```bash
# Obtenir l'IP Minikube
MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Vérifier les targets
curl http://${MINIKUBE_IP}:30909/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'
```

## 🔍 Dépannage

### Prometheus ne démarre pas

1. Vérifier que Minikube est démarré :
   ```bash
   minikube status
   ```

2. Vérifier les logs :
   ```bash
   kubectl logs -n devops -l app=prometheus --tail=50
   ```

3. Vérifier la configuration :
   ```bash
   kubectl get configmap prometheus-config -n devops -o yaml
   ```

### Grafana ne démarre pas

1. Vérifier les logs :
   ```bash
   kubectl logs -n devops -l app=grafana --tail=50
   ```

2. Vérifier que Prometheus est accessible depuis Grafana :
   ```bash
   kubectl exec -n devops -it $(kubectl get pod -n devops -l app=grafana -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://prometheus:9090/api/v1/status/config
   ```

### Node Exporter WSL ne fonctionne pas

1. Vérifier que le service est actif :
   ```bash
   sudo systemctl status node_exporter
   ```

2. Vérifier que le port 9100 est accessible :
   ```bash
   curl http://localhost:9100/metrics | head -20
   ```

3. Vérifier les logs :
   ```bash
   sudo journalctl -u node_exporter -f
   ```

### Jenkins métriques non disponibles

1. Vérifier que le plugin Prometheus est installé dans Jenkins
2. Vérifier que l'endpoint est accessible :
   ```bash
   curl http://<WSL_IP>:8080/prometheus | head -20
   ```
3. Si l'endpoint nécessite une authentification, configurer Prometheus avec les credentials

### Les métriques Ubuntu/WSL n'apparaissent pas dans Grafana

1. Vérifier que Node Exporter WSL est actif et accessible
2. Vérifier que Prometheus peut scraper Node Exporter :
   - Aller dans Prometheus → Status → Targets
   - Vérifier que `node-exporter-wsl` est `UP`
3. Vérifier l'IP WSL dans la configuration Prometheus :
   ```bash
   kubectl get configmap prometheus-config -n devops -o yaml | grep -A 5 "node-exporter-wsl"
   ```

## 📝 Notes Importantes

1. **Mot de passe sudo** : Le script utilise le mot de passe `00000000` pour les opérations sudo. Si votre mot de passe est différent, modifiez la variable `SUDO_PASSWORD` dans `start-prometheus-grafana.sh`.

2. **IP WSL** : L'IP WSL est détectée automatiquement au démarrage. Si elle change, le script la met à jour automatiquement dans la configuration Prometheus.

3. **Démarrage automatique** : Le service systemd démarre automatiquement au boot de WSL. Si vous redémarrez WSL, Prometheus et Grafana redémarreront automatiquement.

4. **Pipeline Jenkins** : Le pipeline Jenkins déploie également Prometheus et Grafana. Le service systemd garantit qu'ils sont toujours disponibles même si le pipeline n'a pas été exécuté récemment.

## 🎉 Résultat

Une fois configuré, vous aurez :

- ✅ Prometheus et Grafana qui démarrent automatiquement au démarrage de WSL
- ✅ Node Exporter qui collecte les métriques Ubuntu/WSL
- ✅ Dashboards Grafana pour visualiser toutes les métriques
- ✅ Métriques de Jenkins, Ubuntu/WSL, et Spring Boot Actuator
- ✅ Aucun besoin d'ouvrir PowerShell pour démarrer les services

## 📚 Ressources

- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Grafana](https://grafana.com/docs/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

