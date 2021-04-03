+++
title="Un serveur en deux deux"
slug="un-serveur-en-deux-deux"
date = 2018-10-18
description="Comment lancer un projet docker-compose sur un serveur publique en moins de 10 minutes"
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["devops"]
[extra]
+++

Pour un projet, il a fallu lancer rapidement un serveur de staging (agilité oblige) en attendant la mise à disposition du serveur de staging final. Sans être aussi rapide qu'avec un service comme [Zeit Now](https://zeit.co/now) ou l'utilisation d'un [ngrock](https://ngrok.com/), il est possible sur AWS lancer un serveur fonctionnel en moins de 10 minutes.

## Création d'une instance Amazon Lightsail

Généralement, j'opte pour une instance EC2. Mais nous avons voulu tester [Lightsail](https://lightsail.aws.amazon.com), entre autres parce que l'instance minimale est plus puissante qu'une EC2 minimale, que c'est gratuit le premier mois et que le tarif reste raisonnable pour la suite (3.5$/m).    
C'est donc une instance minimale qui est choisie: 512 Mo, 1vCPU et un SSD de 20GO, avec l'OS [Amazon Linux](https://aws.amazon.com/fr/amazon-linux-ami/).

La provision du serveur a pris moins de 3 min et je me connecte en ssh grâce à la clé .pem générée.

## Ajout d'une IP fixe

Lorsque on lance une instance EC2, on obtient une URL, certes obscure, mais une URL. Ce n'est pas le cas sur lightsail: l'instance possède par défaut une IP, qui n'est pas fixe. Mais il est possible gratuitement d'y associer un IP fixe, ne restera plus qu'à rediriger un sous-domaine sur cette IP.    
Et non, cela ne sera pas faisable en moins de 10 minutes, qu'à cela ne tienne, je me contenterais de l'IP.

## Création d'un swap

Ensuite, le gros point noir de l'instance, c'est ses 512 Mo de mémoire, vraiment trop court pour espérer pouvoir lancer un build d'image Docker par exemple. Du coup, il faut aider un peu la mini-instance en ajoutant du swap.

Pour cela, il faut créer un fichier de swap de 1Go (1024 * 1024MB => 1048576)

```bash
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile
```

Si `faillocate` est installé sur le serveur, on peut encore plus simplement faire:

```bash
sudo allocate -l 1G /swapfile
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile
```

Puis l'activer

```bash
sudo mkswap /swapfile
sudo swapon /swapfile
```

Pour que le swap soit toujours présent en cas de reboot de l'instance, il faut ajouter le swap au fichier `fstab` :

```bash
# in /etc/fstab
/swapfile none swap sw 0 0
```

Vérifions la mise en place du swap avec la commande `free -m` :

```
             total       used       free     shared    buffers     cached
Mem:           483        474          8          0         12        394
-/+ buffers/cache:         68        415
Swap:         1023          0       1023
```

 > En fait, toutes ces commandes proviennent du post [Linux Add a Swap File - HowTo - nixCraft](https://www.cyberciti.biz/faq/linux-add-a-swap-file-howto/)

## Installation de Docker

L'intégralité du projet à déployer sur ce staging est géré sous docker-compose. Il faut donc installer Docker et docker-compose.

```bash
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Il faut se déconnecter puis se reconnecter du ssh pour que les nouveaux droits soient pris, et permettre de lancer un `docker version` puis un `docker-compose version`permettant de valider l'installation.

## Autres utilitaires

Pour simplifier le gestion de du serveur, j'installe un minimum d'outils de monitoring: [htop](https://hisham.hm/htop/) et [ctop](https://github.com/bcicen/ctop).

```bash
sudo yum install -y htop
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```

Ne manque plus que git pour récupperer le code du projet.

```bash
sudo yum install -y git 
```

## Tadam

```bash
git clone https://monprojet.git
cd monprojet
make install
make run
```

Et voilà ! En 10 minutes (environ, en vrai je n'avais de chronomètre), le projet est accessible publiquement.

J'ai mis plus de temps à écrire ce post de blog.
