# Le Roi de la Savane — Génération 10

Stratégie Pine Script® v6 (TradingView). Fichier : `Roi_de_la_Savane_G10.pine`.

La G10 part de la G9 et répond à deux demandes : **rendre les vingt savanes
configurables indépendamment** et **contrôler le forex et les métaux** pour que
seize ans de chasse rapportent autre chose que 5 000 €.

---

## 1. Bugs corrigés

| # | Bug de la G9 | Effet réel | Correction |
|---|---|---|---|
| 1 | Score des savanes = momentum sur **252 bougies** ÷ volatilité annualisée en **√252**, quelle que soit l'unité de temps | En hebdomadaire, 252 bougies = 4,8 ans : score gonflé ≈ 2,2×, tous les territoires paraissaient gras ; en mensuel, ≈ 4,6× | Vrai t-statistique `|log(close/close[N])| / (bruit × √N)` avec `N` = 252 / 52 / 12 selon l'unité de temps |
| 2 | Volatilité annualisée en jours **calendaires** (`√(31 536 000 / durée_bougie)` = √365 en journalier) sur une série de bougies de **bourse** | Volatilité surestimée de 23 % → levier sous-dimensionné de 23 % en permanence | Annualisation en jours de bourse (√252) |
| 3 | Part affichée des contrariennes = `(w6+w7+w8)/wTot` | Le tableau annonçait ~20 % là où le plafond en comptait 45 % : la Hyène, le Serpent et le Vautour étaient oubliés | Les six contrariennes sont comptées (`w6+w7+w8+w11+w15+w16`) |
| 4 | Tendance de fond figée à 252 bougies | En hebdomadaire, le filtre jugeait sur 5 ans ; en mensuel, sur 21 ans | Suit l'unité de temps (`lbAn`) |
| 5 | Le classement de migration incluait toutes les savanes | Une savane sans données (ou sans intérêt) pouvait être « conseillée » | Une savane décochée est écartée du classement, de la ruche et du tableau |
| 6 | `bestFit` recalculé une seconde fois, identique à `bestRef` | Aucun (redondance) | Une seule chaîne de `math.max` |
| 7 | 20 × `request.security` évaluant trois fois le même `ta.stdev` | Risque de dépassement du budget de calcul TradingView | Deux valeurs par appel, score calculé en local |

Le pseudo-aléatoire de mutation (`math.sin(bar_index × 12.9898)`), la structure
sans boucle ni fonction, et les deux seules lignes indentées en fin de fichier
sont conservés à l'identique.

---

## 2. Les vingt savanes, indépendantes

Chaque territoire porte désormais **sa propre ligne de réglages** :

```
[✓ surveiller]  [symbole]  [seuil]
```

- **surveiller** : décochée, la savane est ignorée partout — score, migration,
  ruche des abeilles, tableau.
- **symbole** : inchangé.
- **seuil** : le score minimal propre à cette savane. `0` = hérite du seuil de
  la classe d'actif. On peut donc exiger 1,2 du Nasdaq et 0,3 de l'EURGBP.

La savane locale (celle sous les pattes du roi) a également son seuil propre,
indépendant des vingt autres.

**La migration classe par excédent au-dessus du seuil propre**, pas par score
brut : un territoire exigeant à 1,10 pour un seuil de 1,20 est moins chassable
qu'un territoire tolérant à 0,45 pour un seuil de 0,30. La G9, qui classait par
score brut, conseillait systématiquement le premier.

---

## 3. Forex et métaux : d'où venaient les 5 000 € en seize ans

Quatre causes cumulatives, toutes structurelles :

1. **Le seuil de savane à 0,80.** Le forex ne produit presque jamais un
   t-statistique de 0,8 sur un an. Le territoire était déclaré stérile la
   grande majorité du temps, et `fCible` forcé à zéro.
2. **La jauge d'entropie à 0,995.** Le forex est proche du bruit blanc sur ce
   test : la jauge y fonctionnait comme un interrupteur d'arrêt permanent, pas
   comme un filtre.
3. **Les frais de sélection à 0,10 %.** Sur l'EURUSD, 0,1 % par retournement,
   c'est 10 pips — dix fois le spread réel. À ce tarif virtuel, toutes les
   espèces rapides affichent une forme négative en permanence, meurent de faim,
   et la meute ne charge jamais.
4. **La conviction non normalisée** — la cause arithmétique principale. La
   conviction collective `|dir|` vaut typiquement 0,30. L'exposition valait donc
   `0,30 × levier` : la meute n'utilisait qu'environ **30 % du budget de risque**
   que l'homéostasie lui accordait. Cumulé au levier déjà 23 % trop bas (bug 2),
   le risque réellement pris était de l'ordre du quart du risque visé.

À quoi s'ajoutait le **filtre de tendance de fond**, qui interdisait la moitié
des sens sur une classe d'actifs sans aucune dérive structurelle.

### Ce que fait la G10

**Calibration automatique par classe d'actif** (`Classe d'actif` → activée par
défaut). La classe est détectée depuis `syminfo.type` et le ticker (forex,
métaux, indices, actions, crypto, énergie) et peut être forcée à la main. Le
forex et les métaux portent chacun leurs dix paramètres vitaux :

| Paramètre | Global (G9) | Forex | Métaux |
|---|---|---|---|
| Seuil de savane | 0,80 | **0,30** | **0,55** |
| Entropie maximale | 0,995 | **1,00** (désactivée) | **1,00** (désactivée) |
| Volatilité cible | 25 % | **20 %** | **28 %** |
| Exposition maximale | ×5 | **×10** | **×6** |
| Proie minimale | 0,20 | **0,08** | **0,15** |
| Frais de sélection | 0,10 % | **0,02 %** | **0,05 %** |
| Respect de la tendance de fond | oui | **non** | **non** |
| Plafond contrarien | 50 % | **70 %** | 50 % |
| Normalisation de la conviction | non | **oui** | **oui** |
| Eau (financement) | 3 %/an | **2 %/an** | 3 %/an |

Les classes **non calibrées** (indices, actions, crypto, énergie) utilisent les
paramètres globaux : le moteur qui a produit les résultats mesurés sur le
Nasdaq et NVIDIA est inchangé pour elles.

**Normalisation de la conviction.** `dir` est divisé par sa propre amplitude
moyenne sur un an, puis reborné à ±1. Le signe et le classement des espèces sont
strictement intacts — seule l'échelle change. La borne ±1 garantit que le
ciblage de volatilité reste le seul maître de la taille finale : on ne dépasse
jamais le levier autorisé, on cesse simplement de laisser les deux tiers du
budget inutilisés.

---

## 4. Reproduire exactement la G9

Une seule case : **`MODE HÉRITAGE G9`** (groupe « Mode héritage »). Cochée, elle
rétablit l'annualisation calendaire, les savanes jaugées sur 252 bougies, la
conviction brute et l'absence de calibration par classe. C'est le témoin de
contrôle : cochez-la pour retrouver vos backtests de la G9, décochez-la pour la
G10.

---

## 5. Avertissements

- **`commission_value` doit être une constante Pine** : elle ne peut pas être un
  paramètre. La valeur 0,05 % convient aux CFD indices et métaux. **Pour le
  forex comptant, éditez l'en-tête** : `commission_value = 0.01` et
  `slippage = 1`. Sinon le backtest facture ~5 pips aller-retour et aucune
  stratégie forex ne survit à ça.
- **L'or change de comportement** avec la calibration activée : il est classé
  « métaux » et hérite du seuil 0,55, des frais 0,05 % et de la conviction
  normalisée. Le backtest or 1D de la G9 (+89,7 %, PF 2,27) se retrouve en
  cochant le mode héritage. Comparez les deux avant de choisir.
- **L'eau (swap) reste de la comptabilité pure** : elle est affichée, jamais
  facturée aux ordres — Pine n'offre pas de mécanisme propre pour ça. Avec un
  levier forex de ×3, un swap de 2 %/an coûte ~6 %/an du capital : lisez la
  ligne « profit après eau » du tableau, pas seulement le profit net.
- **Aucun de ces chiffres n'est backtesté ici.** Les valeurs de calibration sont
  raisonnées à partir des coûts et des volatilités réels de chaque classe, pas
  optimisées sur historique. Passez-les au banc d'essai avant de les croire.
