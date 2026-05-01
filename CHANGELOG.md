# Changelog

Toutes les modifications notables du gamemode gRust seront documentées dans ce fichier.

## [1.0.0] - 2026-05-01

### Added
- **Système de Permissions** - Intégration complète basée sur ULX avec repli sur les vérifications admin standards[cite: 4].
  - Configuration par commande via `!perm set <clé> <grade>`[cite: 1].
  - 5 niveaux de permission : public, user, moderator, admin, superadmin[cite: 4].
  - Accès restreint par défaut aux administrateurs pour toutes les commandes sensibles[cite: 4].
- **Commandes de Chat** - Système complet avec préfixe `!`[cite: 1].
  - `!grust help` - Affiche l'aide[cite: 1].
  - `!multiplier` - Visualise et modifie les taux[cite: 1].
  - `!giveitem` / `!give` - Donne des objets[cite: 1].
  - `!save` / `!load` - Persistance de l'état du gamemode[cite: 2].
  - `!wipe` - Options de réinitialisation complète ou partielle[cite: 1, 9].
  - `!perm` - Gestion des permissions en jeu[cite: 1].
- **Commandes Centralisées** - Consolidation de toutes les commandes dans `commands_sv.lua`[cite: 1].
- **Persistance de Configuration** - Système JSON avec synchronisation automatique vers les clients[cite: 8, 9].
- **Système de Multiplicateurs** - Gestion individuelle pour le farming, les ressources, le recycleur et le loot[cite: 1].

### Fixed
#### Sécurité et Réseau
- **Vérification Réseau (Anti-Exploit)** - Le serveur vérifie désormais systématiquement les permissions avant d'autoriser le spawn d'items via le menu F1, empêchant les injections réseau[cite: 4, 6].
- **Validation des Entités** - Ajout de vérifications `IsValid()` sur les systèmes critiques : Loot, Blueprints, Deploy et Rotation d'objets pour éviter les crashs Lua.
- **Système de Munitions & Attire** - Validation des messages réseau et des types de données pour les index de munitions et la synchronisation des vêtements.

#### Interface et Logique
- **UI Tech Tree & Items** - Correction des accès `nil` lors de la récupération des icônes ou des coûts de recherche.
- **Gestion des Équipes** - Correction d'une condition de course (race condition) via un délai SQL pour garantir l'insertion en base de données.
- **Tooltip UI** - Sécurisation du fichier `tooltip_cl.lua` contre les valeurs `nil` lors du survol d'objets.

### Changed
- **Système de Wipe Amélioré** - Comportement plus robuste et informatif[cite: 9] :
  - `!wipe all` : Supprime les données de jeu (entités/sauvegardes) MAIS conserve la configuration, suivi d'un redémarrage[cite: 9].
  - `!wipe config` : Supprime physiquement tous les fichiers JSON de configuration et redémarre[cite: 9].
  - Ajout d'un délai de 2 secondes avant redémarrage et kick automatique des joueurs avec messages dédiés[cite: 9].
- **Menu F1** - Suppression de la dépendance à `sv_cheats`. Toutes les vérifications de spawn sont traitées côté serveur via le système de permissions[cite: 6].
- **Fiabilité Config** - Amélioration de `GetConfigValue` et `SetConfigValue` avec gestion des structures existantes et rechargement automatique[cite: 9].

### Documentation
- Mise à jour du README.md avec la documentation détaillée des commandes et des niveaux de permission.

## Installation & Configuration
1. Installer **ULib** et **ULX** (Requis).
2. S'abonner au gamemode et à la map recommandée (rust_highland).
3. Sélectionner le gamemode "Rust" au lancement du serveur.