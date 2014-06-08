function ls_archive {
#$1 est l'archive dans laquel on travail

#on initialise l'affichage de ls à " " pour eviter d'accumuler les valeurs précédantes
affichage_ls=" "

#trouve le numéro de la ligne correspondant au chemin indiqué
numero_ligne=$(grep -n '^directory.*\'"$position_theo"'$' archives/"$1" | cut -f1 -d ':')

#on se place à la ligne suivante ou il y a le nom du premier fichier
((numero_ligne= $numero_ligne + 1))

#ligne1 prend la valeur de la ligne (ex toto dwrx-rx--x 4965 25 7)
ligne1=$(sed -n "$numero_ligne"p archives/"$1")

# tant que la ligne est != de @ on lit les lignes suivantes
while [ "$ligne1" != "@" ]
do 
	# on stock le nom du fichier/dossier dans une variable
	fichier_ou_dossier=$(echo $ligne1 | cut -f1 -d ' ')
	
	#si la premières lettre suivant le nom du fichier/dossier est un d alors
	if [ "$(echo $ligne1 | cut -f2 -d ' ' | sed 's/^\([d-]\).*$/\1/g')" = "d" ]
	then
		# c'est un dossier donc on met un / devant le nom
		affichage_ls="$affichage_ls   /$fichier_ou_dossier"
	else 
		# c'est un fichier donc on ne met rient devant le nom
		affichage_ls="$affichage_ls   $fichier_ou_dossier"
	fi #affichage_ls s'agrndi au fure et à mesure avec les noms des fichier/dossier

	((numero_ligne=$numero_ligne + 1))
	ligne1=$(sed -n "$numero_ligne"p archives/"$1")
done	
echo $affichage_ls
}
