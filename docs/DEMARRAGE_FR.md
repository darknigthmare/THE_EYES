# THE EYES — démarrage rapide

Le prototype **0.1.0, The First Observance** est un jeu 3D local sous Godot.
Le jeu et sa bible sont en anglais, conformément au concept fourni.

## Lancer le jeu

**Windows :** télécharge le [ZIP Windows x64](https://github.com/darknigthmare/THE_EYES/releases/download/v0.1.0/THE_EYES_v0.1.0_Windows_x64.zip)
depuis la [version 0.1.0](https://github.com/darknigthmare/THE_EYES/releases/tag/v0.1.0).
Décompresse entièrement `THE_EYES_v0.1.0_Windows_x64.zip`, puis
ouvre `THE_EYES.exe`. Godot n'est pas nécessaire. C'est un exécutable de
développement non signé. L'export et sa structure ont été contrôlés ; la
validation sur un véritable PC Windows reste à faire.

**Sources :** dans Godot **4.7.2**, importe `game/project.godot`, attends la fin
de l'import et appuie sur **F5**. Aucun compte, serveur ni clé API.

## Choisir son rôle

- **ENTER AS A SURVIVOR :** première personne contre l'Œil IA.
- **TAKE THE EYE'S SEAT :** l'Œil contre quatre survivants IA.
- **Story :** découverte avec davantage de temps et un regard moins punitif.
- **Standard / Ruthless :** pression croissante.

Les classes sont **Veil** pour la discrétion, **Tinker** pour le mécanisme,
**Runner** pour la course et **Keeper** pour les soins.

## Survivant

**ZQSD/WASD** ou flèches pour bouger ; souris pour regarder ; **Maj** pour
sprinter ; **Ctrl/C** pour s'accroupir ; **Espace** pour sauter ; **E** pour
interagir ; **Q** pour le pouvoir ; **Tab** pour la carte ; **Échap** pour la pause.

1. Rapporte les **trois fragments lumineux**, un par un, à **Silent Countdown**
   au nord-ouest. E les prend et les dépose. Courir avec un fragment fait du bruit.
2. À **Trial of the Echoes**, au nord-est, observe et reproduis la séquence avec
   **1–4**. **R** la rejoue ; **E/Échap** permet de partir. Le danger continue.
3. À **Clockwork Relay**, au sud, maintiens **E**. Les paliers d'un tiers et de
   deux tiers restent acquis si tu dois te cacher.
4. Rejoins **The Unseen Door**, au nord, après l'ouverture des trois sceaux,
   puis maintiens E pendant 1,5 seconde pour gagner.

Les murs et le monument central coupent réellement le regard. Sors des cercles
dorés avant les piques. Le premier échec mortel offre **Second Sight** : trois
appuis sur E lorsque l'anneau est vert. Après un retour réussi, le prochain
échec mortel est définitif.

## Œil

**1–4 / molette** change de point d'observation. La souris oriente le regard.
**Clic gauche :** piège visible visé. **Clic droit :** marquer un survivant visible.
**Q :** invoquer une ombre sur un sol libre visible. L'énergie, les délais et
les avertissements limitent les pouvoirs. L'Œil ne peut pas marcher.

## Contenu livré et suite du projet

Une arène complète, deux rôles locaux, trois épreuves principales, une salle de
récupération, quatre classes, l'IA, les pièges, les ombres, les fins de partie,
l'interface, les sons et les réglages. La bible détaille **les 25 épreuves**, les
quatre univers, huit personnages et la version multijoueur visée.

`unreal/` prépare le portage **UE5 en Blueprints uniquement** : projet, paramètres,
tables et recettes détaillées. Il ne contient pas encore de carte Unreal jouable
ni de Blueprints binaires. Le réseau et les 22 autres grandes épreuves sont
des étapes suivantes, distinguées du prototype dans chaque document.
