# Kubernetes avec K3s et K3d

## Prérequis

Avant de commencer, assurez-vous d'avoir les outils suivants installés sur votre machine :

- [Docker](https://docs.docker.com/get-docker/) : pour exécuter des conteneurs.
- [K3d](https://k3d.io/) (version v5.7.5) : outil pour exécuter des clusters kubernetes K3s dans Docker.
- [Task](https://taskfile.dev/) : outil pour gérer les tâches via un `Taskfile`.

Pour deployer le cluster, suivez les instructions de la section [Exemple de workflow pour deployer](#Exemple-de-workflow-pour-deployer) apres avoir installe les pre-requis

---

## Qu'est-ce que K3s et K3d ?

### K3s
K3s est une distribution légère de Kubernetes conçue pour des environnements de faible consommation, des clusters embarqués ou des cas d'utilisation de développement. Il simplifie l'installation et réduit les exigences en termes de mémoire et de processeur, tout en restant compatible avec l'écosystème Kubernetes standard.

### K3d
K3d est un outil qui permet de déployer des clusters K3s dans des conteneurs Docker. Il simplifie grandement la gestion des clusters Kubernetes locaux pour le développement et les tests.


Nous utiliserons donc `k3d` pour creer notre cluster Kubernetes en local et deployer notre application.

L'application sera entierement deployee dans le namespace `default` du cluster et utilisera un secret d'authentification Kubernetes a Docker Hub pour permettre le pull des images sans atteindre la limite de pull imposee par Docker Hub.

L'architecture de notre cluster comporte `1 master` node et `2 worker` nodes.
 
## Le fichier déclaratif `Kind: Simple`

Le fichier déclaratif de type `Kind: Simple` (`cluster.yaml` ici) permet de configurer votre cluster K3d declarativement. C'est une facon de configurer et decrire le cluster sous forme de fichier. Voici ce qu'il peut contenir :

- Configuration des nœuds : spécifiez le nombre de nœuds master et worker ainsi que leur configuration respective.
- Mapping de dossiers : partagez des fichiers ou dossiers entre l’hôte et les conteneurs du cluster.
- Ports exposés : configurez l’accès aux services déployés dans le cluster.
- Répertoire `/var/lib/rancher/k3s/server/manifests/` : tout fichier YAML ajouté dans ce dossier sera automatiquement appliqué au cluster par K3s.

Exemple d'utilisation de `/var/lib/rancher/k3s/server/manifests/` :
Si vous ajoutez un fichier YAML de déploiement dans ce dossier, K3s le détectera automatiquement et l’appliquera, sans nécessiter de commande manuelle comme `kubectl apply`.

## Automatisation avec Taskfile

Le fichier `Taskfile.yml` est un outil puissant pour automatiser les tâches. Voici une description des tâches disponibles :

### Tâche : install-k3d
Installe le binaire K3d sur votre machine.
### Tâche : create-cluster
Crée un cluster Kubernetes avec K3d. Cette tâche :
- Utilise un fichier modèle (cluster.yaml) pour générer la configuration de cluster (k3d.yaml).
- Crée le cluster via k3d cluster create.
### Tâche : delete-cluster
Supprime le cluster Kubernetes.
### Tâche : gen-secret
Génère un secret Kubernetes pour l'authentification Docker Hub (Pull des images dans le cluster) et le sauvegarde dans `manifests/secret.yaml`.

## Exemple de workflow pour deployer

1. Commencer par generer votre secret Kubernetes pour l'authentification a Docker Hub de votre cluster:

```bash
task gen-secret DOCKERUSER=myuser DOCKERPWD=mypassword
```

2. Créez votre cluster Kubernetes 
```bash
task create-cluster
```
3. Attendez que le cluster soit disponible
4. Verifier les deploiements et les services dans le namespace `default` de votre cluster:
```bash
kubectl get pods,svc -n default
```
5. Acceder a la webapp

La webapp est configuree via un `Service` Kubernetes de type `NodePort` qui est mappe sur le port `8888` de votre machine hote.
Pour pouvez y acceder a l'adresse : `http://localhost:8888`

