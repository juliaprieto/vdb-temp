library(ape)
library(leaflet)
library(ggtree)
library(jsonlite)
#Ex 1 faire des arbres

tr<- rtree(20)
plot(tr)
# On observe problème de superposition des tags pour ++ feuilles


#Ex 2 : Découvre Leaflet
# require("leaflet")
m<-leaflet()
m<-addTiles(m)
m<-addMarkers(m, lng=4.85, lat=45.75, label="Ici Lyon")
m<-addMarkers(m, lng=2.35, lat=48.85, label="Ici Paris")


renew_map <- function(df){
  m<-leaflet(df)
  m<-addTiles(m,url="http://lifemap-ncbi.univ-lyon1.fr/osm_tiles/{z}/{x}/{y}.png", options=tileOptions(maxZoom=42))
  return(m)
}



# Ex 3

df <- data.frame(Ville=c("Paris","Lyon"), lat=c(0,4.85),lng=c(0,4.85))
m<-renew_map(df)
m<-addMarkers(m,lng=~lng, lat=~lat)
m

# Exercice 4 

GetCooFromTaxID<-function(taxids) {
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
    url<-paste("http://lifemap-ncbi.univ-lyon1.fr:8080/solr/taxo/select?q=taxid:(",taxids_sub,")&wt=json&rows=1000",sep="", collapse="")
    #do the request :
    data_sub<-fromJSON(url)
    DATA<-rbind(DATA,data_sub$response$docs[,c("taxid","lon","lat", "sci_name","zoom","nbdesc")])
    i<-i+100
  } 
  for (j in 1:ncol(DATA)) DATA[,j]<-unlist(DATA[,j])
  class(DATA$taxid)<-"character"
  return(DATA)
}



##test de la fonction
data<-GetCooFromTaxID(c(2,9443,2087))
data

# Ex 5

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
pal<- colorNumeric("Spectral",DF$tauxgcmoyen)
m<-renew_map(DF)
m<- addCircleMarkers(m, lat=~lat,lng=~lon, label=~sci_name, color=~pal(tauxgcmoyen), stroke = FALSE, fillOpacity = .4)
# m<- addCircleMarkers(m, lat=~lat,lng=~lon,radius =~sqrt(SizeGenomeMb)/10, label=~sci_name, color ="#FC8160" , stroke = FALSE, fillOpacity = .2)
m<-addLegend(m,position="bottomright", values=~tauxgcmoyen, pal=pal)
m

library(RColorBrewer)
pal<- colorNumeric("Reds",0:100)

pal(43)
