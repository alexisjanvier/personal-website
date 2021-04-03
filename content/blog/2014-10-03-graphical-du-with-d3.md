+++
title="Une console plus graphique avec node.js et d3.js"
slug="une-console-plus-graphique-avec-nodejs-et-d3js"
date = 2014-10-03
description="\"Afficher graphiquement l'occupation disque d'un répertoire dans la console en Javascript\" : l'énoncé du problème est très motivant. Mais après 5 jours à en tenter l'implémentation, peut-on dire que node.js et d3.js sont utilisables pour des rendus graphiques dans un terminal ? Oui. Mais ..."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["dataviz", "console"]
[extra]
marmelab="https://marmelab.com/blog/2014/10/03/graphical-du-with-d3.html"
+++

<img src="/images/blog/treedu1.png" class="medium" >

On présente souvent node.js comme un outil très pratique pour exécuter du code javascript côté serveur. Mais il sert à beaucoup d'autres choses comme exécuter du javascript côté … poste de travail ; Gulp ou Yeoman en sont des exemples évidents. Pour ce 4ième projet « un produit fonctionnel par semaine sur une techno inconnue », j'ai découvert node.js et d3.js. L'objectif : rendre plus graphique la commande [`du `](http://fr.wikipedia.org/wiki/Du_(Unix)).

## Des promesses pour calculer la taille des répertoires
`du` doit afficher l'espace disque alloué pour tous les fichiers et dossiers contenus dans le dossier courant. Le but du projet sera de représenter sous une forme graphique l'occupation du répertoire courant.
Node.js dispose pour cela d'une bibliothèque très complète : [`fs`](http://nodejs.org/api/fs.html). La problématique consistait donc plutôt à rendre le processus performant : il fallait analyser chaque sous répertoire en parallèle afin de ne pas rendre l'exécution de la commande trop longue. Et pour cela, l'utilisation de promesses semblait tout indiquée, node.js disposant de plusieurs bibliothèques permettant de les gérer. L'une des plus utilisées est [Q](https://github.com/kriskowal/q). Il existe également une adaptation de `fs` aux promesses : [q-io](https://github.com/kriskowal/q-io) (les fonctions ne prennent plus de callback en paramètre, mais renvoient des promesses) .
Sans surprise, le fonctionnement des promesses est le même que sous angular, avec la déclaration d'un `deferred`, résolu en cas de succès, rejeté en cas d'erreur :

``` javascript

[...]

var deferred = q.defer();
getSize(folder.path, function(err, size) {
    if (err) {
        return deferred.reject(err);
    }
    self.folders.push({ path: folder.path, size: size});
    deferred.resolve(true);
});

[...]
```

Pour être performant, il ne s'agissait pas de lancer le calcul de taille de tous les répertoires en les chainant avec des `then`, mais plutôt de pouvoir les lancer tous en parallèle et de ne renvoyer un résultat qu'une fois tous les calculs terminés. Ceci est possible grâce à l'utilisation d'un tableau de promesses et de la fonction `q.all` :

``` javascript
var q = require('q');
var fs = require('q-io/fs');
var getSize = require('get-folder-size');

[...]

FolderAnalyzer.prototype.sortFilesAndFolders = function(){
    var promises = [];
    var self = this;
    // self.files is an array of file name or folder name contained in current folder
    self.files.forEach(function (file) {
        promises.push(fs.stat(file).then(function(statFile){
            if (statFile.isFile()) {
                self.filesSize += statFile.size;
            }
            if (statFile.isDirectory()) {
                 self.foldersPath.push({ path: file});
            }
            return true;
        }, function(error) { return error; })));
    });
    return q.all(promises);
};
```

Avec du recul cela peut sembler aller de soi, mais je dois bien avouer m'être fait quelques noeuds à la tête au moment d'aborder ces traitements asynchrones de fonctions via des promesses... (et merci [@Robin](https://twitter.com/RobinBressan) pour ton aide).

## Dessiner dans la console
Une fois les données recueillies, se pose la question de leur affichage sous forme graphique dans un terminal. Pour cela on peut utiliser [drawille](https://github.com/asciimoo/drawille), un projet initialement écrit en python permettant d'utiliser les caractères Unicode destinés au braille pour dessiner dans la console via l'api de [Canvas](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API). Le projet a été porté sur Go, Php, Ruby, ... et sur [node.js](https://github.com/madbence/node-drawille).

Voici ce que cela peut donner :

``` javascript

var Canvas = require('drawille-canvas');

var c = new Canvas(160, 160);

var drawLeft = function(c) {
    c.beginPath();
    c.moveTo(0,30);
    c.lineTo(0,90);
    c.lineTo(30,110);
    c.lineTo(30,80);
    c.lineTo(60,100);
    c.lineTo(60,70);
    c.lineTo(0,30);
    c.closePath();
    c.stroke();
};

[...]

function draw() {
    var now = Date.now();
    c._canvas.clear();
    c.save();
    c.translate(20, 20);
    drawLeft(c);
    drawRight(c);
    drawTop(c);
    c.restore();
    console.log(c._canvas.frame());
}

draw();

```

<img src="/images/blog/treedu2.png" class="small" >


## Dessiner dans la console avec drawille et d3.js
Il existe un projet bien connu dédié à la "data visualization" en javascript : [d3.js](http://d3js.org/). Pour faire très bref, d3 va permettre de :

* sélectionner un ou des éléments du DOM,
* associer des données à ces éléments (et, au besoin, en ajouter ou en supprimer),
* faciliter la transformation du tout en éléments graphiques de visualisation (courbes, donuts, graphes, ...).

Pour cela, d3 dispose de toute une collection de helpers permettant entre autres de formater les données d'entrées pour les rendre compatibles avec la visualisation (par exemple en coordonnées). Pour ceux qui ne connaissent pas d3, il en existe une multitude de présentations sur le web, dont cette [excellente vidéo](http://www.youtube.com/watch?v=eO59HizTF8k) réalisée aux Apéros Web Nancy.

Evidemment, avec une console, on ne dispose pas de DOM. Il va donc falloir ruser et utiliser le projet [jsdom](https://github.com/tmpvar/jsdom) qui est une implémentation javascript du DOM, utilisable avec node.js.
Second petit point de bloquage : d3 dispose de beaucoup de méthodes pour générer des formes avec SVG, mais très peu avec Canvas. d3 étant un projet disposant d'une bonne communauté, on trouve rapidement un plugin consacré à cette fonctionnalité : [d3-canvas](https://github.com/bspoon/d3-canvas).

Voici ce que donne l'implémentation du dessin du M précédent avec d3.js surchargé par le plugin d3-canvas, jsdom et drawille :

``` javascript

'use strict';

var d3 = require('./lib/d3Canvas');
var canvas = require('drawille-canvas');
var context = new canvas(160, 160);
var jsdom = require('jsdom');
var  htmlStub = '<html><body><div id="canvas"></div></body></html>';

jsdom.env({ features : { QuerySelector : true }, html : htmlStub,
    done : function(errors, window) {
        var canvasDom = window.document.querySelector('#canvas');
        var line = d3.canvas.line(context);
        context.translate(30, 20);
        var leftSide = [[0,30], [0,90], [30,110], [30,80], [60,100], [60,70], [0,30]];
        var rightSide = [[60,100], [90,80], [90,110], [120,90], [120,30], [60,70]];
        var top = [[0,30], [30,10], [60,30], [90,10], [120,30]];
        d3.select(canvasDom).call(line, leftSide);
        d3.select(canvasDom).call(line, rightSide);
        d3.select(canvasDom).call(line, top);
        console.log(context._canvas.frame());
    }
});

```


## Retour au projet : changement de cap
A ce stade le projet était sur la bonne voie : on récupère les données (tailles des sous-répertoires en asynchrone), on traite ces données pour les rendre compatibles avec la visualisation graphique (d3.js) et on dispose d'une méthode pour dessiner dans la console avec l'api Canvas (drawille).
L'objectif initial était de reproduire un affichage à la "[daisydisk](http://www.daisydiskapp.com)", en s'aidant du layout [Sunburst Partition](http://bl.ocks.org/mbostock/4063423) de d3.js.

<img src="/images/blog/treedu3.png" class="small" >

Mais plusieurs points bloquaient tout de même :

* la résolution de ce que l'on affiche sous drawille est très faible, rendant difficile l'affichage assez fin de type Sunburst,
* toute l'api Canvas n'est pas encore implémentée sous drawille pour node.js : on ne dispose pas de la méthode `arc` indispensable à affichage de type sunburst,
* on ne dispose pas de la méthode `fillText`,
* drawille ne gère pas les couleurs.

Afin de s'assurer un produit fonctionnel à la fin des 5 jours l'objectif a donc été légèrement modifié en se réorientant vers le layout [treemap](http://bl.ocks.org/mbostock/4063582) de d3.js :

<img src="/images/blog/treedu4.png" class="small" >

En effet, la méthode `fillRect` (dessin de rectangle) est bien présente dans drawille. Voila ce que cela donne avec des données réelles :

``` javascript

'use strict';

var d3 = require('./lib/d3Canvas');
var canvas = require('drawille-canvas');
var context = new canvas(160, 320);

var drawChart = function(treemapData) {
    var treemap = d3.layout.treemap()
        .children(function (d) {return d.children;})
        .size([160,320])
        .value(function (d) {return d.size;})
        .mode('squarify')
        .nodes(treemapData);

    function position(d) {
        context.fillRect(d.x, d.y,
        Math.max(0, d.dx),
        Math.max(0, d.dy));
        context.clearRect(d.x + 1, d.y + 1,
        Math.max(0, d.dx) - 3,
        Math.max(0, d.dy) -3);
    }
    treemap.forEach(position);

    console.log(context._canvas.frame());
};

getTreemapDataFromFolder().then(drawChart);

```

<img src="/images/blog/treedu5.png" class="small" >

Pas franchement sexy et plus ennuyeux, pas très fonctionnel ...

## Blessed
La preuve que l'on peut utiliser node.js et d3.js pour dessiner dans la console a bien été faite. Mais les limitations de drawille (pas de texte, pas de couleur, résolution très faible) laissent tout de même une impression d'inaccompli.
Afin de rendre le produit final plus fonctionnel, le projet [blessed](https://github.com/chjj/blessed) est venu à la rescousse. Il s'agit d'un portage de [`curses`](http://fr.wikipedia.org/wiki/Curses) sur node.js qui va nous permettre d'afficher du texte ou encore d'ajouter de l'interactivité.
Le principe de `blessed` est assez simple : on définit un `screen` global dans lequel on va pouvoir disposer des boites et contrôler leur contenu. Le `screen` dispose d'un certain nombre de méthodes, incluant des évènements `resize`, `mouse` ou `keypress`.

<center>
<div class="video-container">
<iframe src="//player.vimeo.com/video/107686699" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
</div>
</center>

## L'application node.js en ligne de commande
Dernière touche au projet : rendre l'application node.js disponible comme n'importe quel utilitaire en ligne de commande.
Tout d'abord il faut gérer les paramètres optionnels de la commande. [commander.js](https://github.com/visionmedia/commander.js/) est l'une des librairies disponibles permettant de gérer ces paramètres. Elle génère aussi le `help` de la commande :

``` javascript
    var cli = require('commander'),
        VERSION = require('./package.json').version;

    cli.option('-p, --path  [path to folder]', 'folder path to display', './')
        .option('-t, --theme  [name]', 'set the treedu theme [' + themes + ']', 'marmelab')
        .version(VERSION)
        .parse(process.argv);

    [...]
    currentPath = cli.path;

```

<img src="/images/blog/treedu7.png" class="medium" >

Ensuite, il faut rendre le script exécutable, et ajouter un `shebang` en première ligne du script (cela permet au système de savoir quel interpreteur il doit utiliser pour executer le fichier).

``` javascript
#!/usr/bin/env node
[...]
```

Voici une version un peu "hackée" et déplacée dans un fichier spécifique `bin/treedu.js` (rendant l'exécutable distinct du script node.js).

``` javascript
#!/usr/bin/env node
':' //; # This line below fixes xterm color bug on Mac - https://github.com/MrRio/vtop/issues/2
':' //; export TERM=xterm-256color
':' //; exec "$(command -v nodejs || command -v node)" "$0" "$@"

require('../app.js');
```

Et pour finir, il faut ajouter dans le fichier `package.json` une entrée `bin` pointant vers ce fichier exécutable :

``` javascript

{
  "name": "treedu",
  "version": "0.0.3",
  "description": "Analyze disk usage, as du, but graphically as treemap, in terminal. The project use D3.js and node.js",
  "main": "app.js",
  "preferGlobal": true,
  "scripts": {
    "test": "make test"
  },
  "bin": {
    "treedu": "./bin/treedu.js"
  },
[...]
```

On peut maintenant installer le script en global vie un `npm install -g`.
Il n'y a plus qu'à taper `treedu` dans la console pour lancer le script.

L'ensemble du code du projet est disponible sur le GitHub de marmelab : [https://github.com/marmelab/treedu](https://github.com/marmelab/treedu).

## Conclusion
Au final, le bilan du projet est en demi-teinte. C'est un semi-echec tant l'affichage graphique apporte peu à la fonctionnalité. La faute à la trop faible résolution induite par les caractères Unicode destinés au braille, à l'impossibilité de gérer les couleurs au sein du graphique et à l'impossibilité d'écrire du texte autrement que point par point.
Mais également semi-succès puisque preuve est faite que l'on peut utiliser node.js avec d3.js pour générer des graphiques dans la console, tant que l'on souhaite visualiser une information ne demandant pas trop de précision.
J'en veux pour exemple le vraiment très bon [vtop](http://parall.ax/vtop) qui est à la commande `top` ce que j'aurais voulu que soit `treedu` à `du`.
