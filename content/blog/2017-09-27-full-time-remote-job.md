+++
title="Retour sur une année en télétravail à plein temps"
slug="retour-sur-une-annee-en-teletravail-a-plein-temps"
date = 2017-09-27
description="On trouve beaucoup d’articles de blog sur le « full time remote jobs », moins sur le télétravail à plein temps. Si les entreprises en France s’ouvrent petit à petit, journée par journée au télétravail, le travail à plein temps à distance est moins courant. Pourtant c’est possible et c’est efficace."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["soft-skill"]
[extra]
marmelab="https://marmelab.com/blog/2017/09/27/full-time-remote-job.html"
+++


Le 4 juillet 2017, j'ai fêté ma première année de télétravail à plein temps !

<img src="/images/blog/remote/birthday.png" class="responsive" />

Pourquoi avoir choisi ce mode de travail ? Un gros ras-le-bol de mes collègues ou de mon patron ? Non, pas du tout. Une offre impressionnante d’une boîte de la Silicon Valley me proposant de rejoindre une équipe internationale ? Non plus. La vraie raison, c’est que cela faisait 18 ans que nous étions (ma femme, puis mes filles et moi) à Paris. C’est une ville que j’adore et dont je n’ai pas fait le tour. Mais comme dans la chanson de [LCD Sound System](https://www.youtube.com/watch?v=5JkBiP7rPt0), « Paris I love you but you’re bringing me down »…

Nous aurions pu déménager à Nancy au siège de Marmelab. Mais même si c'est une ville agréable, elle est située trop loin de la mer. Nous voulions donc partir de Paris, sans aller à Nancy. Et heureusement pour nous, Marmelab est une boite militante du travail en province (lire [le rural shore](https://marmelab.com/blog/2015/06/11/iteration-agile.html)) et donc favorable au télétravail. Pour cela, une condition: être à moins de deux heures de Paris en train.

Nous avons donc déménagé à Caen.

<img src="/images/blog/remote/train2.jpg" class="responsive" />

Et voici ce que j'ai appris depuis un an sur le remote working.

##  L'importance des revues de code

Quand on est en télétravail, pas mal de choses disparaissent du quotidien: les transports, la machine à café, le babyfoot, les repas du midi entre collègues, les autres développeurs autour de soi ... Au final, il reste l'écran et le code. C'est un peu caricatural, parce qu'on le verra plus loin, il y a aussi Slack, la webcam, les rencontres ... Il n'empêche que lorsque l'on travaille de chez soi, le point de contact prédominant, c'est le code. Et que l'échange autour du code se fait par les revues de code.

Sans faire de ce post de blog un plaidoyer pour les code reviews ([on en trouve déja de très bons](https://dev.to/vaidehijoshi/crafting-better-code-reviews)), je vais tenter d'expliquer en quoi cela m'a aidé dans mon quotidien  de télétravailleur.

J'essaye tous les jours d'appliquer les trois règles suivantes.

### 1) Commiter vite, explicitement et souvent

Il y a plusieurs moyens de dire ce que l'on est en train de faire : Slack, en visio pour un standup, par fax... Mais le commit ne trompe pas. Donc, dès que je commence une tâche, je fais une branche, un premier commit très court, je push et j'ouvre une Pull Request (PR). Comme ça, tous les membres du projet peuvent savoir sur quoi je travaille.

J'essaye également d'expliciter au mieux ma PR, idéalement avec une petite Todo List. Au final, cela facilite le travail de ceux qui feront la revue.

Toujours dans le même souci de penser à la relecture de son code, une PR constituée de petits commits bien commentés est plus facile à comprendre. J'aime particulièrement bien les PR dont chaque commit reprend la todo list de présentation de la PR. C'est signe que la tache avait la bonne taille, qu'elle a été initialement bien réfléchie, et que l'on ne s'est pas perdu en cours de route en la codant.

<img src="/images/blog/remote/cleanPR.png" class="responsive" />

Et je push souvent. Idéalement à chaque commit. Cela permet à tout le monde de voir l'avancement d'une tâche, de s'apercevoir que le code prend une bonne direction ou de s'inquiéter d'un blocage éventuel.

### 2) Faire des revues bienveillantes

Une revue de code, c'est tout d'abord l'occasion de comprendre le code d'une application sur laquelle on travaille mais que l'on n’a pas écrit. C'est le moment de poser des questions, de remettre en cause le nommage des variables, des fonctions, bref de tout ce qui rend du code lisible et expressif. Donc hormis le côté formel d'une revue (le code styling, les coquilles), c'est le moment où notre cerveau se synchronise avec le reste de l'équipe. Il ne s'agit  pas de donner des leçons, de chercher l'erreur, mais de faire en sorte que tout soit compréhensible par tout le monde et que le code soit le plus robuste possible. C'est un moment de bienveillance.

Chez Marmelab, on a également une règle : on ne merge jamais sa propre Pull Request. Cela renforce d'autant la responsabilité de l'ensemble de l'équipe sur tout le code produit.

### 3) Prendre en compte toutes les revues

Dès que l'on sait que la revue faite sur son code est bienveillante, on ne peut pas refuser de la prendre en compte. On peut discuter, argumenter, défendre sa position, mais aussi accepter de ne pas avoir été assez clair, de s'être trompé, de ne pas avoir eu la meilleure idée. Une bonne revue nous fait toujours progresser. Et même quand on est très fier de sa PR, mais que l'on a des retours parce qu'il manque un ou deux tests, et que l'on a fait une coquille sur un terme anglais, eh bien c'est génial. Le code final sera encore meilleur !

<img src="/images/blog/remote/scout.jpg" class="responsive" />

Je n'énonce ici rien de fou. C'est une pratique profitant à n'importe quelle équipe de développeurs, qu'ils soient dans le même bureau ou non. Mais l'air de rien, outre l'impact que cela a sur la qualité du code, cela permet de bien rythmer la journée lorsque l'on est en remote. Mon quotidien commence le plus souvent par les revues de pull requests prêtes sur Github. Cela peut me prendre une bonne heure. C'est l'occasion de rentrer dans le projet et d'apprendre des autres. Ensuite, j'applique les revues de codes qui m'ont été adressées. L'objectif est de pouvoir merger avant de commencer une nouvelle tâche. Ensuite, j'applique le *commiter vite, explicitement et souvent*. Cela interdit de tomber dans le piège de la grande pause Netflix ou du syndrome du héros codant toutes ses tâches en un weekend sur un seul commit de 4242 lignes de code que personne ne relira...

<img src="/images/blog/remote/workingAtNight.jpg" class="responsive" />

## Se trouver des horaires

Car cette question du cadre est souvent la première que l’on me pose quand je dis que je travaille de chez moi :

> "Mais comment tu fais pour réussir à travailler de chez toi ? Moi je passerais mon temps en pyjama devant la télé."

En fait c’est assez simple dès que l’on travaille en équipe : on conserve les horaires de travail des autres personnes de l’équipe. En tout cas, c’est mon cas, car la majorité des développeurs de chez Marmelab travaillent encore dans le même bureau à Nancy, sur des horaires « classiques ». Ensuite, lorsque la journée débute, elle est rythmée par les commits et la lecture du code des autres.

Mais pour autant, ce cadre des horaires de bureau devient beaucoup moins rigide. Il n’y a plus de période de transport, ce qui fait gagner beaucoup de temps. Ensuite, même si le « flux de commits » doit être régulier, cela ne veut pas dire qu’il doit être constant. C’est sans doute un piège lorsque l’on débute le télétravail : on a l’impression de devoir constamment prouver que l’on travaille au risque d’être suspecté de faire autre chose. On devient son propre manageur tyrannique.

Mais cela passe. Et on commence à profiter du fait de pouvoir prendre un rendez-vous chez le dentiste dans l’après-midi sans avoir 6 mois d’attente, d’aller chercher ses enfants à l’école, de les amener au cours de théâtre le mercredi après midi. L’important, c’est d’arriver à être régulier dans son travail le reste du temps. Ce n’est pas si facile et il faut expérimenter pour arriver à cet équilibre. Je ne suis pas certain de l’avoir encore tout à fait trouvé.

## Conserver un bureau

<img src="/images/blog/remote/nodesk.jpg" class="responsive" />

On s’habitue aussi à travailler d’un peu n’importe où. Mais en ce qui me concerne, je suis loin du mythe du développeur nomade qui code en faisant le tour du monde. Bien au contraire. En arrivant à Caen, j’ai essayé pas mal de cafés ou l’espace de co-working de Caen. J’ai même pour le principe fait une séance de code au bord de la mer. C’était plutôt drôle, mais pas forcement agréable. Pour des raisons très pratiques qui font que rien ne vaut un bon bureau, une bonne chaise, et du calme. Et puis la mer, c’est vraiment mieux d’en profiter sans ordinateur.

Pour continuer sur ce thème, nous avions pris en arrivant à Caen un appartement sans bureau. Je codais dans le salon ou dans la grande cuisine. Mais comme cadeau pour mon premier anniversaire de télétravail, nous avons déménagé dans un appartement où j’ai maintenant un bureau dédié. Si le télétravail vous tente, je ne peux que vous conseiller d’envisager très sérieusement de prendre un logement avec bureau.

## Les bons outils

La question de la logistique liée au travail à distance est aussi une question assez courante. Mais dans notre travail de développeur, ce n'est pas un problème, les outils existent. Voici les éléments qui me semblent importants (en dehors d’un bon bureau et d’une bonne chaise).

### Un bon laptop

Je ne vais pas m’étendre sur la question de l’ordinateur tant il est indissociable d’un développeur. Il doit être puissant. Toujours, évidemment. Mais pour un travailleur en remote, il doit être portable, posséder une bonne autonomie et un écran pas trop petit. Car même si j’ai maintenant un bureau, je bouge quand même régulièrement, principalement pour aller chez le client. Ce qui fait plusieurs heures de travail dans le train. Après, libre à vous d’y ajouter un super clavier mécanique, un ou plusieurs écrans 4K ou ce que vous voulez. Je note juste que selon moi le multiécran, aussi agréable soit il, n’est pas forcément une bonne option. Étant souvent nomade, je préfère avoir mes automatismes sur un seul écran (alt-tab & co).

### De quoi faire des visioconférences de qualité

J’ai beaucoup insisté sur les revues de code. Mais évidemment tout ne se passe pas que sur Github. Parfois, il vaut mieux une bonne discussion en visio que de trop longues phrases. Quand on bloque sur quelque chose, un partage d’écran ou une séance de *pair programming* sont la meilleure solution. En télétravail, la webcam c’est la petite fenêtre ouverte dans le bureau de vos collègues. Cela vaut largement le coup d’y investir quelques euros.

Le premier élément pour une bonne visio, c’est une bonne connexion internet. À Caen, on a une fibre du tonnerre et un bon réseau 4G. C’est important quand on commence à chercher son lieu de travail. Nous avons eu une opportunité de logement assez incroyable, proche de la mer, avec un immense jardin et un calme olympien. Mais la qualité du réseau 4G et le débit de l’ADSL ont été rédhibitoires.

<img src="/images/blog/remote/visio.jpg" class="responsive" />

Ensuite la webcam, le micro et le casque sont des points à ne pas négliger. Rien n’est plus agaçant qu’une conversation ou l’on ne voit pas bien l’interlocuteur. Et c'est encore pire lorsque l'on ne l’entend pas bien.

Les logiciels de visio ne manquent pas. En ce qui me concerne, j’aime bien [talky](https://core.talky.io/).

### Une stack de développement en "SaaS"

Je ne sais pas si le terme *SaaS* est parfaitement approprié, mais l’idée est d’avoir le moins possible besoin de soft à installer ou de machines physiques à maintenir. Tout est disponible en ligne ! [Github](https://github.com/), évidement pour la gestion du code, [Travis](https://travis-ci.org/) pour l’intégration continue, [Trello](https://trello.com/) et [BaseCamp](https://basecamp.com/) pour la gestion des projets, [Slack](https://slack.com/) pour les discussions, AWS, DigitalOcean ou [Zeit Now](https://zeit.co/now) pour les serveurs...

## In Real Life

Donc pour réussir à travailler en remote, il faut une bonne méthode de travail au quotidien, un bureau et le bon matériel. Ce sont des conditions nécessaires, mais en ce qui me concerne non suffisantes.

### Bien connaitre ses collègues

Pour être à l’aise lors d’une revue de code, il faut savoir adopter le bon ton. Et ce ton va dépendre de la personne à qui l’on s’adresse. C’est un peu pareil pour la visio : mieux on se connait, plus la communication devient naturelle et spontannée. C’est donc un facteur de réussite important que de connaitre en "vrai" les membres de l'équipe. Si je suis à l’aise dans mon travail au sein de Marmelab même sans être dans le même bureau, c’est que j'ai déja rencontré tout le monde.

Et c’est tout d’abord parce que l’on travaille par équipe de trois (un facilitateur agile et deux développeurs) en sprint de deux semaines. On se retrouve donc tous une fois toutes les deux semaines chez le client pour la démo, la rétrospective de sprint et le planning poker. Les équipes tournant régulièrement et le nombre de développeurs chez Marmelab étant raisonnable (nous sommes 10), on arrive rapidement à avoir tous travaillé au moins une fois ensemble.

Ensuite, l’équipe se retrouve une fois par mois pour une journée de hackday. Nous allons aussi régulièrement à des conférences. Par exemple, cet été nous nous sommes tous retrouvés à la conférence [React Europe](https://marmelab.com/blog/2017/05/24/minutes-of-react-europe-2017.html).

Et il y a enfin les classiques « fêtes » du personnel et autres journées de *Team Building*, deux ou trois fois par an. C'est l'occasion de passer du temps ensemble sans ordinateur, de bien manger, de boire, voire de se trémousser sur la dance du dauphin...

<img src="/images/blog/remote/dauphin.gif" class="responsive"/>


### Non, la province n'est pas un désert technologique

J’ai abordé la méthodologie de travail au quotidien, le lieu et le matériel. Puis la nécessité de bien connaitre ses collègues pour rendre la communication distante aussi naturelle que possible. On n'est pas loin ici de réunir toutes les conditions suffisantes à bon déroulement d’un poste en télétravail. Mais il manque encore ce que je rangerais pour faire court dans la qualificatif de réseau.

Un réseau c’est important pour rencontrer d’autres développeurs, d’autres méthodes de travail ou d’autres technologies. C’est d’autant plus important quand on travaille dans un métier qui évolue aussi vite que le nôtre.

Et j’avoue que j’étais plein d’*a priori* de Parisien au moment de déménager à Caen. Pour ma défense, il faut reconnaitre qu’à Paris, on est particulièrement gâtés. Je pouvais par exemple sortir pratiquement tous les soirs et trouver un meetup intéressant : sur Go, Clojure, le DDD, React, D3, le meetup Mozilla,... Et cela permettait d’aller visiter l’une des innombrables startups, SS2I, sièges de groupe et autres incubateurs présents sur la place. De là-bas, je voyais un peu la province comme un grand désert...

<img src="/images/blog/remote/desert.jpg" class="responsive" />

Je me trompais lourdement. J’ai découvert une vraie activité à Caen autour du web. J’ai rencontré des startups maîtrisant comme personne une infrastructure full Docker, des agences de com' travaillant en agile, des meetups sur le web, l’agile, le développement, le SEO, l’UX... Bref, je sors encore et j’apprends encore en dehors de Marmelab. J’aimerais d’ailleurs profiter de ce post de blog pour remercier [Laurent](https://twitter.com/l_demontiers), [Valentin](https://twitter.com/ValentinCreativ), [Imagile](https://www.imagile.fr/), [YouSign](https://yousign.com/), [Margotte tournicote](https://www.margottetournicote.fr/) et le [forum digital](http://www.forum-digital.fr/) pour leur accueil.

## L'angoisse de l'ancien parisien

Au risque de divulgâcher ma conclusion, je ne regrette absolument pas mon choix de partir de Paris. Est-ce à dire que j'ai trouvé le pays des licornes ? Presque. Mais pour faire un bilan honnête, je dois quand même aborder la question du marché du travail. C'est sans doute encore une fois un réflexe de parisien (18 ans, cela laisse des traces). Il y a un nombre invraisemblable de boîtes à Paris. Des boîtes qui ont besoin de développeurs. Du coup, on y est un peu les enfants gâtés du monde du travail. Les salaires sont tirés vers le haut (de manière un peu déraisonnable à mon avis). On n'est pas vraiment soumis à la pression de trouver un job et c'est facile d'y changer de poste.

En province, c'est moins évident. Il y a du travail sans aucun doute. Mais d'une part, les projets "sexys" sont moins nombreux. Et les budgets ne suivent pas toujours, du coup les salaires sont en conséquence.

Mais je suis optimiste sur l'avenir. Notre métier est parfaitement adapté au télétravail. Les avantages de partir de Paris sont très nombreux et suffisamment convaincants pour encourager aussi bien les boites que les développeurs à mieux regarder du côté de la province. Cela conduira j'espère à une décentralisation des budgets et des projets, équilibrant ainsi ce marché du travail entre Paris et le reste de la France.

Je commence d'ailleurs à rencontrer d'autres télétravailleurs dans les meetups caennais.

## Conclusion

C’est donc un bilan presque intégralement positif que je fais de cette première année. Certes, j’aimais bien Paris, sa richesse culturelle et professionnelle. Et j’aimais beaucoup travailler dans le même bureau que mes collègues. Mais cette cohésion d'équipe fonctionne aussi très bien à distance, pour peu que l’on continue à se voir régulièrement.

Et je n’ai même pas abordé le point finalement principal dans cette histoire : **le gain de qualité de vie**. Il est très impressionnant. Quel bonheur de pouvoir finir sa journée au bord de la mer, de voir mes filles parfaitement détendues et bien occupées entre l’équitation, le théâtre, le roller et la piscine ! Le soir, le verre est à 2 euros et on n’a pas à prendre de taxi pour rentrer. Il n’y a plus de métro. Et on a presque doublé notre surface d’habitation...

<img src="/images/blog/remote/plage.jpg" class="responsive" />

Le télétravail serait donc la balle d'argent pour rendre les développeurs heureux ? Non, c'est un autre mythe. Mais c'est une solution très valable, comme d'autres. Et cela fonctionne pour moi car je suis au sein d’une équipe suffisamment petite, expérimentée et partageant cette fameuse culture de la revue de code. Je ne sais pas comment cela se passerait pour une grosse équipe ou pour une équipe de développeurs ne se connaissant pas, ou encore pour une équipe plus junior. Mais chez Marmelab, ça marche bien.

Et d’ailleurs, si cela vous tente, on [recrute](https://marmelab.com/fr/jobs) ;)
