+++
title="Road to Caen"
slug="road_to_caen_le_projet"
date = 2016-01-25
tags = ["Lean"]
description="Un nouveau blog, un premier post et un titre pas très technique : je déménage cet été à Caen. "
+++

C’est un peu une mise en pratique de la politique de [rural offshore](#rural_offshore) chère à Marmelab. Non, ce nouveau blog ne sera pas le journal de mon déménagement, mais ce projet de retour en province me semble un moment propice pour améliorer ma compétence en communication.
À paris, c’est trop facile : tous ces meetups, ces conférences, ces collègues de travail... Non pas que je risque de me retrouver seul dans le désert à Caen, mais pour garder cet esprit de partage parisien, je me prépare sans regret à devoir autant donner que recevoir.
Communiquer activement donc, en commençant par ce blog. Et puis écrire c'est sans doute [une vraie bonne habitude](#ecrire), même si ce que l’on écrit n’a rien de révolutionnaire.
Et au-delà du blog, j’espère rencontrer rapidement les membres de la [Coding School](http://www.meetup.com/fr-FR/Coding-School-Meetup-Group), de la [fabrique de services](http://www.meetup.com/fr-FR/Fabrique-de-services-Normandy-Frenchtech/), du [forum digital](http://www.forum-digital.fr/), du [club agile de Caen](http://www.club-agile-caen.fr/)...

# Une application pour déménager
***Road to Caen***, c’est le nom de mon nouveau side project. Une des premières choses à faire quand on déménage, c’est de penser à un nouvel appartement. Et c’est plutôt sympa de chercher un appartement en province quand on vient de Paris, on se rend compte qu’on n’est pas obligé de donner un bras pour avoir un logement. Le projet ne va pas consister en une sorte de mashup d’annonces immobilières, mais devra aider à trouver la bonne localisation de cet appartement. La qualité de la localisation va dépendre de critères plus ou moins subjectifs, mais c’est une des qualités des sides projects : on est toujours d’équerre avec le product owner.

Ces critères seront donc :

* **Le collège et l’école de rattachement de l’adresse**: j’ai deux filles. Il n’est ici aucunement question de remettre en cause le principe de la carte scolaire et l’importance de l’école publique. Il se trouve que ce principe nous a plongés dans des affres de déception, voire de colère sur Paris. C’est donc un point important.
* Ensuite, **la distance à des points notables**, comme la gare (le principe du rural shore, c’est aussi d’être rapidement sur Paris), les espaces de coworking, les salles de concert, les marchés, les écoles de musique, les bars à baby…

Cette application devra aussi permettre de :

* sauvegarder des adresses
* évaluer/noter les adresses (selon leur correspondance aux critères précédents)
* l'ouvrir à une agence afin vérifier la note de localisation d’une éventuelle proposition de location.

# Planning technique
Un side project, c’est aussi l’occasion de tester des nouvelles techno, ou comme ce sera en partie le cas ici, de faire le point sur celles que l’on est sensé maitriser. Voici donc les objectifs techniques, plus ou moins pragmatiques :

* Se baser sur de l’**open-data** : l’idée est de mettre en œuvre un maximum de données normandes, plus ou moins librement et facilement disponibles.
* **Serveless** : Je ne suis pas fan du terme, parce qu’au bout du compte, il y a forcement des serveurs quelque part. Mais ce ne sera pas les miens.
* **Mobile first** et **offline** : A priori, l’utilisation classique de l’application sera sur mobile dans le rue en visite d’appartement, sans forcément avoir une bonne connexion (c’est comment la 4 g à Caen ?)
* **SPA** : j’ai trouvé très pertinent l’article de [Stefan Tilkov](#hate_spa). Mais connaissant bien l’utilisateur final de l’application, une single page fera très bien l’affaire.
* **ES6** : tout le code sera en JavaScript, en profitant au maximum de l’ES6
* **React** et **Redux** (ou pas) : je trouve intéressantes toutes les discussions actuelles sur la [fatigue javascript](https://medium.com/search?q=javascript%20fatigue)… Alors, faire du React/Redux pour faire du React/Redux ? Oui, un peu, ne serait-ce que parce que cela correspond au bootstrap actuel des projets [Marmelab](http://marmelab.com/). Mais ce sera peut-être l’occasion d’y trouver une non-pertinence.
* Il faudra persister des données (sauvegarde d’adresses, points favoris), synchroniser ces données entre plusieurs devices, et que cela puisse se faire offline. Je pense donc tester quelques services du genre de [Firebase](https://www.firebase.com), [pouchdb](http://pouchdb.com/) ou [Amazon Cognito](http://aws.amazon.com/fr/cognito/).

# Road to Caen
Pour finir ce post, pourquoi Road de Caen ? Et bien en référence au **Road to Rouen** de *Supergrass*.

<center><iframe src="https://embed.spotify.com/?uri=spotify:album:7HBzTTfJhW9sis8yvgxmL6&view=coverart" width="300" height="380" frameborder="0" allowtransparency="true"></iframe></center>

Il se trouve que je pense que tous les Normands dansent sur de la pop anglaise (ma femme est de Saint-Lô). Je suis pour ma part manceau, et si par malheurs nous avions déménagé au Mans, je l’aurais appelé [***The arguments for Le Mans***](https://open.spotify.com/album/2bU6BaHfovn3rvxxxHSkWd) ou [***New Day Rising In Le Mans***](https://open.spotify.com/album/2eOu9QDLP2MoO04ZtII2Vm).

Dans mon prochain post, j’aborderais le bootstrap du projet, et la mise en place du MVP : les collèges liés à une adresse à Caen.


# Références

* <a name="rural_offshore"></a>[L'itération agile : entre SSII et agence, un nouveau mode de prestation informatique](http://marmelab.com/blog/2015/06/11/iteration-agile.html)
* <a name="ecrire"></a>[Write What You Know (Now)](http://alistapart.com/column/write-what-you-know-now)
* <a name="hate_spa"></a>[Why I hate your Single Page App](https://medium.com/@stilkov/why-i-hate-your-single-page-app-f08bb4ff9134#.bzfye46vx)
