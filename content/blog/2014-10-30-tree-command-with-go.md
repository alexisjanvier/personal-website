+++
title="Une commande tree plus efficace grâce au Go"
slug="une-commande-tree-plus-efficace-grace-au-go"
marmelab="https://marmelab.com/blog/2014/10/30/tree-command-with-go.html"
date = 2014-10-30
description="Peut-on facilement et rapidement améliorer la classique commande `tree` grâce au langage Go ? Nancy étant dans les cartons, c'est Paris qui s'y colle pour cette journée de Hackday."
tags = ["go"]
+++

Chez Marmelab, un hackday c'est comme une semaine d'intégration, mais sur une journée : une hypothèse définie le matin, un produit fonctionnel et testé le soir sur une nouvelle techno ; et aussi un post de blog pour en parler, dans la nuit. Le plus, c'est qu'on est par équipes.
Pour ce hackday un peu spécial, pour cause de Hack Dayménagement à Nancy, l'équipe parisienne planche sur la reproduction, voir l'amélioration de la commande [tree](http://fr.wikipedia.org/wiki/Commande_tree) bien connue.

## Mise en place de l'environnement de développement
Première étape pour cette journée de découverte du Go : la mise en place de l'environnement de développement. Après l'[installation](https://golang.org/doc/install) proprement dite, il s'agit de configurer le *workspace*, soit un répertoire contenant trois sous-répertoires :

* ***bin*** qui va contenir les exécutables finaux de nos programmes Go,
* ***pkg*** qui va contenir les objets de package utiles aux commandes,
* ***src*** qui va contenir les fichiers sources des packages (c'est le plus souvent dans ce dossier que l'on va mettre notre propre code).

Ce répertoire doit être ajouté à une variable d'environnement GOPATH. Donc si classiquement on définit un répertoire Go à la racine de notre répertoire utilisateur, on va faire un  :

    export GOPATH=$HOME/Go
    export PATH=$PATH:$GOPATH/bin

Ce qui est génial, c'est que du coup, lorsque l'on va compiler un programme Go (avec un `Go install path/to/pgm`), il sera directement accessible depuis la ligne de commande.

Nativement, Go s'installe avec un programme permettant de corriger le formatage d'un fichier.Go : [gofmt](https://golang.org/cmd/gofmt/). Pour ceux travaillant avec Sublime Text, ne reste plus qu'à installer et configurer le plugin [SublimeGo](https://github.com/DisposaBoy/GoSublime) pour pouvoir commencer à coder sur de bonnes bases.


## Première implémentation : reproduire tree
Notre premier objectif a consisté en la reproduction de l'affichage "en arbre" du contenu d'un répertoire. Pour cela, nous avons utilisé les outils de la librairie standard du Go (`flag`, `io/ioutil` et `strings`), ainsi qu'une programmation très procédurale. Du coup, nous avons assez rapidement atteint notre premier objectif.

``` go
package main

import (
    "flag"
    "fmt"
    "io/ioutil"
    "strings"
)

func main() {
    flag.Parse()
    path := "./"
    if userpath := flag.Arg(0); userpath != "" {
        path = userpath
    }

    displayDir(path, "")
}

func displayDir(path string, previousIndent string) {
    files, _ := ioutil.ReadDir(path)
    nbElements := len(files)
    indent := "├──"
    nextIndent := " │       "

    for i, f := range files {
        if i == nbElements-1 {
            indent = "└──"
            nextIndent = "       "
        }

        if f.IsDir() {
            s := []string{path, f.Name()}
            nextPath := strings.Join(s, "/")
            fmt.Println(previousIndent, indent, f.Name())

            s[0] = previousIndent
            s[1] = nextIndent
            displayDir(nextPath, strings.Join(s, ""))
        } else {
            fmt.Println(previousIndent, indent, f.Name())
        }
    }
}

func displayIndent(previousIndent string) (nextIndent string) {
    s := []string{previousIndent, "-"}
    nextIndent = strings.Join(s, "/")
    return
}
```

<img src="/images/blog/gotreev0.png" class="medium" >


## Seconde implémentation : ajouter de l'interactivité
Une fois ce premier objectif atteint, nous devions décider si :

* nous allions continuer à reproduire la commande initiale tree (mise en place des nombreuses options),
* ou bien si nous allions dévier de la commande originale pour y ajouter de l'interactivité.

C'est cette seconde option qui a été choisie, et ce grâce à l'utilisation de la bibliothèque [termbox-Go](https://github.com/nsf/termbox-Go), implémentation en Go de la librairie [termbox](https://code.google.com/p/termbox/).

Cette seconde implémentation fut l'occasion d'un premier refactoring, et donc d'une première approche de l'organisation du code. Nous avons opté pour la mise en place de notre package `gotree` au niveau de la racine de notre répertoire de travail, et nous avons écrit notre script principal `main` dans un sous répertoire cmd.

<img src="/images/blog/gotreeorga.png" class="small" >

``` go
package main

import (
    "github.com/marmelab/gotree"
)
```

Nous aurions pu au contraire mettre notre script principal `main` à la racine de notre répertoire de travail, et l'ensemble des autres fichiers dans un sous-répertoire au sein d'un package nommé par exemple gotree_tools, importés dans notre script `main` via un import 'github.com/marmelab/gotree/gotree_tools'.

``` go
package main

import (
    "github.com/marmelab/gotree/gotree_tools"
)
```

Suite à cette seconde implémentation basée sur `termbox`, nous avons maintenant une commande console s'éloignant de tree (nous n'avons plus de visualisation en arbre des répertoires et sous-répertoires) mais interactive.

<center>
<div class="video-container">
<iframe src="//player.vimeo.com/video/110195230" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
</div>
</center>

## Du code testable : passage en POO
Avant d'aller plus loin, il était temps de se pencher un peu sur les tests. En effet, notre méconnaissance et notre découverte du langage par tâtonnement a été une bonne excuse pour ne pas faire du TDD dès le début. Résultat, même avec un code refactorisé, notre code n'était pas testable à cette étape.

A propos des tests, Go dispose de base d'une [bibliothèque de tests](http://golang.org/pkg/testing/) et l'on trouve un grand nombre de projets permettant d'étendre ces outils de tests. Nous avons choisi pour gotree le projet [http://golang.org/pkg/testing/](https://github.com/stretchr/testify), ajoutant aussi bien des fonctionnalités d'assertion non présentes en natif que des outils de mocks.
Et c'est ce besoin de réaliser un mock de la bibliothèque termbox qui nous a obliger à refactoriser notre code.

Nous avons alors converti nos fonctions en objets, plus précisement en structures, ce qui diffère sensiblement d'un object en PHP ou Java par exemple.
Nous nous sommes confrontés à l'utilisation des [interfaces en Go](https://golang.org/doc/effective_go.html#interfaces), très différentes des interfaces PHP avec lesquelles nous étions plus familiers.

Voici un extrait de notre commande `main` après le passage en POO:

``` go
// Notre objet Termbox implémente l'interface Screen
var screen gotree.Screen = new(gotree.Termbox)
// L'objet Screen est inclu dans le Displayer
displayer := &gotree.Displayer{screen}

displayer.Init()
defer func() {
    displayer.Terminate()
}()

navigator := gotree.NewNavigator(displayer, rootPath)
navigator.InitDir(rootPath)
```

Go possède quelques particularités en ce qui concerne l'écriture des structures, en voici quelques unes.

Vous avez peut être noté la syntaxe, quelque peu scolaire, de décalaration de la variable `screen` :

``` go
var screen gotree.Screen = new(gotree.Termbox)
```

La syntaxe raccourcie `:=` est habituellement utilisée, nous aurions pu écrire ceci:

``` go
screen := new(gotree.Termbox)
```

Ces deux codes semblent identiques, et en effet se comportent de la même façon, mais une subtilité persiste.
L'interface `Screen` comporte 4 méthodes. En Go, comme dans la plupart des autres langages, rien ne nous empèche de rajouter des méthodes.
Mais attention, en Go, si vous avez déclaré votre structure à l'aide de la première syntaxe, le compilateur de Go va vous indiquer que cette nouvelle méthode, que vous essayez d'appeler sur votre variable, n'existe pas.

Une autre particularité d'une structure consiste à lui injecter une autre structure en paramètre sans préciser de nom de propriété dans laquelle l'inclure.

Ce sont des [propriétés anonymes en Go](https://golang.org/ref/spec#Struct_types) qui ressemblent à une forme d'héritage. Il s'agit d'une forme de composition de classe particulière : [l'Embedding](http://golang.org/doc/effective_go.html#embedding).
Voici par exemple un extrait de notre structure `Displayer` :

``` go
type Displayer struct {
    Screen
}

func (d Displayer) Stop() {
    d.Flush()
}
```

On peut voir que le `Displayer` fait appel à une méthode `Flush()` qui n'est disponible que dans la structure `Screen`, un peu déroutant pour nous au début.

Pour finir, il y a plusieurs façons d'instantier une structure en Go.

``` go
display := new(gotree.Displayer(screen))
display = &gotree.Displayer{screen}

// A l'aide d'une Factory
func NewDisplayer(screen Screen) *Displayer {
    return &Displayer{screen}
}
display = NewDisplayer(screen)
```

Toutes trois retournent le même résultat.

## Ecriture des tests

Voici le test d'une méthode de notre structure `Navigator`:

``` go
package gotree

import (
    "github.com/nsf/termbox-Go"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "testing"
)

type DummyScreen struct {
    mock.Mock
}

func (ds *DummyScreen) Clear(fg, bg termbox.Attribute) error {
    args := ds.Called(fg, bg)

    return args.Error(0)
}

func (ds *DummyScreen) Flush() error {
    args := ds.Called()

    return args.Error(0)
}

func (ds *DummyScreen) SetCell(x, y int, ch rune, fg, bg termbox.Attribute) {
    ds.Called(x, y, ch, fg, bg)
}

func (ds *DummyScreen) Size() (int, int) {
    args := ds.Called()

    return args.Int(0), args.Int(1)
}

func TestInitDir(t *testing.T) {
    assert := assert.New(t)

    screen := new(DummyScreen)
    displayer := &Displayer{screen}
    navigator := NewNavigator(displayer, "fake")

    screen.On("Clear", 0, 0).Return(nil)
    screen.On("Flush").Return(nil)
    screen.On("SetCell", 0, 0, 102, 8, 5).Return()
    screen.On("SetCell", 1, 0, 97, 8, 5).Return()
    screen.On("SetCell", 2, 0, 107, 8, 5).Return()
    screen.On("SetCell", 3, 0, 101, 8, 5).Return()
    screen.On("SetCell", 4, 0, 47, 8, 5).Return()
    screen.On("SetCell", 5, 0, 100, 8, 5).Return()
    screen.On("SetCell", 6, 0, 105, 8, 5).Return()
    screen.On("SetCell", 7, 0, 114, 8, 5).Return()
    screen.On("Size").Return(1, 1)

    // assert equality
    assert.Equal(navigator.currentLine, 0, "currentLne is 0 on instantiation")
    assert.Equal(navigator.rootPath, "fake", "rootPath is set to new value on instantiation")
    assert.Equal(navigator.currentPath, "fake", "currentPath is set to rootPath on instantiation")

    navigator.currentLine = 3
    navigator.InitDir("fake/dir")
    assert.Equal(navigator.currentLine, 0, "currentLine is reseted after InitDir() call")
    assert.Equal(navigator.currentPath, "fake/dir", "currentPath gets the the new value given by InitDir()")
}
```

Nous avons retrouvé dans l'écriture des tests une façon de procéder assez similaire à d'autres langages de programmation.
La librairie de mock est simple d'utilisation et la librairie d'assertion est tout à fait standard.

## Utilisation des Goroutines

Afin de finir cette journée de hack sur une des particularités de Go, nous avons implémenter *in extremis* les goroutines, qui à ce stade, n'apportent pas grand chose en terme de performance.

``` go
func InitDir(path string) {
    if "" == rootPath {
        rootPath = path
    }

    displayStart()

    displayBreadcrumb(path)

    c := make(chan File)
    Go fetchFiles(path, c)

    first := true
    i := 0
    for f := range c {
        displayLine(i+1, f, first)

        first = false
        i += 1
    }

    displayStop()

    currentPath = path
    currentLine = 0
}

func fetchFiles(path string, fs chan File) {
    files = make([]File, 0)
    var file File
    dirFiles, _ := ioutil.ReadDir(path)

    for _, f := range dirFiles {
        if f.IsDir() && strings.HasPrefix(f.Name(), ".") {
            continue
        }
        file = File{f.IsDir(), f.Name()}
        fs <- file

        files = append(files, file)
        // do something
    }

    close(fs)
}

```

## Conclusion

Une journée, c'est très court pour réussir à fournir un produit fonctionnel sur une nouvelle techno ou un nouveau langage. Il faut savoir ne pas être trop ambitieux sur la définition du produit. Et nous ne l'étions pas en début de journée, réussissant assez vite à reproduire le fonctionnement de base de la commande `tree` (première implémentation).
Mais nous avons ensuite été un peu trop ambitieux en voulant ajouter une interactivité qui n'a finalement que dénaturé le produit. Reste que cela a été l'occasion d'aborder plus sérieusement le Go via la POO et les tests, ce qui était aussi l'un des objectifs de cette journée de hackday, loin des cartons.

***Post-scriptum*** : *le code de cette journée est [disponible sur Github](https://github.com/marmelab/gotree).*

