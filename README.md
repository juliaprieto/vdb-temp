# Visualisation de (très) grands arbres: Lifemap

Le cours est disponible en ligne. 

## Objectifs
Ce TP vise à appréhender l'utilisation de Lifemap depuis R, et se familiariser par la même occasion avec l'outil de cartographie leaflet.

* **1. Intro grands arbres : illustration rapide du problème**
* **2. Appréhender Lifemap et les outils de base de Leaflet**
  * Prise en main de leaflet depuis R (charger la carte, mettre un marqueur et un popup associé)
  * Passage à Lifemap (tuiles + données dans Solr)
* **3. Visualiser des données génomiques sur Lifemap**
  * Récupération des données (infos sur génomes eucaryotes séquencés)
  * Varier la taille des marqueurs (nombre de génomes séquencés et/ou assemblés)
  * Varier la couleur des marqueurs (%GC, taille des génomes)
  * La notion de 'groupes'
  * Tracer des lignes
* **4. Aller plus loin dans l'interactivité avec shiny**
  * Exemple d'application cartographique simple avec shiny et leaflet
  * Création d'une application Lifemap pour visualiser les données issues du séquençage 


### 1. Intro grands arbres : illustration rapide du problème
En R, avec le package ape, il est simple de générer de arbres avec la fonction `rtree` et les visualiser rapidement avec la fonction `plot.phylo` ou `plot` .

> **Exo 1** 
> - Installer ape 
> - Générer un arbre de N feuilles (N petit puis N grand)
> - Le visualiser. Observer le problème.

Pour aller plus loin dans la visualisation d'arbres avec R : utiliser le package ggtree. Bonne présentation par l'auteur des fonctionnalitées ici : https://guangchuangyu.github.io/presentation/2016-ggtree-chinar/. 


### 2. Appréhender Lifemap et les outils de base de Leaflet
#### Prise en main de leaflet depuis R (charger la carte, mettre un marqueur et un popup associé)

Les tuiles formant le fond de carte de Lifemap sont accessibles comme celles formant les cartes osm ou google maps.

Afficher ces tuiles, zoomer, paner, dans un navigateur, se fait via des librairies javascript. Une des plus utilisées est [leaflet](https://leafletjs.com/). Suivre le lien pour voir l'étendue des possibilités.

Leaflet est utilisable depuis R  grâce au package `leaflet` (https://rstudio.github.io/leaflet/). Intégration possible avec shiny pour créer des applis plus complètes (voir la fin du TP).
Le code ci-dessous permet de charger un fond de carte osm avec leaflet, et d'ajouter un marqueur au niveau de la ville de Lyon. 
```r
require("leaflet")
m<-leaflet()
m<-addTiles(m)
m<-addMarkers(m, lng=4.85, lat=45.75, label="Ici Lyon")
```

> **Exo 2** 
> - Installer Leaflet pour R
> - Exécuter le code précédent, mais en mentionnant explicitement la source des tuiles : https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
> - Ajouter (en plus de lyon) un marqueur sur la ville de Paris (longitude = 48.85, latitude = 2.35) et visualiser à nouveau la carte. Qu'observe-t-on ?
> - Écrire une fonction permettant de 'recharger' une carte vierge (utile pour la suite du TP).

La fonction `leaflet()`peut aussi prendre en entrée des données avec `leaflet(data=...)`, sous forme de data.frame ou autre. Il est ensuite possible de faire référence aux éléments présents dans le data frame depuis les fonctions `addMarkers()`, `addCircles()`, `addCircleMarkers()`, etc. en ne mentionnant que le nom de la colonne d'intérêt précédé du tilde (`~lat` pour latitude par exemple). 

> **Exo 3**
> - Créer une data.frame avec les noms "Lyon" et "Paris" dans la première colonne, leur longitude dans la seconde et leur latitude dans la troisième.
> - Visualiser les marqueurs pour ces deux villes en donnant ce data.frame en entrée à la fonction `leaflet()`
> - Modifier la fonction permettant de recharger une carte nouvelle pour permettre de prendre un data frame en entrée.

#### Passage à Lifemap (tuiles + données dans Solr)
Les tuiles de Lifemap ont pour url http://lifemap-ncbi.univ-lyon1.fr/osm_tiles/{z}/{x}/{y}.png. 

Les données additionnelles de Lifemap sont stockées dans deux 'coeurs' [Solr](https://lucene.apache.org/solr/). On y trouve les coordonnées de toutes les espèces et de tous les clades (un clade = un groupe monophylétique), ainsi que les noms latins, les synonymes, le nombre de descendants, leurs ascendants, etc. Aller voir directement sur http://lifemap-ncbi.univ-lyon1.fr:8983/solr/#/ pour mieux comprendre. 

Au NCBI, et donc dans Lifemap, les espèces et les clades sont identifiés par un identifiant unique appelé **taxid**. 

Une requête des taxid 2, 9443 et 2087 sur le "coeur" `taxo` (qui contient les données taxonomiques) se fait par l'url : http://lifemap-ncbi.univ-lyon1.fr:8983/solr/taxo/select?q=taxid:(2%209443%202087)&wt=json&rows=1000. Notons que le `%20` remplace l'espace.

> **Exo 4**
> - Visualiser Lifemap en lieu et place de la carte osm précédente et modifier la fonction qui crée une nouvelle carte vierge en conséquence.
> - Écrire une fonction pour récupérer les coordonnées des espèces (à partir d'un vecteur de **taxid**) en utilisant la fonction `fromJSON()` du package `jsonlite` (à installer) <sup>[Aller plus loin](#aller-plus-loin)</sup>
> - Récupérer les coordonnées des trois taxids de l'exemple et les représenter dans Lifemap sous forme forme de ronds (fonction `addCircleMarkers()`).
> - Jouer avec l'opacité, la présence de bordure, la couleur, la taille, etc. Taper `?addCircleMarker()` dans R pour avoir de l'aide.
> - [rigolo] : n'importe quelle image peut servir d'icône de marqueur. On peut par exemple mettre une [silhouette de cheval](https://svgsilh.com/png-512/156496-cddc39.png) à *Equus caballus* (taxid : 9796). Essayez si vous avez le temps (explication détaillée [ici](https://rstudio.github.io/leaflet/markers.html)).

### 3. Visualiser des données génomiques sur Lifemap
Le but est de récupérer des données génomiques que nous pouvons associer aux espèces de l'arbre de la vie et visualiser sur Lifemap. 
Nous nous intéressons ici :
- aux données de séquençage de génomes: quantité, représentativité, qualité
- aux données génomiques à proprement parler: nombre de chromosomes, nombre de gènes annotés, taux de GC dans les génomes

Les données seront récupérées directement sur le ftp du NCBI avec la fonction `read.table()`. Nous nous intéresserons aux données, eucaryotes, moins volumineuses (moins de génomes séquencés que chez les bactéries). Le fichier à récupérer est disponible à l'url suivante : ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/eukaryotes.txt. L'explication des champs présents dans ce fichier est la suivante :

|Column|Description|
|---|---|
| #Organism/Name | Organism name at the species level   |
| BioProject | BioProject Accession number (from BioProject database) |
|Group |         Commonly used organism groups:  Animals, Fungi, Plants, Protists;|
|SubGroup|       NCBI Taxonomy level below group: Mammals, Birds, Fishes, Flatworms, Insects, Amphibians, Reptiles, Roundworms, Ascomycetes, Basidiomycetes, Land Plants, Green Algae, Apicomplexans, Kinetoplasts;|
|Size (Mb)     | Total length of DNA submitted for the project |
|GC%     |       Percent of nitrogenous bases (guanine or cytosine) in DNA submitted for the project|
|Assembly      | Name of the genome assembly (from NCBI Assembly database)|
|Chromosomes  |  Number of chromosomes submitted for the project       |
|Organelles  |   Number of organelles submitted for the project |
|Plasmids     |  Number of plasmids submitted for the project |
|WGS          |  Four-letter Accession prefix followed by version as defined in WGS division of GenBank/INSDC|
|Scaffolds |     Number of scaffolds in the assembly|
|Genes      |    Number of Genes annotated in the assembly|
|Proteins    |   Number of Proteins annotated in the assembly | 
|Release Date |  First public sequence release for the project|
|Modify Date  |  Sequence modification date for the project|
|Status   |      Highest level of assembly: <br> Chromosomes: one or more chromosomes are assembled<br> Scaffolds or contigs: sequence assembled but no chromosomes <br>SRA or Traces: raw sequence data available<br> No data: no data is connected to the BioProject ID

*Attention: le nom des colonnes change après l'import dans R !*

#### Préparation des données

> **~~Exo 5~~**
> - Récupérer les données sur le ftp du NCBI. 
  Attention avec la fonction `read.table()` : les séparateurs de champs sont des tabulations (utiliser `sep="\t"`), il y a un header (utiliser `header=TRUE`), les apostrophes ne doivent pas être considéré comme des guillemets contrairement aux vrais guillemets (`"`) (utiliser `quote="\""`) et la ligne commençant par un `#` ne devrait pas être traitée comme une ligne de commentaires puisque c'est celle qui contient le nom des colonnes (utiliser `comment.char=""`).  Note : il est possible d'utiliser l'url du fichier directement dans la fonction `read.table()` sans avoir à télécharger le fichier sur le disque préalablement.
> - créer un data.frame contenant pour chaque taxid existant dans le fichier récupéré au NCBI : 
>    - les coordonnées lat/lon
>    - le nom latin
>    - le nombre total de génomes séquencés (fonction `table()`)
>    - le nombre de ces génomes entièrement assemblés (`Status == "Chromosome"`)
>    - le taux de GC **moyen**
>    - la taille **moyenne** des génomes en Mb

```r
##RÉCUPÉRER LES DONNÉES
EukGenomeInfo<-read.table("ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/eukaryotes.txt", sep="\t", header=T, quote="\"", comment.char="")
## liste unique des taxid
taxids<-unique(EukGenomeInfo$TaxID)

## RÉCUPÉRER LES COORDONNÉES
DF<-GetCooFromTaxID(taxids)

## CALCULER LE NOMBRE DE GÉNOMES SÉQUENCÉS POUR CHAQUE TAXID
nbGenomeSequenced<-table(EukGenomeInfo$TaxID)
## l'ajouter à DF
DF$nbGenomeSequenced<-as.numeric(nbGenomeSequenced[DF$taxid])

##CALCULER LE NB DE GENOMES ENTIEREMENT ASSEMBLES POUR CHAQUE TAXID
##le calcul pour un seul taxid nommé 'tid' serait :
sum(EukGenomeInfo[which(EukGenomeInfo$TaxID=='tid'),]$Status=="Chromosome")
##on peut utiliser la fonction sapply pour le faire pour chaque taxid 
nbGenomeAssembled<-sapply(DF$taxid, function(x,tab) sum(tab[which(tab$TaxID==x),]$Status=="Chromosome"), tab=EukGenomeInfo)
DF$nbGenomeAssembled<-nbGenomeAssembled

##CALCULER LE TAUX de GC MOYEN  
tauxgcmoyen<-sapply(DF$taxid, function(x,tab) mean(as.numeric(as.character(tab[which(tab$TaxID==x),]$GC.)), na.rm=TRUE), tab=EukGenomeInfo)
DF$tauxgcmoyen<-tauxgcmoyen

##CALCULER LA TAILLE MOYENNE DES GÉNOMES EN Mb
SizeGenomeMb<-sapply(DF$taxid, function(x,tab) mean(tab[which(tab$TaxID==x),]$Size..Mb., na.rm=TRUE), tab=EukGenomeInfo)
DF$SizeGenomeMb<-SizeGenomeMb 
```

#### Varier la taille des marqueurs

> **Exo 6**
>  - visualiser *successivement* sous forme de cercles de taille proportionnelle (fonction `addCircleMarkers()`)
>    - le nombre total de génomes séquencés
>    - le nombre de ces génomes entièrement assemblés
>    - la **proportion** des génomes séquencés qui sont entièrement assemblés
> Trouver à chaque fois la meilleure transformation des données pour rendre le résultat le plus lisible. 

#### Varier la couleur des marqueurs
Il est possible, au lieu (ou en plus) d'utiliser la taille des marqueurs, d'utiliser leur couleur pour représenter les données d'intérêt. De nombreuses façon d'associer des données discrètes ou continues à des couleurs existent en R. Nous utiliserons les fonctions et les approches décrites ici : https://rstudio.github.io/leaflet/colors.html
En substance : 
la fonction `colorNumeric()` du package `leaflet` prend en entrée une palette de couleurs et un ensemble de valeurs. Elle renvoie une fonction qui lorsqu'elle est appelée avec une ou plusieurs valeurs en arguments, renvoie une/des couleurs.
Certains packages R proposent des palettes de couleur utilisables avec cette fonction. Par exemple `RColorBrewer` ou `viridis`. Il faudra les installer avant.
```r
##charger un package contenant des palettes de couleur
library(RColorBrewer) #ou "viridis" qui contient de bonnes couleurs aussi
## créer la fonction de palette
pal<-colorNumeric("Greens",0:100) ##green est une des palettes de RColorBrewer. Taper 
                 ## display.brewer.all() pour les voir toutes
## tester la palette
pal(12) # "#00FF00"
pal(c(12,1,24)) # "#00FF00" "#00FF00" "#00FF00"
pal(101) #impossible ! car 101 est en dehors de l'intervalle possible. 
```
> **Exo 7**
>  - visualiser *successivement* sous forme de cercles de couleurs différentes 
>    - le taux de GC moyen 
>    - la taille moyenne des génomes séquencés en Mb. 
>    - La couleur est elle une bonne façon de représenter cette dernière variable. Pourquoi ? Que suggérez vous ?   
>    - Pensez à ajoutez une légende à chaque fois (fonction `addLegend()`)


#### La notion de 'groupes'
Il est possible d'associer les marqueurs à des groupes puis de décider d'afficher tel ou tel groupe de façon sélective. Il suffit
- d'ajouter `group="groupname"` aux arguments des fonctions `addCircleMarkers()` et éventuellement `addLegend()` (si les différents groupes ont différentes légendes.
> **Exo 8**
>  - Créez des marqueurs distincts pour le taux de GC des Fungi, Animals, Plants, Protists et Others (nécessite de mettre à jour le data.frame servant en entrée (code ci-dessous).
>  - Utilisez ensuite la fonction `addLayersControl()` pour permettre à l'utilisateur de la carte de choisir pour quel(s) groupe(s) d'espèces il souhaite voir la donnée. 
```r
##ajouter une colonne à DF avec le Group:
TaxID.et.Group<-EukGenomeInfo[!duplicated(EukGenomeInfo$TaxID),c("TaxID","Group")]
groups<-as.character(TaxID.et.Group[,2])
names(groups)<-TaxID.et.Group[,1]
DF$Group<-groups[DF$taxid]
```
#### Tracer des lignes (polyLines)
Le code ci-dessous permet de récupérer la liste des taxids ascendants (jusqu'à LUCA) pour un taxid donné. 

```r
library("jsonlite")
GetAscendFromTaxID<-function(taxids) {
  ##taxids is an array that contains taxids.
  ## url cannot be too long, so that we need to cut the taxids (100 max in one chunk)
  ## and make as many requests as necessary.
  taxids<-as.character(taxids) #change to characters.
  DATA<-NULL
  i<-1
  while(i<=length(taxids)) {
    cat(".")
    taxids_sub<-taxids[i:(i+99)]
    taxids_sub<-taxids_sub[!is.na(taxids_sub)]
    taxids_sub<-paste(taxids_sub, collapse="%20") #accepted space separator in url
    url<-paste("http://lifemap-ncbi.univ-lyon1.fr:8080/solr/addi/select?q=taxid:(",taxids_sub,")&wt=json&rows=1000",sep="", collapse="")
    #do the request :
    data_sub<-fromJSON(url)
    ##ajouter le taxid quary à la liste
    res<-sapply(1:length(data_sub$response$docs$ascend), function(x,y,z) c(y[[x]],z[[x]]), y=data_sub$response$docs$taxid, z=data_sub$response$docs$ascend)
    DATA<-c(DATA,res)
    i<-i+100
  } 
  if (!is.list(DATA)) DATA<-list(DATA) ##si un seul taxid demandé
  return(DATA)
}
```
> **Exo 9**
> - Récupérer les "chemins" allant de *Microbotryium violaceum* (taxid=5272) et *Homo sapiens* (taxid=9606) à la racine de l'arbre du vivant.
> - Récupérer les coordonnées des taxids formant ces chemins
> - tracer les deux chemins et identifier ainsi le MRCA* de ces deux espèces. 
> - Ajouter un nouveau marqueur au niveau de ce MRCA
>
>*MRCA = Most Recent Common Ancestor


### 4. Aller plus loin dans l'interactivité avec shiny 
On voit dans l'exemple précédent que rendre la carte interactive (au delà du zoom) est très limité si l'on se cantonne à l'utilisation du package `leaflet`. La fonction `addLayersControl()` peut être oubliée si l'on passe à l'utilisation de **Shiny**, qui vous a été présenté dans une séance antérieure. Un tutoriel peut aussi être trouvé ici : https://shiny.rstudio.com/tutorial/

#### Exemple d'application cartographique simple avec shiny et leaflet

Le code ci-dessous (modifié depuis https://rstudio.github.io/leaflet/shiny.html) permet de créer une application web pour visualiser les données de 1000 éruptions volcaniques survenues dans les îles Fidgi depuis 1964, avec leur localisation, leur intensité, leur profondeur. Différents types de boutons permettent de filtrer ce qui est affiché sur la carte. 
Notez l'utilisation de la fonction `leafletProxy()` qui peut remplacer la fonction `leaflet()` si on ne souhaite pas recharger l'ensemble de la carte et des couches quand seulement quelques modifications ou filtres sont appliqués à certaines couches.  

Notez l'utilisation des fonctions `reactive()` et `observe()`. La différence entre les deux est ténue mais on peut simplifier ainsi : 
- la fonction `reactive()` surveille si des données en entrée changent, et renvoie une nouvelle valeur, qui sera utilisée par une fonction à l'extérieur (généralement une fonction `observe`. 
- la fonction `observe()` ne renvoie pas de données en dehors. Elle surveille simplement si les données à l'intérieur changent et agit en conséquence (ici pour updater les layers). 

```r
library(shiny)
library(leaflet)
library(viridis)
library(RColorBrewer)

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
    sliderInput("range", "Magnitudes", min(quakes$mag), max(quakes$mag),
      value = range(quakes$mag), step = 0.1
      ),
    selectInput("depth", "Depth of earthquakes (km)",c("all","<200","200-500",">500"))
    )
  )

server <- function(input, output, session) {
##set palette function
  pal<-colorNumeric("magma", quakes$mag)
  # Reactive expression for the data subsetted to what the user selected
  filteredData <- reactive({
    k<-quakes[quakes$mag >= input$range[1] & quakes$mag <= input$range[2],]
    if (input$depth!='all') {
      if (input$depth=="<200") k<-k[k$depth<200,]
      if (input$depth=="200-500") k<-k[k$depth>=200&k$depth<=500,]
      if (input$depth==">500") k<-k[k$depth>500,]
    }
    k
  })

  output$map <- renderLeaflet({
  # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    m<-leaflet(quakes)
    m<-addTiles(m)
    m<-fitBounds(m, ~min(long), ~min(lat), ~max(long), ~max(lat))
    m<-addLegend(m, position = "bottomright", pal = pal, values = ~mag)
  })
  # Incremental changes to the map (in this case, replacing the
  # circles when a new color is chosen) should be performed in
  # an observer. Each independent set of things that can change
  # should be managed in its own observer.
  observe({
    proxy<-leafletProxy("map", data = filteredData())
    proxy<-clearShapes(proxy)
    proxy<-addCircles(proxy, radius = ~10^mag/10, weight = 1, color = "#777777", fillColor = ~pal(mag), fillOpacity = 0.7, popup = ~paste(mag))
  })
}

shinyApp(ui, server)
```
#### Création d'une application Lifemap pour visualiser les données issues du séquençage 

> **Exo 10**
> En vous inspirant de ce code, et en vous reposant sur ce que vous avez vu dans les exercices et dans les séances précédentes, vous allez créer une une application Shiny fonctionnelle permettant de visualiser les données vues plus haut, de façon interactive. Plus spécifiquement, l'application permettra : 
> - de visualiser (selectInput) dans un premier bloc : 
>   - le nombre de génomes séquencés
> - de visualiser (selectInput) dans un second bloc : 
>   - le taux de GC des génomes
>   - leur taille en Mb
>  - de filtrer
>    - par Groupe (Fungi, Animals, Plants, Protists)
>    - par qualité d'assemblage 
>    - par date (année) de séquençage (avec un slider) -> observation de l'explosion des projets de séquençage.
>
> Ne pas oublier les légendes.
> [aller plus loin](#aller-plus-loin)  
> 

___
##### Aller plus loin
- Exo 4 : Si vous avez le temps, créez aussi une fonction permettant de récupérer les coordonnées à partir du nom latin et pas du taxid. En tolérant éventuellement les fautes de frappe, etc. (solr permet cela !!)
- Exo 9 : Les possibilités d'amélioration sont infinies : ajouter la visualisation du nombre de chromosomes des génomes séquencés ; visualiser les mêmes informations pour les génomes bactériens et archéens ; Imaginer comment insérer une barre de recherche pour localiser les espèces par leur nom ; Créer un système permettant de localiser dans l'arbre où se trouve une espèce que l'on ne connaît que par sa séquence (placement phylogénétique). 
