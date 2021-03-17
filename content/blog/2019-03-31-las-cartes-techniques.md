+++
title="Les cartes techniques"
slug="les-cartes-techniques"
date = 2019-03-31
description="Si l'on se limite aux histoires utilisateur pour remplir le backlog produit, ne passe-t-on pas à côté de la plaque ?"
tags = ["Agile"]
+++

Dans son billet [« Les histoires d’utilisateurs sont surestimées »](https://marmelab.com/blog/2019/01/31/user-stories-are-overrated.html), Florian soulève le problème suivant : certains agilistes ont tendance à s’enfermer dans une forme de dogmatisme. Comme le fait d’interdire l’ajout de tout ce qui ne serait pas une histoire utilisateur dans un backlog de produit.

Ce post, écrit sous l’angle du développeur, va revenir plus en détail sur le cas des cartes techniques. Tout d’abord en interrogent les éventuelles bonnes raisons de les rejeter, ou tout du moins de s’en méfier. Puis en explorant des situations où, bien que sans valeur directe pour l’utilisateur, ce type d’entrée au backlog semble être nécessaire à la vie d’un projet.

## D’où vient ce rejet de la carte technique ?

De but en blanc, on peut avancer que c’est une manière d’introduire du taylorisme — on impose une séparation entre la pensée sur le métier (l’US) et la production — au sein d’un processus agile. Lorsque l’on connait l’histoire des méthodologies agile, cela constitue un vrai *smell* conceptuel.

Et effectivement, l’expérience tend à prouver qu’isoler la partie réalisation technique de son but final, la valeur utilisateur, peut conduire à plusieurs écueils.

### La suringénierie

C’est un reproche classique fait aux développeurs : nous aurions une fâcheuse tendance à faire des choses compliquées. Séparer la tache technique de la US illustre bien cette tendance. En le faisant, on va se mettre à raisonner sur un besoin qui s’est abstrait de la demande initiale. On va chercher des solutions plus généralistes. Étant un peu flémard, on a ce réflexe de se dire que notre solution est plutôt réussie et que donc, il suffirait d’ajouter cette petite couche d’abstraction supplémentaire pour pouvoir la réutiliser dans un autre projet sans devoir la recoder... On suringénierise rapidement, c’est vrai !

<div style="float:left; width: 330px; margin: 1rem">
    <img src="/images/technicaltasks/the_general_problem.png" alt="La suringenierie"/>
    <figcaption><a href="https://imgs.xkcd.com/comics/the_general_problem.png"/>xkcd - The General Problem</a></figcaption>
</div>

Même si l’on ne doit pas écrire nous-mêmes la brique logiciel, on va devoir en choisir une déjà existante. Alors on hésite, on se dit que cette brique pourrait bien servir à faire autre chose sur le projet que ce qui est demandé dans la tache d’origine, on *prend les devants*. À ce rythme, on a vite fait d’implémenter un Kafka pour répondre à l’US « En tant qu’utilisateur, je veux recevoir un email pour confirmer mon inscription »...

Enfin, ces briques existantes auront elles-mêmes implémenté une forte abstraction, justement pour pouvoir être réutilisé dans de nombreux contextes. Elles vont donc nécessairement introduire de la complexité.

### Des difficultés de communication

Lorsque l’on sépare la brique technique de la fonctionnalité, on introduit nécessairement une couche de complexité. En implémentant une interface de communication qui exprimera non pas le métier, mais une abstraction, on perd la possibilité d’exprimer le métier dans une partie du code. On introduit une cassure entre le langage des développeurs et celui du reste de l’équipe. On appauvrit la connaissance globale, on complexifie les échanges au sein de l’équipe. Bref on va à l’encontre du concept d’Ubiquitous Language, et ce au détriment de la valeur la plus fondamentale de l’agilité :

> Les individus et leurs interactions, de préférence aux processus et aux outils

De prime abord, ce problème de communication peut sembler anodin. Mais sur la durée d’un projet, toutes ces petites complexifications techniques deviennent sources de petites approximations dans la communication, pouvant parfois déboucher sur des résultats catastrophiques (R.I.P. Mars Climate Orbiter).

### Des erreurs d’architecture

Au-delà du langage, c’est l’architecture même du projet qui peut être faussée lorsque l’on sépare une brique technique du métier. 

<div style="float:right; width: 230px;">
    <img src="/images/technicaltasks/ddd.jpg" alt="Domain Driven Design"/>
</div>

Prenons l’exemple classique du livre dans une librairie en ligne. On peut dès le début abstraire la persistance d’un livre dans une base de données relationnelle. Puis ne plus penser ce choix dans les développements suivant. Mais un jour, un éditeur change le prix d’un livre et le lendemain, c’est la comptable qui arrive affolée, car toutes les factures liées à ce livre ont été modifiées.

C’est un sujet complexe, théorisé par le Driven Domain Design. Le meilleur conseil à fournir pour l’aborder est certainement de se procurer le livre de Éric Evans, ou d’écouter les podcasts de Café Craft sur le sujet, car cela dépasse très largement le cadre de ce post. Mais ce qui est à retenir, c’est que l’architecture logicielle d’un projet doit se construire sur les problématiques du métier, et non sur des choix d’implémentation techniques. Et c’est le risque pris lorsque l’on sépare la tache technique sous-jacente à une US. 

### Les partisans du « tout US » auraient-ils raison ?

Interdire les cartes techniques semble être une bonne stratégie pour éviter tous ces écueils. Cela oblige à maintenir un langage commun à l’équipe, à penser la technique au plus simple et de la manière la plus adaptée à ce que l’on doit faire.

Pour autant, doit-on toujours s’interdire de formaliser un besoin technique dans le backlog ? De toute manière, ce besoin apparaitra quelque part, même si cela doit se faire par d’autre biais : dans la liste des tâches de la carte, dans une Pull Request isolée… 

Étudions maintenant 5 raisons parmi d’autres pouvant au contraire justifier l’ajout de cartes techniques : la refactorisation, l’apprentissage, l’estimation, les bugs et le démarrage de projet.

## La refactorisation

La refactorisation, c’est un processus itératif. À chaque fonctionnalité entrante, on modifie un peu de code pour en intégrer du nouveau. Lorsque l’on voit une méthode qui se répète, on va faire le petit changement permettant de n'en n’avoir plus qu’une seule. On laisse toujours le campement plus propre en partant qu’en arrivant. On garde le code le plus simple possible en s’attachant à ce qu’il ne fasse qu’une seule chose. Les noms de nos fonctions sont dûment réfléchis, pour qu’elles traduisent parfaitement le métier sur lequel on travaille. D’ailleurs, le PO est capable de suivre ce que l’on fait sur Github. De plus, puisque la couverture de test est idéale, ni trop ni trop peu, avec un mix judicieux de tests unitaires, fonctionnels et end-to-end, c’est assez facile de vérifier que nos petites interventions de refactorisation ne cassent rien. On n’hésite donc jamais à le faire. On est d’autant plus sûre de nous que l’équipe à une forte culture de la revue de code. Si quelque chose nous a échappé, la perspicacité de nos collègues l’aura identifié tout de suite. Pour ne rien gâcher, on a tous lu le « Refactoring » de Martin Folwer. On connait les patterns, on voit arriver les chausse-trappes de loin. 

<div style="float:left; width: 230px; margin: 0 1rem 1rem 0; ">
    <img src="/images/technicaltasks/refactoring.jpg" alt="refactoring"/>
</div>

> « When you want to make a change, first, make the change easy. (Warning, this may be hard.) Then make the easy change » — Ken Beck

Mauvaise nouvelle : tout ce qui vient d'être décrit, c’est ce vers quoi nous tendons en tant que développeur. Mais ce n’est pas facile, loin s’en faut. Cela réclame pas mal d’expérience. Il arrive donc que l’on doive s’atteler au nettoyage la base de code. Et comme cela prend du temps, il faut ajouter une carte au backlog, car il ne s’agit pas de le faire le soir en pénitence.

Et quand bien même, l’hygiène du code serait impeccable, cela sous-entend que nous n’ayons jamais fait de technique pour la technique. Que nous ayons toujours implémenté le bon outil, la bonne architecture au bon moment. Au bon moment pour un projet qui va évoluer et, souhaitons-le, rencontrer le succès. Il faudra alors peut-être revenir sur des choix techniques pourtant rationnels au moment de les prendre. Mais ils peuvent ne plus convenir dans le temps. 
Prenons un exemple très classique : le choix d’une architecture monolithique versus une architecture en microservices. Partir sur du microservice, c’est tomber dans le travers de suringénierie décrit dans la première partie de ce post de blog. Mais si l’application prend de l’ampleur, rencontre le succès, cela deviendra pertinent de refactoriser certains services en microservices. À périmètre ISO évidemment, donc sans valeur utilisateur propre. Pourtant, il faudra une carte dans le backlog pour ce travail !

## L’apprentissage

S’extraire de la problématique technique lors de la réalisation d’une US n’est pas toujours si facile. Au même titre que la capacité à penser la refactorisation au quotidien, cela requiert de l’expérience. C’est un peu comme un musicien : avant de ne plus penser à l’instrument pour ne plus être concentré que sur la musique, il faut du temps et beaucoup de pratique. Le niveau d’une équipe n’est pas forcement homogène. On peut donc parfois être amené à extraire une partie technique d’une fonctionnalité afin de permettre une montée en compétence sur un sujet particulier.

Ceci est d’autant plus vrai qu’on ne connait jamais tout en développement tant les technologies évoluent vite. Chaque projet apporte son lot de challenges fonctionnels, challenges auxquels on peut répondre d’innombrable manière. Il faut savoir prendre des risques, essayer des technologies émergentes. Pour limiter l’impact de ces expérimentations, il est probablement prudent de consacrer des cartes d’exploration avant de faire le choix d’utiliser ou non un nouveau langage, un nouveau service, une nouvelle architecture. Ou alors, se préparer à voir apparaitre des cartes de refactorisation. 

<div style="float:right; width: 300px; margin: 0 0 1rem 1rem; ">
    <img src="/images/technicaltasks/noIdea.png" alt="Carte d'exploration"/>
</div>

Chez Marmelab, pour un projet où nous avions décidé de choisir TypeScript que nous ne connaissions pas, nous avons dû faire machine arrière au bout d’une semaine tant son utilisation, mal maitrisée, nous ralentissait. Nous avons pris la décision d’ajouter une carte au backlog « Supprimer TypeScript ». Pour autant, nous n’avons pas mis TypeScript sur notre liste noire des technos. Au contraire, nous l’employons maintenant sur d’autres projets. En partie grâce à cette prise de risque lors de ce premier projet qui, bien qu’ayant en un sens échoué, nous a permis de mieux appréhender TypeScript sur les projets suivants. 

On peut tout de même se poser la question de l'à-propos de ces cartes d’apprentissage techniques. Doivent-elles être réellement intégrées au backlog d’un projet ? La question est d’autant plus délicate dans un contexte de service. Si l’intérêt est évident dans le cas d’une équipe travaillant sur son propre produit, car il s’agira alors d’une carte produisant de la connaissance pour l’entreprise, cela est peut-être moins évident lorsque c’est le prestataire qui gardera cette connaissance. De manière un peu ingénue, on peut répliquer que même dans ce cadre, l’équipe projet ne forme qu’un, que ses membres soient clients ou qu’ils soient externes. La connaissance y sera partagée par tous. Mais de manière plus pragmatique, cette curiosité technique, cette capacité à prendre des risques, à défricher de nouvelles technos est une vraie plus-value, particulièrement pour des projets web. C’est un atout de choix dans l’agilité. Cela a logiquement un coût qui pourra se traduire par l’apparition de telle carte « d’apprentissage » au sein du backlog.

## L’estimation

Voici un cas classique d’apparition d’une carte technique. L’estimation au sein d’un projet agile fait débat, et selon que l’on sera pour ou contre ce processus d’estimation, l’apparition de ce type de carte sera un argument de défense ou un argument à charge.

Pour estimer les cartes du backlog, on va s’attacher à leur donner des valeurs relatives les unes par rapport aux autres. En effet, personne ne donne des valeurs en temps de réalisation. Personne.

Imaginons donc deux US : 

* « En tant qu’utilisateur, lorsque je termine mon inscription je veux recevoir un email me confirmant mon inscription »
* « En tant de community manager, lorsqu’un nouvel utilisateur termine son inscription je veux recevoir un email m’avertissant de cette inscription pour pouvoir le remercier »

<div style="float:left; width: 300px; margin: 0 1rem 1rem 0; ">
    <img src="/images/technicaltasks/estimate.jpg" alt="Les estimations"/>
</div>

Comparées l’une à l’autre, ces deux cartes devraient avoir un poids très proche. Mais qu’en est-il de la brique technique permettant l’envoi de ces emails : mise en place d’un serveur smtp sur les serveurs, d’un mock smtp pour le développement en local, du système de templating des emails, du système d’alerte en cas d’échec de l’envoi des emails.. ? 
Doit-on faire porter ce poids à la première carte, lui donnant une valeur démesurée par rapport à la seconde ? Où doit-on créer une carte technique « Mise en place du système d’envoi d’email », permettant d’attribuer la même valeur aux deux US ? Quitte à prendre le risque d’avoir une valeur plus importante pour les trois taches cumulées. Rappelez-vous, il faudra peut-être installer Kafka, ce qui n’est jamais une sinécure ! 
Ou doit-on abandonner les estimations, cela ne veut rien dire, et de toute façon l’équipe est au courant de l’existence de la partie technique ne se posera donc pas la question de la différence d’avancement des deux cartes au daily ?

Il n’y a sans doute pas de bonne réponse. Cela va dépendre du fonctionnement de l’équipe, de la manière de faire la plus explicite et la confortable pour elle.

## Les bugs

> « Ce n’est pas un bug, c’est une nouvelle feature ! » 

Les développeurs aiment beaucoup polémiquer sur ce thème. 

![Bug Vs Feature](/images/technicaltasks/bugVsFeature.jpg)

Tant qu’une fonctionnalité n’a pas été acceptée selon des critères clairement définis (la fameuse colonne done), ce ne sera jamais un bug. Par contre, une fois la carte acceptée, de deux choses l’une :

* Soit la fonctionnalité ne fonctionne pas (c’est binaire), elle produit une erreur. Dans ce cas, c’est un bug.
* Soit la fonctionnalité n’opère pas tout à fait dans les bonnes conditions. Dans ce cas, c’est une nouvelle fonctionnalité, puisque la fonctionnalité d’origine n’a pas été définie sous les mêmes conditions. La preuve, elle a été acceptée.

Dès lors, le bug est nécessairement un problème technique. Cette carte technique doit-elle apparaître dans le backlog ? Bien sûr ! On peut même organiser le flux d’avancement des cartes en prenant spécifiquement en compte ces cartes du bug : il s’agit du Zero-Bug Software Development.

## Le démarrage du projet

Si les points précédents tendent à expliquer le bien-fondé de l’existence des taches techniques au sein du backlog, il n’en reste pas moins que l’approche « user centric » reste primordiale dans une approche agile. Les US traduisant les besoins de l’utilisateur constituent la substantielle moelle du projet.

La réalisation de ces cartes exige une bonne identification de la fonctionnalité, de ses conditions de réalisation et donc d’acceptation. Pour cela, il faut obtenir le plus rapidement possible des retours sur ce qui a été réalisé. Un retour de l’équipe, mais surtout un retour des utilisateurs. 

**Une US ne pourra être considérée comme terminée qu’à l’aune du retour des utilisateurs.
Il faut donc qu’elle soit en production.**

Cela exige une infrastructure technique solide, mais parfois négligée. C’est pourtant le préalable à toutes réalisations d’US. Cela va du bon accès à la base versionnée du code par tous les développeurs au déploiement sur un serveur accessible aux utilisateurs finaux. On parle ici de toute une machinerie incluant l’automation des tests, des outils de revue de code, d’accès ssh aux serveurs, d’outils d’intégration continue et de déploiement... 
Certains parlent d’usine de développement (UDD). Si l’on se méfie des métaphores empreintes de tayloriste, on préférera parler d’atelier de développement, dans un esprit plus « Software Craftmanship ».

![CraftmanShip](/images/technicaltasks/craftmanship.jpg)

Cette phase de « préparation de l’atelier », purement technique, est pourtant souvent cachée sous le tapis des premières fonctionnalités. Ce faisant, on ne cache non pas la technique induite par la carte, mais un rouage indispensable à la réalisation d’un projet informatique. C’est une erreur, car cela risque de faire partir l’équipe sur de la frustration et de la méfiance. 

Mais en se concentrant sur une première tâche consistant à s’assurer d’un `hello project` déployé sur un serveur accessible aux utilisateurs, on pourra ensuite sereinement tracter les cartes du backlog à la colonne `done`.

## Conclusion

N’accepter que des histoires utilisateurs dans le backlog produit, c’est nier la richesse d’un projet en pensant qu’il n’y a de valeur que pour l’utilisateur. S’il est important, voir enrichissant de se poser des questions au moment d’introduire une carte technique, c’est aussi appauvrir le projet que de les refuser par principe. Ce faisant, il ne perdra peut-être pas de valeur pour l’utilisateur, mais il en perdra en termes de qualité, d’apprentissage, d’innovation et même d’agilité.

## Références

* [User Stories Are Overrated](https://marmelab.com/blog/2019/01/31/user-stories-are-overrated.html)
* [Un-SAFe At Any Speed: Rethinking Scale and Agility](https://www.linkedin.com/pulse/un-safe-any-speed-rethinking-scale-agility-sam-mcafee/)
* [UbiquitousLanguage](https://www.martinfowler.com/bliki/UbiquitousLanguage.html)
* [Manifesto for Agile Software Development](https://agilemanifesto.org/)
* [What is Domain-Driven Design?](http://dddcommunity.org/learning-ddd/what_is_ddd/)
* [Café Craft Episode 29: le DDD Stratégique, avec Cyrille Martraire](https://www.cafe-craft.fr/29)
* [The State of Agile Software in 2018](https://martinfowler.com/articles/agile-aus-2018.html)
* [Les estimations sont fausses, surtout si on considère qu'elles sont justes \| pablo pernot](https://pablopernot.fr/2018/09/les-estimations-sont-fausses-surtout-si-on-considere-qu-elles-sont-justes/)
* [Ne sous-estimons pas le rôle des estimations. - Imagile](https://www.imagile.fr/ne-sous-estimons-pas-le-role-des-estimations/)
* [Zero-Bug Software Development – Quality Faster – Medium](https://medium.com/qualityfaster/the-zero-bug-policy-b0bd987be684)
* [Démarrer un projet plus vite que l’UDD \| OCTO Talks !](https://blog.octo.com/demarrer-un-projet-plus-vite-que-ludd/)
* [Manifesto for Software Craftsmanship](http://manifesto.softwarecraftsmanship.org/)
