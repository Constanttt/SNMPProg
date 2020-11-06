# Projet SNMP

Le projet consiste à développer un outil permettant de monitorer des équipements en utilisant le protocole SNMP.
Les objectifs sont les suivants :

- Surveiller en ligne l'ensemble du matériel constituant le parc. Elle peut avoir une représentation graphique ou/et textuelle.
- Sauvegarder l'ensemble des données issues des équipements.
- Gérer les erreurs possibles en les signalant à l'utilisateur et dans un système de log.

## Organisation de l'application

### Module de configuration

L'application doit être configurable, c'est à dire qu'il doit être possible d'ajouter du nouveau matériel a configurer, ou supprimer un équipement. Les informations importante sont le matériel en lui même et type d'information a monitorer.
Il faut donc développer un module qui permet de gérer cette configuration de la façon al plus simple possible. 

### Module de surveillance

Ce module doit pouvoir contacter les équipements décrits dans la configuration afin de les surveiller en les interrogeant de manière périodique en utilisant SNMP. Les informations alors obtenues seront alors utilisées pour de l'affichage graphique ou/et textuel.

### Module de "Log"

Pour une application de surveillance, il est très important de consigner chaque évènement (information, erreur) dans une base de données. Cela permet en particulier de pouvoir retracer l'historique d'un équipement mais aussi de rajouter des modules de détection de panne, de surveillance de vieillissement.

## Organisation du travail

Chaque module peut être développé indépendamment. Ils feront chacun l'objet d'une étude permettant de définir les fonctionnalités essentielles (Use Cases). Un schéma de classes décrivant les principales entités du module et leurs relations avec les classes internes ou extérieures au module constitueront le point de départ de chacune des implémentations.

## Implémentation

### Choix techniques

#### Langage

Le langage principal utilisé pour développer cette application est le Python. C'est un langage maîtrisé par les membres du binôme. C'est aussi un langage pertinent pour faire une application de ce genre : il est possible de créer une interface, de lire des fichiers et de communiquer avec une base de donnée.

Le module de surveillance sera développé en bash, car la commande `snmp-table` permet une gestion des données plus simple. Nous n'avons pas trouvé d'alternative satisfaisante a cette commande en Python.

#### Architecture

L'application sera découpée en plusieurs modules différents :

- Module de configuration
- Module de surveillance
- Module de traitement des données
- Module de log
- Module de connexion a la base de donnée
- Module "interface web"

Les modules seront développés pour pouvoir fonctionner de manière indépendante. Ils communiqueront via API REST. Ce choix de fonctionnement a été choisi afin de permettre à l'administrateur de l'application de mettre les modules sur différents serveurs, si il le souhaite. Ce fonctionnement permet aussi de limiter la charge de travail sur un seul module en répartissant les taches entre différents modules. 

### Organisation du travail

Nous avons décider d'utiliser Trello pour la gestion de projet. Cet outil correspond bien a notre projet, chaque module correspondant a une tache, chaque taches ayant des "objectifs" a remplir pour être complétée.

Le code est stocké sur un dépot github privé. Il est constitué de plusieurs dossiers : un dossier par module développé.
L'utilisation de github permet de travailler sur un même projet facilement, tout en ayant un historique des versions.
Les fonctions et variables seront nommées en utilisant un '`_`' pour séparer les mots.

Pour la communication interne au binôme, les applications Teams et Discord sont utilisées.

L'application est testée sur un environnement physique présent

### Avancement

#### Module de configuration

Cas d'utilisation du module de configuration :

![Usecase](doc/Usecase.png)

**Organisation du module :**
	Classe Conf_Reader qui va s'occuper de la lecture du ficheir de configuration.
	Cette classe sera utilisé dans la fonction principale.
	Les différentes méthodes de Conf_Reader seront réparties sur différents endpoint en utilisant des méthodes différentes (POST, GET, PUT etc...)

Le module de configuration est développé en Python.
Il permet de lire un fichier XML et de le modifier (ajouter un élément, supprimer un élément, éditer un élément).
L'utilisation d'un fichier XML permet a un administrateur d'aller éditer le fichier directement si il le souhaite.

Ce module est accessible via une API REST. La base de cette API se fait grâce au framework web `Flask` et son module `Flask RESTful`.
Il propose 2 endpoint :

- `/api/devices` pour récupérer la liste des équipements et créer un nouvel équipement.
- `/api/devices/<device_ip>` pour modifier ou supprimer un équipement, un équipement étant reconnu par son adresse IP.

La difficulté principale rencontrée lors du développement de ce module fut le traitement du fichier XML. Il fallait d'abord réfléchir à une organisation du fichier pertinente, puis réussir a modifier / supprimer une valeur précise. retrouver un élément dans un fichier XML a pris plus de temps que prévu. 

Ce module est terminé, il propose toutes les fonctionnalités prévues initialement.

#### Module de surveillance

Le module de configuration est développé en Bash.

#### Module de traitement des données

*en cours*

#### Module de log

*en cours*

#### Module de connexion a la base de donnée

*en cours*

#### Module de "interface web"

*en cours*

## Conclusion

