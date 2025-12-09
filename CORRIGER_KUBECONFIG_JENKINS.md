# Corriger le kubeconfig pour Jenkins

## 🔧 Problème

Le fichier `/var/lib/jenkins/.kube/config` contient des chemins qui pointent vers `/home/negzaoui/.minikube/...` mais ils doivent pointer vers `/var/lib/jenkins/.minikube/...`

## ✅ Solution

### Étape 1 : Modifier le kubeconfig

Vous êtes déjà dans nano avec le fichier ouvert. Modifiez les chemins suivants :

**Dans la section `clusters:`**
Changez :
```yaml
certificate-authority: /home/negzaoui/.minikube/ca.crt
```

En :
```yaml
certificate-authority: /var/lib/jenkins/.minikube/ca.crt
```

**Dans la section `users:`**
Changez :
```yaml
client-certificate: /home/negzaoui/.minikube/profiles/minikube/client.crt
client-key: /home/negzaoui/.minikube/profiles/minikube/client.key
```

En :
```yaml
client-certificate: /var/lib/jenkins/.minikube/profiles/minikube/client.crt
client-key: /var/lib/jenkins/.minikube/profiles/minikube/client.key
```

### Étape 2 : Sauvegarder et quitter nano

1. Appuyez sur `Ctrl + O` pour sauvegarder (Write Out)
2. Appuyez sur `Enter` pour confirmer
3. Appuyez sur `Ctrl + X` pour quitter

### Étape 3 : Vérifier les permissions

```bash
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config
```

### Étape 4 : Tester

```bash
sudo -u jenkins kubectl get nodes
```

Vous devriez voir :
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   XXm   v1.34.0
```

## 📝 Commandes Rapides

Si vous voulez faire les modifications rapidement avec sed :

```bash
sudo sed -i 's|/home/negzaoui/.minikube|/var/lib/jenkins/.minikube|g' /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config
```

Puis testez :
```bash
sudo -u jenkins kubectl get nodes
```

