+++
title = "Du PHP au Go: une semaine pour réaliser un produit fonctionnel"
slug = "du-php-au-go-une-semaine-pour-realiser-un-produit-fonctionnel"
date = 2014-09-22
description = "Du PHP au Go: une semaine pour réaliser un produit fonctionnel."
draft = false
in_search_index = true
[taxonomies]
tags = ["go"]
categories = ["informatique"]
[extra]
marmelab = "https://marmelab.com/blog/2014/09/22/golang-par-la-pratique.html"
+++

<img src="go-by-practice.png">

Fraichement arrivé chez Marmelab, ma mission actuelle constiste à produire un applicatif par semaine, sur une techno inconnue, avec une bonne qualité de code (tests unitaires, réutilisabilité) et un produit fonctionnel à la fin. Il s'agit de s'accoutumer au mantra *« learn fast, fail fast, and recover fast. »* (voir [One New Tech Per Project](http://marmelab.com/blog/2014/09/01/one-new-tech-per-project.html)). Si ma première semaine était plutôt *fail fast* (elle s'est terminée sans produit fonctionnel), ma seconde semaine m'a semblée plutôt *learn fast*. La mission consistait à réaliser un webservice lié à Github et aux Pull Requests, en Go. Cette première approche pratique d'un langage typé et compilé fut un réel plaisir, tant Go semble respecter son engagement à rendre facile l'écriture de programmes simples, fiables et efficaces. Voici quelques éléments de feedback.

## Mise en place d'un webservice
Les fonctionnalités du Go sont étendues via des packages, le langage étant livré de base avec une boite à outils conséquente (la « [standard library](http://golang.org/pkg/) »). Même si google retourne très rapidement des résultats sur des packages destinés à la mise en place de serveurs web ([mux](http://www.gorillatoolkit.org/pkg/mux), [Martini](http://martini.codegangsta.io/)), on trouve dans la librairie standard un excellent package dédié, le package [http](http://golang.org/pkg/net/http/).

``` go
package main

import (
    "fmt"
    "net/http"
)

func handler(response http.ResponseWriter, request *http.Request) {
    fmt.Fprintf(response, "Hi there, I love %s!", request.URL.Path[1:])
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
```

Avec 15 lignes de code (simple, fiable et efficace), on dispose d'un serveur web qui, une fois compilé, pourra être exécuté sans dépendances (pas de node à installer) aussi bien sur Linux que sur Osx ou Windows. Pour quelqu'un venant du Php, je trouve cela « magique ».

Mieux encore, Go est fourni avec un package permettant d'exécuter des tests (nativement) et même un package dédié aux tests http (le package [httptest](http://golang.org/pkg/net/http/httptest/)). La côté fiable du langage est pris au sérieux.

## Go Playground
Peut-être plus anecdotique, on dispose sur le site de Golang d'une interface permettant d'exécuter et de partager du code Go: le [Go Playground](http://play.golang.org). Certes, on trouve l'équivalent pour d'autres technologies sur des sites comme [CodePen](http://codepen.io), mais c'est réjouissant de retrouver ce service pour Go, supporté directement par l'équipe du langage. De plus, contrairement à du javascript, le Go est un langage compilé : la mise en place d'un tel service était certainement moins évidente. Elle est rendue possible entre autres par la vitesse de compilation du langage : c'est vraiment très, très rapide. Lors du développement cette phase que l'on trolle si facilement sur du .NET est presque transparente.

Pour conclure sur le Go Playground, c'est un outil génial pour apprendre, mais également pour faire du code review ou du peer programming à distance.

## Closures et structures de test et de boucle
Sans aborder ici la syntaxe spécifique du Go concernant les structures de test (`if` et `switch`) ou de boucle (`for` uniquement), un point m'a déconcerté lors de l'utilisation de ces structures : toutes les variables déclarées dans un `if` ou un `for` ne sont visibles qu'en leur sein. On est dans une closure.

L'exemple suivant provoque une erreur

``` go
func main() {
    if greeting := sayHello(); len(greeting) > 0 {
        fmt.Println(greeting)
    }
    fmt.Println(greeting)
}

func sayHello() string {
    var say string
    say = "Hello !"

    return say
}
```
[http://play.golang.org/p/adulEdo8VS](http://play.golang.org/p/adulEdo8VS)

Pour que cela fonctionne, il faut faire :

``` go
func main() {
    var greeting string
    if greeting = sayHello(); len(greeting) > 0 {
        fmt.Println(greeting)
    }
    fmt.Println(greeting)
}

func sayHello() string {
    var say string
    say = "Hello !"

    return say
}
```
[http://play.golang.org/p/i0m_Mrc7ca](http://play.golang.org/p/i0m_Mrc7ca)

L'exemple ici est très simple, mais j'ai été confronté à des cas un peu plus compliqués, du moins pour une première découverte du langage.

Par exemple, le code suivant renvoie une erreur:

``` go
type Tag struct {
    Name string
    Sha string
}

type Branch struct {
    Name string
}


func main() {
    testVar := "tag"
    if testVar == "tag" {
        base, err := fetchTag()
    } else {
        base, err := fetchBranch()
    }
    if err != nil {
        fmt.Printf("error : %v\n", err)
    }
    fmt.Println(base.Name)
}

func fetchTag() (Tag, error) {
    tag := Tag{Name: "v1", Sha: "2b55d21f91309cf5ca17bcb827a0ddbd1de81d18"}

    return tag, nil
}
func fetchBranch() (Branch, error) {
    branch := Branch{Name: "master"}

    return branch, nil
}
```
[http://play.golang.org/p/FT32xqpp8t](http://play.golang.org/p/FT32xqpp8t)

Il faut plutôt faire:

``` go
type Tag struct {
    Name string
    Sha string
}

type Branch struct {
    Name string
}


func main() {
    testVar := "tag"
    var name string
    var err error
    if testVar == "tag" {
        tag, errTag := fetchTag()
        name = tag.Name
        err = errTag
    } else {
        branch, errBranch := fetchBranch()
        name = branch.Name
        err = errBranch
    }
    if err != nil {
        fmt.Printf("error : %v\n", err)
    }
    fmt.Println(name)
}

func fetchTag() (Tag, error) {
    tag := Tag{Name: "v1", Sha: "2b55d21f91309cf5ca17bcb827a0ddbd1de81d18"}

    return tag, nil
}
func fetchBranch() (Branch, error) {
    branch := Branch{Name: "master"}

    return branch, nil
}
```
[http://play.golang.org/p/KGNf-KAINg](http://play.golang.org/p/KGNf-KAINg)

Une autre solution consisterait à utiliser les interfaces du Go, très différentes de la notion d'interface d'un langage comme le PHP.

## Persistance avec MongoDb
Le projet sur lequel je travaillais nécessitait du stockage et je me suis vite orienté vers du MongoDb (phase de découverte de techno oblige). Cette fois-ci, pas de package dans la librairie standard, mais un package apparaît très rapidement lors d'une recherche web (et pas 20 packages différents) : [mgo](https://labix.org/mgo).

Imaginons un objet `adress` qu'il faut sauvegarder. Nous allons définir un type `Adress` et complèter la définition de ses différents attributs avec la syntaxe `bson:"nom_mongodb"`. Le `BSON` est le format binaire utilisé par MongoDb pour le stockage du `JSON`.

``` go

type Adress struct {
    Street       string      `bson:"street"`
    PostalCode   string      `bson:"postal_code"`
    City         string      `bson:"city"`
    DoorCode     int         `bson:"-"`
}

```

De cette manière, le package mgo va pouvoir facilement transformer une variable de type `Adress` en objet bson sauvegardable dans MongoDb. Et inversemment, un objet bson requêté depuis MongoDb sera transformé en variable de type `Adress` dans le code Go.
Rapide, simple et efficace.

<div class="tips">

si l'on ne veut pas qu'un attribut soit transformé en bson pour être stocké, il suffit d'indiquer `bson:"-"`.

</div>

## Une bonne documentation, parfois en manque d'exemples
On trouve un utilitaire permettant de générer la documentation d'un package depuis le code : [gocode](https://godoc.org/code.google.com/p/go.tools/cmd/godoc). La documentation peut être affichée sur la console, mais godoc peut également lancer un serveur web pour consulter cette documentation depuis un navigateur.

En règle générale, tous les packages de la librairie standard sont très bien documentés, même s'ils manquent parfois d'exemples pratiques.
Je pense ici au package [time](http://golang.org/pkg/time/), via lequel j'avais besoin de soustraire 2 semaines à une date donnée. On trouve dans la documentation une fonction Add() et une fonction Truncate(), mais pas d'exemples. Et bien pour retirer 2 semaines à une date il faut utiliser Add() avec une `duration` négative.

``` go
func main() {
    now := time.Now()
    fmt.Println(now)
    twoWeeksAgo := now.Add(-2 * 7 * 24 * time.Hour)
    fmt.Println(twoWeeksAgo)
}
```
[http://play.golang.org/p/kkF7G7yLfF](http://play.golang.org/p/kkF7G7yLfF)

Merci [@manuquentin](https://twitter.com/manuquentin), parfois (souvent, toujours) les collègues sont la meilleure documentation du monde.

##Tout ce que je n'ai pas abordé en une semaine
Je suis très loin d'avoir vu toutes les subtilités de Go lors de cette semaine : les tableaux de bits, les runes et les slices me réservent encore beaucoup d'étonnement. Je m'attends à être piègé par des pointeurs hasardeux. Je regrette de n'avoir pas encore utilisé les [Goroutines](http://golang.org/doc/effective_go.html#goroutines) qui constituent paraît-il l'un des atouts du Go. Mais je suis positivement étonné par la rapidité avec laquelle on peut produire du code fiable, rapide, multitâches et  multi-environnements. Au point où je rajouterais bien sur mon pc un sticker de gopher à mon éléphant.