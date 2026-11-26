# THE EYES — démarrage rapide

Le prototype **0.4.0, The Third Observance**, propose trois façons de jouer en
local : survivant Solo, **toi avec quatre alliés IA**, ou l'Œil contre quatre
survivants IA. Il conserve **neuf épreuves disponibles, trois actives par partie**.
Le jeu et sa bible sont en anglais, conformément au concept fourni.

## Lancer le jeu

**Windows :** télécharge le [ZIP Windows x64 0.4.0](https://github.com/darknigthmare/THE_EYES/releases/download/v0.4.0/THE_EYES_v0.4.0_Windows_x64.zip)
depuis la [release 0.4.0](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.4.0).
Décompresse entièrement `THE_EYES_v0.4.0_Windows_x64.zip`, puis ouvre
**THE_EYES.exe**. Godot n'est pas nécessaire pour ce paquet. C'est un exécutable
de développement non signé, avec les données du jeu intégrées.

La publication exige le démarrage du même paquet sur Windows, sans affichage,
pour les **douze combinaisons mode × contrat**. `WINDOWS_SMOKE.json` donne les
résultats réellement obtenus. Une partie graphique sur un PC Windows reste une
validation distincte. Consulte le [rapport 0.4](qa/V0_4_VERIFICATION.md) pour les
contrôles terminés et ceux qui restent à faire.

**Sources :** dans Godot **4.7.2**, importe `game/project.godot`, attends la fin
de l'import et appuie sur **F5**. Aucun compte, serveur, plugin ni clé API.

## Choisir sa partie

Commence par **Story / Keeper / First Observance**. Tu peux ensuite sélectionner :

| Bouton | Partie |
| --- | --- |
| **Play Solo as a Survivor** | Un survivant contre l'Œil IA ; récupération Solo avec Second Sight |
| **Lead a Local Squad · You + 4 AI** | Ton survivant et quatre alliés IA contre l'Œil IA |
| **Take the Eye's Seat** | L'Œil contre quatre survivants IA |

Il n'y a ni salon réseau ni second joueur humain local. Une seule évasion valide
fait gagner toute l'équipe, même si ton propre survivant a déjà été éliminé.

| Contrat | Épreuves |
| --- | --- |
| **First Observance** | Silent Countdown, Trial of the Echoes, Clockwork Relay |
| **Second Observance** | The Memory Vault, The Ritual Circle, The Clock Room |
| **Third Observance** | Light in the Darkness, Strings of Despair, Chimes of Doom |
| **Seeded Mix** | Une épreuve parmi trois dans chaque zone : 27 combinaisons possibles |

Les trois modes acceptent tous les contrats. Le nombre `Seed` fixe la sélection
et les énigmes dans une même version ; il ne reproduit pas exactement les temps
de déplacement ou les décisions de l'IA. Standard et Ruthless augmentent la
pression. Les huit premières secondes protègent les survivants. Le passage à
neuf épreuves change la sélection Mix : une graine 0.3 peut donner un autre
ensemble en 0.4. First et Second gardent leurs énigmes déterministes.

## Diriger l'escouade

Le groupe contient ton personnage et un bot de chaque classe. Les noms restent
distincts ; le bot de ta classe utilise une identité alternative de la bible.
Le tableau à droite affiche l'état, les PV, la tâche, le temps avant élimination
et la progression du secours. Tab le remplace par la carte.

| Touche | Ordre | Effet |
| --- | --- | --- |
| **B** | Work | Les alliés avancent sur les épreuves actives |
| **F** | Follow | Ils viennent vers toi ; si tu es inactif, ils peuvent reprendre le travail |
| **V** | Hold | En passant à cet ordre, chaque bot mémorise sa propre position |

Le danger immédiat, un secours possible et l'évacuation par une sortie ouverte
peuvent passer avant l'ordre normal. Un bot qui voit une ombre proche peut se
dégager en courant sur un trajet praticable, puis reprendre sa tâche. Cette
esquive interrompt un secours et remet sa progression à zéro. Hold ne bloque
pas l'évacuation quand la porte s'ouvre.

### Secourir un allié

Chaque membre dispose d'**une seule réanimation**. Sa première chute mortelle
l'immobilise au sol avec **35 secondes avant élimination**. Approche à moins de
**1,8 m**, garde une ligne de vue dégagée, reste immobile et **maintiens E six
secondes sans interruption avant la fin du délai**. Les bots respectent les
mêmes conditions physiques. Un seul secouriste peut aider une personne à la fois.

Bouger, sauter, relâcher E, sortir de portée, perdre la visibilité ou recevoir
un coup annule la tentative et remet sa progression à zéro. La pause fige le
délai mais annule le secours partiel ; il faut recommencer le maintien après
reprise. Le secours rend
**35 PV et cinq secondes de protection**. La chute mortelle suivante élimine le
membre. Le délai de 35 secondes expiré l'élimine aussi. Si personne ne reste
debout pour aider, l'escouade perd immédiatement.

Les objets indispensables sont libérés sans être détruits quand leur porteur
tombe. Après ton élimination, **1–4 / molette** permet de regarder les survivants
restants depuis leur position réelle. Leur sortie peut encore faire gagner
l'équipe.

### Keeper et les autres classes

**Keeper / Mend** rend jusqu'à **30 PV**, avec **35 secondes de recharge**, au
membre actif admissible le plus blessé, **toi compris**. Un allié doit être à
moins de 4 m avec une vue dégagée. À PV égaux, le soin privilégie Keeper, puis
un ordre stable entre alliés. Mend ne relève pas un membre au sol et ne rend
pas une réanimation déjà utilisée. En Solo, il te soigne toi-même.

**Veil** réduit le bruit et temporairement l'exposition au regard. **Runner** a
plus d'endurance et une accélération temporaire. **Tinker** contribue plus vite
au Relay et peut obtenir pendant huit secondes un conseil pour le prochain
levier de l'horloge ; il faut toujours se déplacer et agir. Le travail cumulé
de l'escouade sur le Relay est limité à **1,8 fois sa vitesse de base**, avec une
seule mise à jour par pas physique. Les règles Solo restent inchangées.

## Commandes

| Commande | Action |
| --- | --- |
| ZQSD/WASD ou flèches ; souris | Se déplacer ; regarder |
| Maj ; Ctrl/C ; Espace | Sprinter ; s'accroupir ; sauter |
| E / maintenir E | Interagir, charger, secourir ou sortir selon le contexte |
| **A sur AZERTY / Q sur QWERTY** | Pouvoir de classe |
| G | Déposer un fragment ou rendre une relique, braise ou cellule à son support |
| B / F / V en Squad | Work / Follow / Hold |
| 1–4 ; R dans Echoes | Saisir les symboles ; rejouer la séquence |
| E / R près d'un levier ; X au centre | Avancer / reculer l'horloge ; la réinitialiser |
| E / R près d’une cloche | Frapper / déplacer ou enlever la sourdine commune |
| 1–4 / molette après élimination en Squad | Observer un allié |
| Tab ; Échap | Carte ; pause et réglages |

Le jeu affiche les positions physiques d'un clavier QWERTY : son « Q »
correspond à **A sur AZERTY**. Les positions 1–4 de la rangée supérieure
fonctionnent sans Maj, pour les symboles, les points d'observation et le
spectateur.

## Réussir First Observance

1. Rapporte **trois fragments lumineux**, un par un, à **Silent Countdown** au
   nord-ouest. E les prend et les dépose. Courir avec un fragment fait du bruit.
2. À **Trial of the Echoes**, au nord-est, observe les quatre symboles puis
   reproduis-les avec 1–4. R rejoue la séquence ; E/Échap permet de partir.
   L'Œil continue d'agir pendant l'énigme.
3. À **Clockwork Relay**, au sud, maintiens E. Les paliers d'un tiers et de deux
   tiers restent acquis si tu dois te cacher.
4. Les trois sceaux ouvrent **The Unseen Door**, au nord. Rejoins-la et maintiens
   E pendant **1,5 seconde** avant la fin du nouveau compte à rebours d'évasion.

## Réussir Second Observance

1. **The Memory Vault, nord-ouest :** E au bureau affiche quatre reliques pendant
   huit secondes, avec relecture possible. Cherche-les parmi les six supports
   du sud et transporte chaque objet vers son berceau numéroté exact. Une erreur
   conserve l'objet en main ; G le remet sur son support. Les succès sont acquis.
2. **The Ritual Circle, nord-est :** prends la braise commune et allume les cinq
   réceptacles dans l'ordre. Les paires validées restent acquises. Une erreur
   sur un réceptacle éteint annule seulement la partie non validée et rend la
   braise. Ensuite, reste huit secondes dans le cercle : **continue à bouger
   à l'intérieur de son rayon de 2,8 m** pour éviter le danger. Sortir remet
   uniquement ce maintien à zéro. Le secours, lui, exige de rester immobile.
3. **The Clock Room, sud :** lis la cible des trois aiguilles, de 0 à 5. A déplace
   A+B, B déplace B+C, C déplace C+A. Près d'un levier, E avance et R recule.
   Chaque départ généré exige quatre actions optimales. Une fois aligné,
   confirme avec E au centre ; X y permet de repartir de l'état initial.
4. Sors par la même porte nord après les trois sceaux. L'ordre des épreuves est
   libre. Seeded Mix reprend les règles de ses trois épreuves sélectionnées.

## Réussir Third Observance

1. **Light in the Darkness, parcours ouest :** chaque cellule porte le numéro
   de sa lampe. Prends-la avec E et rejoins le refuge correspondant. Maintiens
   E **deux secondes**, immobile, à moins de **1,8 m**, avec une vue dégagée.
   Chaque lampe allumée reste acquise. La charge commence à 100 et baisse de
   **4 points par seconde uniquement quand tu portes une cellule hors refuge**.
   Le refuge initial et les lampes déjà allumées rendent **12 points par seconde**
   dans leur rayon de **3 m**, avec visibilité. Une charge vide bloque
   l’alignement ; tu peux toujours marcher et revenir recharger. G rend la cellule.
2. **Strings of Despair, nord-est :** lis les deux indices du pupitre. Le premier
   désigne la paire de gauche ou de droite ; le second une forme courbe
   (**cercle ou croissant**) ou anguleuse (**triangle ou losange**). Une seule
   corde satisfait les deux indices. Maintiens E **deux secondes** près d’elle,
   sans bouger. Chacun des **trois paliers** reste acquis. Une erreur déclenche
   un arrêt de sécurité de **trois secondes**, puis laisse réessayer.
3. **Chimes of Doom, sud :** lis la partition de quatre notes, puis marche
   jusqu’aux cloches numérotées. **E frappe** ; **R place ou retire l’unique
   sourdine** sur la cloche proche. Deux phrases terminent l’épreuve. Une erreur
   remet seulement la phrase actuelle à zéro ; la première phrase validée reste
   acquise. La sourdine réduit le bruit d’une note juste ; une erreur reste bruyante.
4. Les trois sceaux ouvrent la même porte nord. Bouger, sauter, subir un coup,
   perdre la portée ou la vue, relâcher E ou mettre en pause annule un
   alignement ou une coupe partielle. Les paliers déjà validés restent acquis.

Les murs et le monument central coupent réellement le regard. Quitte les
avertissements dorés avant les piques ; les ombres annoncent leur arrivée.
Le microphone n'est jamais utilisé : le bruit vient des déplacements, des actions et des cloches du jeu.

**En Solo uniquement**, la première chute mortelle propose **Second Sight** :
trois appuis sur E quand l'anneau est vert, dans un délai de 25 secondes. Un
mauvais appui retire deux secondes. Réussir rend 50 PV et cinq secondes de
protection ; la chute mortelle suivante est définitive. Squad utilise le
secours entre alliés à la place.

## Jouer l'Œil

**1–4 / molette** change de point d'observation ; la souris oriente le regard.
**Clic gauche :** piège visible visé. **Clic droit :** marquer un survivant
visible. **A sur AZERTY / Q sur QWERTY :** invoquer une ombre sur un sol libre
visible. L'énergie, les délais et les avertissements limitent les pouvoirs.
L'Œil reste fixé à ses points d'observation et ne peut pas marcher.

Les quatre survivants IA se déplacent et utilisent les objets avec les mêmes
validations physiques. Ils peuvent accomplir les neuf épreuves et tenter la
sortie pour chaque contrat. Le système de réanimation Squad appartient au mode
escouade, pas à cette partie de l'Œil.

## Réglages, traces et contenu livré

Échap met toute la partie locale en pause. Les réglages comprennent son,
mouvements/vignette réduits, inversion verticale, sensibilité et champ de vue.
Le changement des touches et les manettes restent à ajouter.

`settings.cfg` conserve les réglages. `last_observance.json`, en **schéma 3**,
conserve mode de session, contrat, épreuves, graine, résultat, événements et
bilan d'escouade. C'est un compte rendu après partie, sans reprise d'une partie
interrompue ni relecture complète de sa simulation.

Le [rapport 0.4](qa/V0_4_VERIFICATION.md) distingue les tests de règles, les
situations physiques préparées, les parcours complets contre l’Œil actif et
les démarrages Windows. Il donne les résultats réellement mesurés pour cette
version. Les contrôles de démarrage ne remplacent pas une partie graphique
complète sous Windows.

Le prototype conserve une arène, trois modes locaux, neuf épreuves, quatre
classes et les huit noms de personnages de la bible pour distinguer l'équipe.
La [bible](bible/README.md) détaille les **25 épreuves**, quatre univers et la
production visée. `unreal/` prépare le portage **UE5 en Blueprints uniquement**
avec projet, paramètres, **neuf tables CSV** et recettes ; il ne fournit pas
encore de carte jouable ni de Blueprints compilés. Le réseau, les 16 autres
épreuves et les variantes complètes restent des étapes suivantes.

Voir les [notes 0.4.0](releases/V0_4_0.md) pour les changements et le
[rapport de vérification](qa/V0_4_VERIFICATION.md) pour leur validation exacte.
