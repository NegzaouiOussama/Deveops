# 🔧 Configuration de Jenkins avec Prometheus

Ce guide explique comment configurer Jenkins pour exporter des métriques Prometheus.

## 📦 Installation du Plugin Prometheus dans Jenkins

### Étape 1 : Installer le Plugin

1. Ouvrez Jenkins : `http://localhost:8080` (ou votre URL Jenkins)
2. Allez dans **Manage Jenkins** → **Plugins** (ou **Manage Plugins**)
3. Cliquez sur **Available plugins**
4. Recherchez **"Prometheus metrics"** ou **"Prometheus Plugin"**
5. Cochez la case et cliquez sur **Install without restart**
6. Après l'installation, redémarrez Jenkins si nécessaire

### Étape 2 : Vérifier l'Activation

1. Allez dans **Manage Jenkins** → **System**
2. Cherchez la section **Prometheus**
3. Vérifiez que le plugin est activé
4. L'endpoint des métriques sera disponible sur : `http://<jenkins-url>/prometheus`

### Étape 3 : Tester l'Endpoint

```bash
# Depuis WSL ou votre machine
curl http://localhost:8080/prometheus | head -20
```

Vous devriez voir des métriques au format Prometheus.

## 🔗 Configuration de Prometheus pour Scraper Jenkins

### Option 1 : Jenkins dans Kubernetes

Si Jenkins est déployé dans Kubernetes, mettez à jour `prometheus-config.yaml` :

```yaml
- job_name: 'jenkins'
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - default  # ou le namespace où Jenkins est déployé
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app]
      action: keep
      regex: jenkins
    - source_labels: [__meta_kubernetes_pod_ip]
      action: replace
      target_label: __address__
      replacement: '${1}:8080'
    - source_labels: [__meta_kubernetes_pod_name]
      target_label: pod_name
```

### Option 2 : Jenkins en dehors de Kubernetes

Si Jenkins est sur la machine hôte (comme dans votre cas), utilisez la configuration statique dans `prometheus-config.yaml` :

```yaml
- job_name: 'jenkins'
  static_configs:
    - targets: ['host.docker.internal:8080']  # Depuis Minikube
      labels:
        job: 'jenkins'
        service: 'jenkins'
  metrics_path: '/prometheus'
```

**Note** : Vous devrez peut-être ajuster l'IP selon votre configuration Minikube.

## 📊 Métriques Jenkins Disponibles

Le plugin Prometheus expose de nombreuses métriques :

- `jenkins_builds_total` - Nombre total de builds
- `jenkins_executor_count_value` - Nombre d'exécuteurs
- `jenkins_job_last_build_duration_seconds` - Durée du dernier build
- `jenkins_job_last_build_timestamp_seconds` - Timestamp du dernier build
- `jenkins_node_builds_total` - Builds par node
- `jenkins_plugins_plugin_version` - Versions des plugins
- Et bien plus...

## 🎨 Dashboard Grafana pour Jenkins

Créez un dashboard dans Grafana avec ces requêtes PromQL :

**Nombre de builds par minute :**
```promql
rate(jenkins_builds_total[5m])
```

**Durée moyenne des builds :**
```promql
avg(jenkins_job_last_build_duration_seconds)
```

**Taux de réussite des builds :**
```promql
sum(rate(jenkins_builds_total{result="SUCCESS"}[5m])) / sum(rate(jenkins_builds_total[5m]))
```

## 🔍 Vérification

1. Vérifier que Prometheus peut scraper Jenkins :
   - Prometheus UI → Status → Targets
   - Vérifier que `jenkins` est `UP`

2. Tester les métriques dans Prometheus :
   - Prometheus UI → Graph
   - Entrer : `jenkins_builds_total`
   - Cliquer sur Execute

3. Visualiser dans Grafana :
   - Grafana → Dashboards → Import
   - Créer un nouveau dashboard avec les requêtes ci-dessus

