#________________________FONCTION CAT__________________________________

function cat_archive {
#-------vérification que le fichier existe--------------------------------------

#on trouve le numéro de la ligne correspondant au chemin de l'utilisateur
numero_ligne=$(grep -n '^directory .*'"$position_theo"'$' $archive | cut -f1 -d ':' ) 

ligne=$(sed -n $(($numero_ligne+1))p $archive)
test_fichier_existe=non
while [ "$ligne" != "@" ] 
do	
	#si le fichier est écrit au début de la ligne et que ce n'est pas un dossier alors le test est concluant, le fichier existe 
	if [ "$fichier" = "$(echo $ligne | sed -n '/^'"$fichier"'/p' | cut -f1 -d ' ')" -a "d" != "$(echo $ligne | sed 's/^[^ ]* \(.\).*/\1/g')"  ]
	then
		test_fichier_existe=oui	
	fi
	numero_ligne=$(($numero_ligne+1))
	ligne=$(sed -n "$numero_ligne"p $archive)
done

#----------fin de la vérification de l'existance du fichier--------------------------



#si le fichier à été trouver dans le dossier indiqué par l'utilisateur alors on applique la commande cat
if [ "$test_fichier_existe" = "oui" ]
then
	# $1 est l'archive dans laquel on travail
	debut_body=$(head -1 $archive | cut -f2 -d ':')
	debut_fichier=$(($debut_body + $(sed -n '/^'"$fichier"' .*/p' $archive | cut -f4 -d ' ') -1))
	fin_fichier=$(($debut_fichier + $(sed -n '/^'"$fichier"'.*/p' $archive | cut -f5 -d ' ') -1))


	ligne=$(sed -n "$debut_fichier"p $archive)

	# tant que le numero de la ligne n'est pas le numéro de la ligne de fin du fichier on continue
	while [ $debut_fichier -le $fin_fichier ]
	do 
		echo $ligne  
		#on augmente le numéro de la ligne de 1
		debut_fichier=$(($debut_fichier +1))
	
		ligne=$(sed -n "$debut_fichier"p $archive)
	done
else 
	echo "le fichier $fichier n'existe pas pour le dossier $position"
fi
}


#__________________________FONCTION LS_____________________________________________

function ls_archive {
#$1 est l'archive dans laquel on travail

#on initialise l'affichage de ls à " " pour eviter d'accumuler les valeurs précédantes
affichage_ls=" "

#trouve le numéro de la ligne correspondant au chemin indiqué
numero_ligne=$(grep -n '^directory.*\'"$position_theo"'$' $archive | cut -f1 -d ':')

#on se place à la ligne suivante ou il y a le nom du premier fichier
((numero_ligne= $numero_ligne + 1))

#ligne1 prend la valeur de la ligne (ex toto dwrx-rx--x 4965 25 7)
ligne=$(sed -n "$numero_ligne"p $archive)

# tant que la ligne est != de @ on lit les lignes suivantes
while [ "$ligne" != "@" ]
do 
	# on stock le nom du fichier/dossier dans une variable
	fichier_ou_dossier=$(echo $ligne | cut -f1 -d ' ')
	#si la premières lettre suivant le nom du fichier/dossier est un d alors
	if [ "$(echo $ligne | cut -f2 -d ' ' | sed 's/^\([d-]\).*$/\1/g')" = "d" ]
	then
		# c'est un dossier donc on met un / devant le nom
		affichage_ls="$affichage_ls   /$fichier_ou_dossier"
	else 
		# c'est un fichier donc on ne met rient devant le nom
		affichage_ls="$affichage_ls   $fichier_ou_dossier"
	fi 
	#affichage_ls s'agrandi au fur et à mesure avec les noms des fichiers ou dossiers

	((numero_ligne=$numero_ligne + 1))
	ligne=$(sed -n "$numero_ligne"p $archive)
done	
echo $affichage_ls
}

#_________________________________FONCTION CD____________________________________________

function cd_archive {
# on actualise la véritable position
position=$position_theo
}

#_______________________________FONCTION VERIFICATION DU CHEMIN________________________

function verif_chemin {
# $1 = nom de la fonction a executer si le chemin est valide

# extrait le premier mot du chemin ex : pour /A/A1 cela renvoie A
premier=$(echo $chemin | sed 's/^\/\?\([^/]*\).*/\1/g')

# si le premier mot est ".." alors
if [ "$premier" = "$(echo $premier | sed -n '/^\.\.$/p')" ]
then
	# si position_theo différent de / alors on peut appliquer le ..
        if [ "$position_theo" != "/" ]
        then
		# si position_theo contient un seul "/" ex : "/A" ou "/B" ("/A/A1" ne marche pas)
		if [ "$position_theo" = "$(echo $position_theo | sed -n '/^\/[^/]\+$/p')" ]
		then	
			# "/A" devient "/"
			position_theo=/
		else
	        	# enleve le dernier mot de position_theo ex : "/A/A1" devient "/A"
                	position_theo=$(echo $position_theo | sed 's/^\(\/.*\)\/.\+$/\1/g')  
        	fi
	fi
	
        # on enleve le premier mot de chemin ex : "/A/A1" devient "/A1"
        chemin=$(echo $chemin | sed 's/^\/\?[^/]\+\(.*\)/\1/g')

        # si le chemin n'est pas terminé alors on relance la fonction
        if [ "$chemin" != "/" -a -n "$chemin" ]
        then	
		# on relance la fonction 
		verif_chemin $1
        else	
		# on appelle la fonction a laquel s'applique le chemin qui est validé 
		if [ "$1" = "cd" ]
		then 
			cd_archive	
		elif [ "$1" = "ls" ]
		then
			ls_archive
		elif [ "$1" = "cat" ]
		then
			cat_archive
                fi
        fi

#si le premier mot est "." alors la position theorique ne change pas
elif [ "$premier" = "$(echo $premier | sed -n '/\.$/p')" ]
then

	# on enleve le premier mot de chemin
	chemin=$(echo $chemin | sed 's/^\/\?[^/]\+\(.*\)/\1/g')

	# si le chemin n'est pas terminé alors on relance la fonction
	if [ "$chemin" != "/" -a -n "$chemin" ]
	then
	        verif_chemin $1 
	else
		# on appelle la fonction a laquel s'applique le chemin qui est validé 
                if [ "$1" = "cd" ]
                then 
                         cd_archive      
                elif [ "$1" = "ls" ]
		then
			ls_archive  
		elif [ "$1" = "cat" ]
		then
			cat_archive 
                fi

	fi

#si le premier mot est autre chose que ".." ou "." alors c'est du texte à chercher dans l'archive
else
	#dans cette boucle on recherche le chemin formé par position_théo et le premier mot du chemin de l'utilisateur
        if [ "$position_theo" = "/" ]
        then
		 recherche_archive=$(sed -n '/^directory .*\'"$position_theo"''"$premier"'$/p' $archive)
        else
                 recherche_archive=$(sed -n '/^directory .*\'"$position_theo"'\/'"$premier"'$/p' $archive)
        fi
	
	#si on a trouvé le chemin exite dans l'archive alors
        if [ -n "$recherche_archive" ]
        then
		#on ajoute premier à la fin de position_theo pour former le chemin actuel
        	if [ "$position_theo" = "/" ]
	        then
	                position_theo=$position_theo$premier
                else
                        position_theo=$position_theo/$premier
                fi
 	
		#on eleve le premier mot du chemin
                chemin=$(echo $chemin | sed 's/^\/\?[^/]\+\(.*\)/\1/g')

                # si le chemin n'est pas terminé alors on relance
                if [ "$chemin" != "/" -a -n "$chemin" ]
		then
			verif_chemin $1 
                else
			# on appelle la fonction a laquel s'applique le chemin qui est validé 
                       	if [ "$1" = "cd" ]
                      	then 
				cd_archive      
			elif [ "$1" = "ls" ]
			then
				ls_archive 
			elif [ "$1" = "cat" ]
			then
				cat_archive 
                       	fi

                fi

	#le chemin n'existe pas dans l'archive
	else 
		echo "chemin non valide"	
	
	fi
fi
}

#________________________FONCTION VERIFICATION ARCHIVE____________________________

function verif_archive {
# si le nom d'archive donné existe dans le répertoir des archives on continue
test_archive_existe=non
if [ "$nom_archive" = "$(ls $position_archives | sed -n '/^'"$nom_archive"'$'/p)" ]	
then
	# si le premier mot du header est directory alors c'est une archive
	debut_header1=$(head -1 "$archive" | cut -f1 -d ':')
	#on vérifie qu'on obtient bien un nombre
       	if [ "$debut_header1" = "$(echo $debut_header1 | sed -n '/^[0-9]\+$/p')" ] 
	then
		if [ "directory" = "$(sed -n "$debut_header1"p "$archive" | cut -f1 -d ' ')" ]
       		then
			test_archive_existe=oui
		fi
	else
		echo "$nom_archive n'est pas une archive"
	fi
else
	echo "$nom_archive n'existe pas"
fi
}


#________________________PARTIE LIST/BROWSE/EXTRACT________________________________



while read option #while facultatif un read aurait suffit
do

#indique le chemin ou se trouve toutes les archives du serveur
position_archives=archives


# ----------------------PARTIE LIST--------------------------------------
if [ "$option" = "list" ] 
then
	#on parcourt tous les fichier localiser à l'endroit ou sont les archives
	for i in $(ls $position_archives) 
	do
		# on récupère la ligne ou commence le header
		debut_header=$(head -1 "$position_archives/$i" | cut -f1 -d ':')
		# si ce qu'on vient de récupérer est bien un nombre on continue
		if [ "$debut_header" = "$(echo $debut_header | sed -n '/^[0-9]\+$/p')" ]
		then  
			# si la ligne numéro "début_header" commence par le mot directory alors on suppose que l'on est bien en présence d'une archive
			if [ "directory" = "$(sed -n "$debut_header"p "$position_archives/$i" | cut -f1 -d ' ')" ]		
			then 
				# on affiche l'archive
				echo "$i"
			fi
		fi
	done




#--------------------------PARTIE BROWSE-------------------------------
elif [ "$option" = "browse" ]
then	
	read nom_archive
	#archive contient le chemin et le nom de l'archive choisie par l'utilisateur
	archive=$position_archives/$nom_archive

	#on test si l'archive existe
	verif_archive

	if [ "$test_archive_existe" = "oui" ]	
	then
	#L'ARCHIVE EST VALIDE

		#la position actuelle avant toute action de l'utilisateur est /
		position=/
		commande=ok			
		while [ "$commande" != "exit" ] #while facultatif puisque géré aussi du coté client
		do	
			#echo "vsh:>"
			read commande

			#on place la position théorique au même endroit que la position réel
			position_theo=$position
				
			# extrait la première partie de commande dans le cas ou il y a une option après ex : pour cd /A/A1 on ne prend que le cd 
			commande1=`echo $commande | cut -f1 -d ' '`  




#------------- PARTIE lancement CD 
		if [ "$commande1" = "cd" ]
		then
			# on récupère la deuxième partie de la commande donc le chemin pour un cd 
			chemin=$(echo $commande | cut -f2 -d ' ')
			
			# si il n'y a rien d'érit après le cd (pas de chemin) chemin aura pris la valeur cd et non pas " " 
			if [ "$chemin" != "cd" ]
			then 	
				# si le chemin commence par /.. 
				if [ "$chemin" = "$(echo $chemin | sed -n '/^\/\.\..*/p')" ]
				then
					echo "chemin non valide"
				# si le chemin est egual à / alors
				elif [ "$chemin" = "$(echo $chemin | sed -n '/^\/$/p')" ]
				then 
					position=/
				# sinon on lance le fonction de vérification du chemin
				else 	
					# si le chemin commence par un /
					if [ "$(echo $chemin | sed 's/^\(.\).*$/\1/g')" = "/" ]
					then 
						#c'est un chemin absolue et pour ne pas avoir de problème de concaténation dans la focntion verif_chemin on met position theo à /
						position_theo=/
					fi
					# on lance la vérification du chemin
					verif_chemin cd 
				fi
			fi  
#--------------------Partie lancement LS
		elif [ "$commande1" = "ls" ]
                then
			#on recupère le chemin placé après le ls
			chemin=$(echo $commande | cut -f2 -d ' ')
			#si le chemin existe alors
                        if [ "$chemin" != "ls" ]
                        then	
				#si le chemin commence par "/.." alors
                                if [ "$chemin" = "$(echo $chemin | sed -n '/^\/\.\..*/p')" ]
                                then
	                                echo "chemin non valide"
				# ou si le chemin est juste "/" alors
                                elif [ "$chemin" = "$(echo $chemin | sed -n '/^\/$/p')" ]
                                then 
                                        position_theo="/"
					# on lance directement ls car "/" est un chemin valide
                                        ls_archive 
 
                                else 
					#si le premier caractère est "/"
					if [ "$(echo $chemin | sed 's/^\(.\).*$/\1/g')" = "/" ]
					then 
						#c'est un chemin absolue
						position_theo=/
					else 
						position_theo=$position
					fi
                                        verif_chemin ls
                                fi
			else
				#cas du "ls" sans chemin après
				position_theo=$position
				ls_archive 
                        fi


#----------------------Partie lancement CAT
		elif [ "$commande1" = "cat" ]
                then
			chemin=$(echo $commande | cut -f2 -d ' ')
                        if [ "$chemin" != "cat" ]
                        then	
				#si il y a un / dans le chemin
				if [ "$chemin" = "$(echo $chemin | sed -n '/\//p')" ] 
				then
					#récupere le dernier mot du chemin qui doit etre le fichier
					fichier=$(echo $chemin | sed 's/.*\/\([^/]*\)$/\1/g')
					#on récupere le chemin placé avant le fichier
					chemin=$(echo $chemin | sed 's/\(.*\)\/[^/]*$/\1/g')

					#si le chemin commence par "/.." alors
                                	if [ "$chemin" = "$(echo $chemin | sed -n '/^\/\.\..*/p')" ]
                                	then
	                                	echo "chemin non valide"
					# ou si le chemin est juste "/" alors
                                	elif [ "$chemin" = "$(echo $chemin | sed -n '/^\/$/p')" ]
                                	then 
                                        	position_theo="/"
						# on lance directement ls car "/" est un chemin valide
                                        	cat_archive 
 
                                	else 
						#si le premier caractère est "/"
						if [ "$(echo $chemin | sed 's/^\(.\).*$/\1/g')" = "/" ]
						then 
							#c'est un chemin absolue
							position_theo=/
						else 
							#c'est une chemin relatif donc on part de la position actuelle 						
							position_theo=$position
						fi
                                        	verif_chemin cat 
                                	fi

				#le chemin ne contient que le nom du ficher car pas de "/" avant	
				else
					fichier=$chemin
					position_theo=$position
					#on appelle la fonction cat 
					cat_archive
				fi
			else 
				echo "il n'y a pas de chemin après le cat"
			fi
#----------------------Partie autre
		elif [ "$commande" = "exit" ] #facultatif
		then
			echo "enrevoir"
		elif [ "$commande" = "pwd" ]
		then
			echo $position 
		else 

			echo "la commande n existe pas"
		fi



#________________________________CAS D'UNE ARCHIVE QUI N'EXISTE pas____________________
		done
	else 
		#on tue le processus du serveur pour que le client se deconnecte
		pkill -9 nc 
		#on relance le serveur
		nc -l -k 3333 < FIFO | bash server.sh > FIFO

	fi

#---------------------------------PARTIE EXTRACT--------------------------------

elif [ "$option" = "extract" ]
then
	read nom_archive
	#archive contient le chemin et le nom de l'archive choisie par l'utilisateur
	archive=$position_archives/$nom_archive

	#on test si l'archive existe
	verif_archive

	if [ "$test_archive_existe" = "oui" ]	
	then
#====================================================
         	debut_header=$(head -1 "$archive" | cut -f1 -d ':')
         	fin_header=$(head -1 "$archive" | cut -f2 -d ':')

	         compteur=0
	                for i in $(head -$fin_header $archive | tail -$[$fin_header] | grep directory | sed 's/^directory \(.*\)$/\1/g')
        	        do
        	                mkdir -p "./$i"
        	                compteur=$(($compteur + 1))
        	                posd=$[$(grep -n "$i$" $archive | sed 's/^\([0-9]*\):.*$/\1/g')+1]
	
        	                posf=$[$(grep -n "@" $archive | head -$compteur | tail -1 | sed 's/^\([0-9]*\):@$/\1/g')-1]
	
        	                oldIFS=$IFS
        	                IFS=$'\n'
        	                for n in $(sed -n ""$posd","$posf"p" $archive)
        	                do
        	                        echo "$n"
	
        	                        if [ "$(echo "$n" | cut -d' ' -f 2 | sed 's/\([d-]\).*$/\1/g')" = "-" ]	
        	                        then 
						touch "./$i/$(echo "$n" | cut -d' ' -f 1)"
					     	debfich=$[$(echo "$n" | cut -d' ' -f 4)+$fin_header]
					     	finfich=$[$(echo "$n" | cut -d' ' -f 5)+$debfich-1]

					     	sed -n ""$debfich","$finfich"p" $archive > "./$i/$(echo "$n" | cut -d' ' -f 1)"
                                        else echo 0
                                	fi
                        	done
                		IFS=$oldIFS

                	done
#==================================================================================
	else 

		#on tue le processus du serveur pour que le client se deconnecte
		pkill -9 nc 
		#on relance le serveur
		nc -l -k 3333 < FIFO | bash server.sh > FIFO

	fi


else 
	echo "l'option du vsh n'existe pas"

fi
done
