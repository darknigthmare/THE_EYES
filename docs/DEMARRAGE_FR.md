# THE EYES — démarrage rapide

Le prototype **0.2.0, The Observance Collection** est un jeu 3D local sous Godot.
Il propose deux rôles, **six épreuves disponibles et trois actives par partie**.
Le jeu et sa bible sont en anglais, conformément au concept fourni.

## Lancer le jeu

**Windows :** télécharge le [ZIP Windows x64](https://github.com/darknigthmare/THE_EYES/releases/download/v0.2.0/THE_EYES_v0.2.0_Windows_x64.zip)
depuis la [version 0.2.0](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.2.0).
Décompresse entièrement `THE_EYES_v0.2.0_Windows_x64.zip`, puis ouvre
`THE_EYES.exe`. Godot n'est pas nécessaire. C'est un exécutable de développement
non signé, avec les données du jeu intégrées.

La publication exige un export contrôlé, puis le démarrage réel du même ZIP sur
un environnement Windows, sans affichage, pour les deux rôles et les trois
contrats. Le fichier `WINDOWS_SMOKE.json` de la release donne les résultats
exacts. Une partie graphique sur un PC Windows reste un contrôle distinct à
réaliser ; le rendu graphique a été vérifié sous Linux.

**Sources :** dans Godot **4.7.2**, importe `game/project.godot`, attends la fin
de l'import et appuie sur **F5**. Aucun compte, serveur ni clé API.

## Choisir sa partie

| Choix | Contenu |
| --- | --- |
| **First Observance** | Silent Countdown, Trial of the Echoes, Clockwork Relay |
| **Second Observance** | The Memory Vault, The Ritual Circle, The Clock Room |
| **Seeded Mix** | Une épreuve parmi deux dans chaque zone : huit combinaisons possibles |
| **Enter as a survivor** | Première personne contre l'Œil IA |
| **Take the Eye's seat** | L'Œil contre quatre survivants IA qui se déplacent réellement |

Commence par **Story / Keeper / First Observance** pour apprendre l'arène.
Passe à **Second Observance** pour les nouveaux mécanismes. Le nombre `Seed`
fixe les épreuves et leurs énigmes ; il ne garantit pas un déroulement identique
au centième de seconde. Standard et Ruthless augmentent la pression.

Les classes sont **Veil** pour la discrétion, **Tinker** pour les mécanismes,
**Runner** pour la course et **Keeper** pour les soins. Tinker peut obtenir
pendant huit secondes un conseil sur le prochain levier de l'horloge ; il faut
toujours se déplacer et effectuer l'action.

## Commandes du survivant

| Commande | Action |
| --- | --- |
| ZQSD/WASD ou flèches ; souris | Se déplacer ; regarder |
| Maj ; Ctrl/C ; Espace | Sprinter ; s'accroupir ; sauter |
| E / maintenir E | Interagir / charger / sortir |
| **A sur AZERTY / Q sur QWERTY** | Pouvoir de classe |
| G | Déposer un fragment ou rendre une relique/braise à son support |
| 1–4 ; R dans Echoes | Saisir les symboles ; rejouer la séquence |
| E / R près d'un levier d'horloge | Tourner en avant / en arrière |
| X au centre de l'horloge | Réinitialiser ses aiguilles |
| Tab ; Échap | Carte ; pause et réglages |

Le jeu affiche les positions physiques d'un clavier QWERTY. Le « Q » affiché
correspond donc à **A sur AZERTY**. Les positions 1–4 de la rangée supérieure
fonctionnent sans maintenir Maj, pour les symboles et les points d'observation.

## First Observance

1. Rapporte **trois fragments lumineux**, un par un, à **Silent Countdown** au
   nord-ouest. E les prend et les dépose. Courir avec un fragment fait du bruit.
2. À **Trial of the Echoes**, au nord-est, observe la séquence puis reproduis-la
   avec 1–4. R la rejoue ; E/Échap permet de partir. Le danger continue.
3. À **Clockwork Relay**, au sud, maintiens E. Les paliers d'un tiers et de deux
   tiers restent acquis si tu dois te cacher.
4. Les trois sceaux ouvrent **The Unseen Door**, au nord. Rejoins-la et maintiens
   E pendant 1,5 seconde avant la fin du compte à rebours d'évasion.

## Second Observance

1. **The Memory Vault, nord-ouest :** lis les quatre reliques indiquées au bureau
   avec E. L'ordre reste visible huit secondes et peut être relu. Cherche les
   objets sur les six supports du sud, transporte-les un par un et place chaque
   relique dans le bon berceau numéroté. Une erreur conserve l'objet en main ; G
   le remet sur son support. Les placements réussis restent acquis.
2. **The Ritual Circle, nord-est :** prends la braise commune, puis allume les
   cinq réceptacles dans l'ordre indiqué. Chaque paire validée reste acquise.
   Une erreur sur un réceptacle encore éteint annule la partie non sauvegardée
   et rend la braise. Une fois les cinq allumés, reste huit secondes dans le
   cercle. **Continue à te déplacer à l'intérieur** pour éviter le danger.
   Sortir remet uniquement ce dernier maintien à zéro, sans éteindre les flammes.
3. **The Clock Room, sud :** lis la cible des trois aiguilles, de 0 à 5. Le
   levier A déplace A+B, B déplace B+C, C déplace C+A. Approche chaque levier :
   E avance, R recule. Chaque énigme générée se résout en quatre actions
   optimales. Quand les trois aiguilles correspondent, confirme avec E au
   centre. X au centre permet de repartir de l'état initial.
4. Sors par la même porte nord après les trois sceaux. L'ordre des épreuves
   est libre. Seeded Mix reprend les règles des trois épreuves qu'il sélectionne.

Les murs et le monument central coupent réellement le regard. Sors des cercles
dorés avant les piques. Le premier échec mortel propose **Second Sight** : trois
appuis sur E lorsque l'anneau est vert. Après un retour réussi, le prochain échec
mortel est définitif. La partie entière peut être mise en pause avec Échap.

## Jouer l'Œil

**1–4 / molette** change de point d'observation. La souris oriente le regard.
**Clic gauche :** déclencher le piège visible visé. **Clic droit :** marquer un
survivant visible. **A sur AZERTY / Q sur QWERTY :** invoquer une ombre sur un
sol libre visible. L'énergie, les délais et les avertissements limitent les
pouvoirs. L'Œil reste fixé à ses points d'observation ; il ne peut pas marcher.

Les quatre survivants IA utilisent les objets et les mêmes validations de
distance et d'obstacle que le joueur. Ils savent accomplir les six épreuves et
tenter la sortie pour chacun des contrats.

## Sauvegardes et contenu livré

`settings.cfg` conserve les réglages. `last_observance.json` conserve le dernier
résultat avec la version, le contrat, les trois épreuves, la graine et les
événements. Il ne permet pas de reprendre une partie interrompue.

Le prototype livre une arène, deux rôles locaux, six épreuves principales, une
salle de récupération, quatre classes, l'IA, les pièges, les ombres, les fins de
partie, l'interface, les sons et les réglages. La [bible](bible/README.md) détaille
les **25 épreuves**, quatre univers, huit personnages et le multijoueur visé.

`unreal/` prépare le portage **UE5 en Blueprints uniquement** : projet, paramètres,
sept tables CSV et recettes détaillées. Il ne contient pas encore de carte
Unreal jouable ni de Blueprints compilés. Le réseau, les 19 autres épreuves et
les variantes complètes de production restent des étapes suivantes.

Voir le [rapport de vérification 0.2](qa/V0_2_VERIFICATION.md) pour les tests et
leurs limites, et les [notes de version](releases/V0_2_0.md) pour les changements.
