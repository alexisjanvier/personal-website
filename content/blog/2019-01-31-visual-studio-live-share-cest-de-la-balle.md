+++
title="Visual Studio Live Share, c’est de la balle !"
slug="visual-studio-live-share-cest-de-la-balle"
date = 2019-01-31
description="Cela fait maintenant plus de deux ans que je travaille en full remote. Une des questions récurrentes lorsque j’en discute concerne les outils que j’utilise pour travailler avec mes collègues. Et bien en voici un vraiment très bon : Visual Studio Live Share."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["devops"]
[extra]
+++

On a récemment fait une journée de hackday avec mon confrère [Kevin](https://twitter.com/Kmaschta?lang=fr) (sur Rust et Webassembly, post de blog à venir). Le truc, c’est que Kevin est à Nancy, et moi à Caen. Du coup, on pouvait soit partir chacun de son côté sur un bout du projet, soit faire le hackday en pair-programming. Mais le partage d’écran via [Framatalk](https://framatalk.org/accueil/fr/) toute une journée, c’est un peu frustrant. 

> « Est-ce qu’on n’essayerait pas Live Share ? » (Kevin)

Pourquoi pas, j’étais inscrit à la beta, mais je ne l’avais vraiment utiliser. Kevin initie une session, me transmet le lien et bingo !

Ce qui est chouette avec Live Share (LS pour la suite), c’est qu’effectivement on travaille à deux sur le même code, mais tout en gardant sa propre configuration ! Et puis on partage le code, mais aussi sa console !

Mais la grosse claque, c’est quand Kevin a lancé depuis se console Vs Code un serveur de dev, et qu’un nouvel onglet c’est ouvert dans mon Chrome ! Pas de doutes, LS permet de très simplement partager un serveur.
Du coup, j’étais capable d’éditer un fichier sur la machine de Kevin pendant que lui travaillait sur un autre, et à la sauvegarde, le hot reload mettait à jour le site sur le navigateur de mon laptop. Magique !

Pour voir plus en détail ce que l’on peut faire, le plus mieux est de faire un petit tour sur la [page officiel](https://visualstudio.microsoft.com/fr/services/live-share).

On est resté cette journée sur Framatalk pour se parler, mais c’est parce qu’on avait raté cette autre extension : [VS Live Share Audio](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare-audio)

**Donc si comme moi (je suis en *full remote*) vous devez travailler régulièrement avec vos collègues développeurs à distance, je vous conseille très vivement d’essayer Live Share ! C’est sans doute l’outil de pair-programming en remote le plus convaincant que j’ai utilisé. Et une bonne raison de préférer Vs Code à Vim.**
