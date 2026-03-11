# Atomia Cloud Suite - Déploiement Rapide

## Prérequis

- Serveur/VPS avec Ubuntu 20.04+ (ou Debian 11+)
- Docker et Docker Compose installés
- (Optionnel) GPU NVIDIA avec drivers >= 525.xx

## Installation Rapide

```bash
# 1. Cloner ou télécharger les fichiers
git clone https://github.com/your-repo/atomia-cloud-suite.git
cd atomia-cloud-suite

# 2. Rendre le script exécutable
chmod +x setup.sh

# 3. Lancer l'installation (en tant que root ou avec sudo)
sudo ./setup.sh
```

Le script va :
- Vérifier/installer Docker
- Détecter automatiquement un GPU NVIDIA
- Créer le réseau et les volumes Docker
- Télécharger les images
- (Optionnel) Télécharger les modèles IA initiaux

## Configuration Initiale

### 1. Modifier les mots de passe

Éditez `docker-compose.yml` et changez :

```yaml
# Code Server
environment:
  - PASSWORD=change_this_password    # ← Changer ici

# Open WebUI  
environment:
  - WEBUI_SECRET_KEY=change_this_secure_key_in_production  # ← Changer ici
```

### 2. Configurer Continue pour VS Code Server

Le fichier `continue/config.json` est déjà configuré pour pointer vers Ollama.
Il sera automatiquement copié dans le conteneur code-server.

### 3. Pour GPU NVIDIA (Optionnel)

Si vous avez un GPU NVIDIA, installez le NVIDIA Container Toolkit :

```bash
# Ajouter le repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Installer
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Accès aux Services

| Service | URL | Description |
|---------|-----|-------------|
| **Open WebUI** | http://localhost:8080 | Interface chat IA |
| **Code Server** | http://localhost:8443 | IDE VS Code |
| **Gitea** | http://localhost:3000 | Serveur Git auto-hébergé |
| **Ollama API** | http://localhost:11434 | API REST |
| **Nginx Proxy** | http://localhost:81 | Proxy inverse (optionnel) |

## Commandes Utiles

```bash
# Voir les logs en temps réel
docker compose logs -f

# Redémarrer un service spécifique
docker compose restart ollama

# Arrêter tous les services
docker compose down

# Supprimer aussi les volumes (attention : perte de données)
docker compose down -v

# Mettre à jour les images
docker compose pull
docker compose up -d

# Lister les modèles Ollama
docker exec atomia-ollama ollama list

# Télécharger un nouveau modèle
docker exec atomia-ollama ollama pull codellama:7b
```

## Configuration Continue

### Modèles Disponibles

Le fichier `continue/config.json` est pré-configuré avec :

- **codellama** - Parfait pour la génération de code
- **deepseek-coder** - Expert en développement
- **llama3** - Usage général
- **mistral** - Rapide et efficace
- **phi3** - Léger, rapide

### Utiliser Continue dans Code Server

1. Ouvrez Code Server : http://localhost:8443
2. Connectez-vous avec le mot de passe défini
3. Installez l'extension Continue depuis le marketplace
4. L'extension utilisera automatiquement `continue/config.json`

### Changer le Modèle par Défaut

Éditez `continue/config.json` et modifiez :

```json
{
  "models": [
    {
      "model": "votre-modele-préféré",
      ...
    }
  ]
}
```

## Accès Externe (Optionnel)

Pour accéder depuis l'extérieur via Nginx Proxy Manager :

1. Démarrez le service Nginx :
   ```bash
   docker compose up -d nginx-proxy-manager
   ```

2. Ouvrez http://votre-ip:81
3. Connectez-vous avec : `admin@example.com` / `changeme`

4. Ajoutez des proxies :
   - Host : `ollama.votre-domaine.com` → `172.28.0.x:11434`
   - Host : `chat.votre-domaine.com` → `172.28.0.x:8080`
   - Host : `code.votre-domaine.com` → `172.28.0.x:8443`
   - Host : `git.votre-domaine.com` → `172.28.0.x:3000`

## Personnalisation des Ressources

Dans `docker-compose.yml`, ajustez les limites :

```yaml
deploy:
  resources:
    limits:
      memory: 8G    # RAM maximale
      cpus: '4.0'  # Nombre de CPU
```

Recommandations :
- **Ollama** : 8-16GB RAM, 2-4 CPU (plus si GPU)
- **Open WebUI** : 2-4GB RAM, 1-2 CPU
- **Code Server** : 4-8GB RAM, 2-4 CPU
- **Gitea** : 2-4GB RAM, 1-2 CPU

## Stockage Persistant

Les données sont stockées dans des volumes Docker persistants :

```
data/
├── ollama/          # Modèles IA (10-50GB+)
├── openwebui/       # Chats, paramètres, uploads
├── code-server/     # Config, extensions VS Code
├── gitea/           # Dépôts Git, base de données
├── gitea-ssh/       # Clés SSH
projects/            # Vos projets de code
```

Pour sauvegarder : `tar -czvf atomia-backup.tar.gz data/ projects/`

## Gitea - Serveur Git

### Configuration Initiale

1. Ouvrez http://localhost:3000
2. Suivez l'assistant d'installation :
   - Type de base de données : SQLite3
   - Chemin des données : /data
   - Nom de domaine : localhost
   - URL du serveur : http://localhost:3000

### Utiliser avec Code Server

Dans Code Server, configurez Git :

```bash
# Configurer Git
git config --global user.name "Votre Nom"
git config --global user.email "vous@atomia.local"

# Cloner un dépôt Gitea
git clone http://localhost:3000/votre-user/votre-repo.git

# Ou via SSH
git clone ssh://git@localhost:2222/votre-user/votre-repo.git
```

### Fonctionnalités Gitea

- Gestion de dépôts Git
- Pull requests avec revue de code
- Issues et项目管理
- Wiki intégré
- CI/CD basique
- Authentification OAuth2

## Dépannage

### Ollama ne détecte pas le GPU

```bash
# Vérifier NVIDIA Docker
docker run --rm --gpus all nvidia/cuda:11-base nvidia-smi

# Si erreur, reconfigurer
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Problèmes de réseau entre conteneurs

```bash
# Vérifier le réseau
docker network inspect atomia-network
```

### Espace disque insuffisant

```bash
# Nettoyer les images inutilisées
docker system prune -a

# Voir l'utilisation
docker system df
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      ATOMIA CLOUD SUITE v2.0                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   OLLAMA     │◄──►│ OPEN WEBUI   │    │ CODE SERVER  │   │
│  │  (AI GPU)    │    │   (Chat)     │    │   (VS Code)  │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│         │                   │                   │              │
│         │                   │                   │              │
│         └───────────────────┼───────────────────┘              │
│                             │                                  │
│                    ┌────────▼────────┐                        │
│                    │ Docker Network  │                        │
│                    │ atomia-network  │                        │
│                    └─────────────────┘                        │
│                             │                                  │
│  ┌──────────────────────────┼──────────────────────────┐      │
│  │                          │                          │      │
│  ▼                          ▼                          ▼      │
│ ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│ │    GITEA     │    │     DATA     │    │    NGINX     │   │
│ │ (Git/PR)     │    │   VOLUMES    │    │ PROXY MGR    │   │
│ └──────────────┘    └──────────────┘    └──────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Licence

MIT License - Libre d'utilisation et de modification.