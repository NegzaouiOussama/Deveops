# 🚀 Guide : Démarrer le Pipeline Jenkins pour Prometheus et Grafana

Ce guide explique comment démarrer le pipeline Jenkins pour intégrer et déployer Prometheus et Grafana avec toutes les métriques.

## 📋 Prérequis

Avant de démarrer le pipeline, assurez-vous que :

- ✅ **Jenkins est démarré** et accessible (http://localhost:8080 ou votre IP WSL)
- ✅ **Minikube est démarré** : `minikube status`
- ✅ **kubectl est configuré** et fonctionne : `kubectl get nodes`
- ✅ **Le service systemd est installé** (optionnel, pour démarrage automatique) : `sudo systemctl status prometheus-grafana`

## 🎯 Méthode 1 : Via l'Interface Jenkins (Recommandé)

### Étape 1 : Accéder à Jenkins

1. Ouvrez votre navigateur
2. Allez à l'URL de Jenkins :
   - **Depuis Windows** : `http://localhost:8080` ou `http://<WSL_IP>:8080`
   - **Depuis WSL** : `http://localhost:8080`

### Étape 2 : Trouver ou Créer le Pipeline

#### Si le pipeline existe déjà :

1. Dans le tableau de bord Jenkins, trouvez votre pipeline (ex: `Deveops-Pipeline` ou `student-management-pipeline`)
2. Cliquez sur le nom du pipeline

#### Si le pipeline n'existe pas encore :

1. Cliquez sur **"New Item"** (ou "Nouvel élément")
2. Entrez un nom : `Deveops-Pipeline` ou `student-management-pipeline`
3. Sélectionnez **"Pipeline"**
4. Cliquez sur **"OK"**

5. Dans la configuration :
   - **Definition** : Sélectionnez **"Pipeline script from SCM"**
   - **SCM** : Sélectionnez **"Git"**
   - **Repository URL** : `https://github.com/NegzaouiOussama/Deveops.git`
   - **Branch Specifier** : `*/main` ou `main`
   - **Script Path** : `Jenkinsfile`
   - Cliquez sur **"Save"**

### Étape 3 : Lancer le Pipeline

1. Sur la page du pipeline, cliquez sur **"Build Now"** (ou "Construire maintenant")
2. Le pipeline va commencer à s'exécuter
3. Cliquez sur le numéro de build dans **"Build History"** pour voir les détails
4. Cliquez sur **"Console Output"** pour voir les logs en temps réel

### Étape 4 : Surveiller le Déploiement

Le pipeline exécute automatiquement ces étapes :

1. ✅ **Checkout** - Récupère le code depuis GitHub
2. ✅ **Test** - Exécute les tests
3. ✅ **Package** - Crée le JAR
4. ✅ **Build Docker Image** - Construit l'image Docker
5. ✅ **Push Docker Image** - Pousse l'image vers Docker Hub
6. ✅ **Deploy to Kubernetes** - Déploie l'application
7. ✅ **Deploy Monitoring Stack** - **Déploie Prometheus et Grafana** 🎯
8. ✅ **Verify Monitoring Stack** - Vérifie que tout fonctionne

## 🎯 Méthode 2 : Via la Ligne de Commande (Jenkins CLI)

Si vous préférez utiliser la ligne de commande :

```bash
# Depuis WSL
cd ~/Documents/GitHub/Deveops

# Obtenir le token Jenkins (depuis l'interface Jenkins)
# Manage Jenkins → Manage Users → Configure → API Token

# Déclencher le build
curl -X POST http://localhost:8080/job/Deveops-Pipeline/build \
  --user <username>:<api-token> \
  --data-urlencode json='{"parameter": []}'
```

## 🎯 Méthode 3 : Démarrage Automatique (Déjà Configuré)

Si vous avez installé le service systemd avec `./install-auto-start.sh`, Prometheus et Grafana démarrent automatiquement au démarrage de WSL.

Pour démarrer manuellement le service :

```bash
sudo systemctl start prometheus-grafana
```

Pour vérifier le statut :

```bash
sudo systemctl status prometheus-grafana
```

## 📊 Vérification après le Pipeline

### 1. Vérifier les Pods Kubernetes

```bash
kubectl get pods -n devops | grep -E "prometheus|grafana|node-exporter"
```

Vous devriez voir :
- `prometheus-xxxxx` - Running
- `grafana-xxxxx` - Running
- `node-exporter-xxxxx` - Running

### 2. Obtenir les URLs d'Accès

```bash
# Obtenir l'IP Minikube
MINIKUBE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "📊 Prometheus: http://${MINIKUBE_IP}:30909"
echo "📈 Grafana: http://${MINIKUBE_IP}:30300 (admin/admin)"
```

Ou via tunnel Minikube :

```bash
minikube service prometheus -n devops
minikube service grafana -n devops
```

### 3. Vérifier les Targets Prometheus

1. Ouvrez Prometheus : `http://<MINIKUBE_IP>:30909`
2. Allez dans **Status → Targets**
3. Vérifiez que tous les targets sont **UP** :
   - ✅ `spring-boot-app` - Métriques Spring Boot Actuator
   - ✅ `jenkins` - Métriques Jenkins
   - ✅ `node-exporter-k8s` - Métriques système Kubernetes
   - ✅ `node-exporter-wsl` - Métriques Ubuntu/WSL
   - ✅ `prometheus` - Métriques Prometheus lui-même

### 4. Vérifier les Dashboards Grafana

1. Ouvrez Grafana : `http://<MINIKUBE_IP>:30300`
2. Connectez-vous : `admin` / `admin`
3. Allez dans **Dashboards** (icône menu → Dashboards)
4. Vous devriez voir :
   - 📊 **Dashboard Complet - DevOps Monitoring** (toutes les métriques)
   - 🌱 **Spring Boot Application Metrics**
   - 🏗️ **Jenkins Metrics**
   - 🖥️ **System Metrics (Node Exporter)**

## 🔍 Dépannage

### Le pipeline échoue à l'étape "Deploy Monitoring Stack"

1. **Vérifier que Minikube est démarré** :
   ```bash
   minikube status
   ```

2. **Vérifier que kubectl fonctionne** :
   ```bash
   kubectl get nodes
   ```

3. **Vérifier les logs du pipeline** :
   - Dans Jenkins, cliquez sur le build qui a échoué
   - Cliquez sur **"Console Output"**
   - Cherchez les erreurs dans la section "Deploy Monitoring Stack"

### Prometheus ne collecte pas les métriques

1. **Vérifier que les targets sont UP** :
   - Prometheus → Status → Targets

2. **Vérifier l'IP WSL dans la configuration** :
   ```bash
   kubectl get configmap prometheus-config -n devops -o yaml | grep -A 3 "node-exporter-wsl"
   ```

3. **Vérifier que Node Exporter WSL est actif** :
   ```bash
   sudo systemctl status node_exporter
   curl http://localhost:9100/metrics | head -20
   ```

### Grafana ne montre pas de données

1. **Vérifier que Prometheus est la source de données** :
   - Grafana → Configuration → Data Sources
   - Vérifier que "Prometheus" est configuré avec l'URL : `http://prometheus:9090`

2. **Vérifier que les dashboards sont importés** :
   - Grafana → Dashboards
   - Vous devriez voir les 4 dashboards listés ci-dessus

3. **Vérifier que Prometheus collecte des données** :
   - Prometheus → Graph
   - Tester une requête : `up` (devrait retourner plusieurs résultats)

## ✅ Checklist de Vérification Finale

Après le pipeline, vérifiez :

- [ ] Les pods Prometheus et Grafana sont **Running** dans Kubernetes
- [ ] Prometheus est accessible : `http://<MINIKUBE_IP>:30909`
- [ ] Grafana est accessible : `http://<MINIKUBE_IP>:30300`
- [ ] Tous les targets Prometheus sont **UP**
- [ ] Les dashboards Grafana sont visibles et affichent des données
- [ ] Les métriques Spring Boot sont collectées
- [ ] Les métriques Jenkins sont collectées
- [ ] Les métriques Ubuntu/WSL sont collectées

## 🎉 Résultat Attendu

Une fois le pipeline terminé avec succès, vous aurez :

✅ **Prometheus** qui collecte les métriques de :
   - Spring Boot Application (via Actuator)
   - Jenkins
   - Ubuntu/WSL (via Node Exporter)
   - Kubernetes (via Node Exporter K8s)

✅ **Grafana** avec 4 dashboards pour visualiser :
   - Vue d'ensemble complète (Dashboard Complet)
   - Métriques détaillées Spring Boot
   - Métriques Jenkins
   - Métriques système Ubuntu/WSL

✅ **Démarrage automatique** au boot de WSL (si service systemd installé)

## 📚 Ressources

- [Guide Prometheus et Grafana](./GUIDE_PROMETHEUS_GRAFANA.md)
- [Instructions Pipeline Jenkins](./INSTRUCTIONS_PIPELINE_JENKINS.md)
- [Créer Pipeline Jenkins](./CREER_PIPELINE_JENKINS.md)

