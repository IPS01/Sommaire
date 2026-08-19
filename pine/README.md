# Le Roi de la Savane — Génération 10

Stratégie Pine Script® v6 (TradingView). Fichier : `Roi_de_la_Savane_G10.pine`.

---

## 1. Les réglages NVIDIA sont désormais les défauts

Le script se charge directement avec la configuration de production. Rien à
ressaisir.

| Réglage | G9 | **G10 (défaut)** |
|---|---|---|
| Part maximale des contrariennes | 50 % | **80 %** |
| Part du lion (hiérarchie) | 2 | **4** |
| Proie minimale | 0,20 | **0,35** |
| Savane propice à partir de | 0,80 | **0,99** |
| Volatilité cible | 25 % | **100 %** |
| Exposition maximale | ×5 | **×10** |
| Borne mortelle (perte max) | 30 % | **50 %** |
| Convalescence après choc | 10 bougies | **1 bougie** |
| Armer les abeilles | non | **oui** |
| Début du backtest | 2010 | **2016** |
| Pyramidage | 99 | **150** |
| Levier long / court | 20× (marge 5 %) | **50× (marge 2 %)** |
| Slippage | 2 ticks | **1 tick** |

Inchangés : mémoire 63, frais 0,1 %, bonus de niche 0,5, filtre de tendance de
fond actif, entropie 96 / 0,995, famine 150, soin parental 25, fenêtre de vol
63, zone morte 25 %, respiration 5, guérison 500, plancher 50 %, choc 4 σ,
eau 3 %/an, miroir 126, commission 0,05 %.

---

## 2. La liste déroulante « Profil de chasse »

Un profil est un jeu de réglages **verrouillé**, calibré pour un terrain.

- **Automatique (selon la classe d'actif)** — *défaut*. La classe est détectée
  (`syminfo.type` + ticker) et le profil correspondant s'applique : NVIDIA →
  actions, l'or → métaux, l'EURUSD → forex.
- **Actions & indices (réglage NVIDIA)**, **Or & métaux**, **Forex** — forcent
  un profil quelle que soit la classe.
- **Manuel (mes réglages ci-dessous)** — plus aucun profil : ce sont vos
  réglages qui commandent, tous sans exception. Comme les défauts *sont* le
  profil NVIDIA, passer en Manuel c'est partir de NVIDIA et modifier ce qu'on
  veut.

Les valeurs effectives du profil actif s'affichent en clair dans le tableau,
ligne **« Profil de chasse »** — lisez-les, puis recopiez-les en Manuel pour
les retoucher.

| Paramètre | Actions (NVIDIA) | Or & métaux | Forex |
|---|---|---|---|
| Seuil de savane | 0,99 | **0,45** | **0,25** |
| Entropie maximale | 0,995 | **1,00** (coupée) | **1,00** (coupée) |
| Volatilité cible | 100 % | 100 % | 100 % |
| Exposition maximale | ×10 | **×12** | **×15** |
| Proie minimale | 0,35 | **0,20** | **0,12** |
| Frais de sélection | 0,10 % | **0,04 %** | **0,015 %** |
| Filtre de tendance de fond | respecté | **libre** | **libre** |
| Plafond contrarien | 80 % | 80 % | **85 %** |
| Part du lion | ^4 | **^3,5** | **^3** |
| Normalisation de conviction | non | **oui** | **oui** |
| Respiration | 5 | **4** | **3** |
| Eau (financement) | 3 %/an | 3 %/an | **2 %/an** |
| **Bip-Bip** | au repos | **armé, 75 %** | **armé, 100 %** |

---

## 3. Le Bip-Bip : l'espèce du désert

Les seize autres espèces refusent de chasser quand le territoire est déclaré
stérile. **Ce refus était le premier verrou des 5 000 € en seize ans** : sur le
forex, le score de savane passe rarement le seuil, donc l'exposition tombait à
zéro et y restait.

Le Bip-Bip n'a pas ce scrupule. Ça monte il achète, ça descend il vend, et le
**gain de réactivité** (×3 à ×3,5) le fait saturer à ±1 dès un tiers
d'écart-type : il ne dose pas, il s'engage. Il a deux rôles :

1. **Membre de la meute** quand la savane est grasse — il concourt, se
   reproduit, meurt de faim et mute comme les autres.
2. **Chasseur solitaire du désert** — quand le score passe sous le seuil, la
   meute se couche et lui seul continue, à `bipDesert` % de l'exposition, sans
   proie minimale et (par défaut) sans filtre de tendance de fond.

Ce qui le tient malgré tout : **torpeur** (réduction progressive jusqu'à la
borne mortelle de 50 %), **bouclier immunitaire**, **plancher d'extinction
définitive** à 50 % du capital, **ordre souverain**. « Sans restriction » n'a
jamais voulu dire immortel — il s'agit de la survie de l'espèce.

**Désarmé, le Bip-Bip n'existe pas du tout** : il ne pèse ni dans l'écosystème
(`pEco` redevient une moyenne sur 16), ni dans la meute, ni dans le classement
de l'alpha. Le moteur est alors rigoureusement celui des seize espèces — c'est
pourquoi le profil NVIDIA, qui le laisse au repos, est identique à ce qu'il
était.

---

## 4. Bugs corrigés (hérités du diagnostic de la G9)

| # | Bug | Effet réel | Correction |
|---|---|---|---|
| 1 | Score des savanes = momentum sur **252 bougies** ÷ vol annualisée en **√252**, quelle que soit l'unité de temps | En hebdomadaire, 252 bougies = 4,8 ans : score gonflé ≈ 2,2× (≈ 4,6× en mensuel) | Vrai t-statistique sur une fenêtre d'un an réelle (252 / 52 / 12) |
| 2 | Volatilité annualisée en jours **calendaires** sur des bougies de **bourse** | Vol surestimée de 23 % → levier sous-dimensionné de 23 % en permanence | Annualisation en jours de bourse |
| 3 | Part des contrariennes = `(w6+w7+w8)/wTot` | ~20 % annoncés contre 45 % réels : Hyène, Serpent et Vautour oubliés | Les six contrariennes sont comptées |
| 4 | Tendance de fond figée à 252 bougies | Jugeait sur 5 ans en hebdomadaire, 21 ans en mensuel | Suit l'unité de temps |
| 5 | Une savane désactivée restait proposée en migration | Migration vers un territoire sans données | Écartée du classement, de la ruche et du tableau |
| 6 | `bestFit` recalculait la chaîne de `math.max` déjà tenue par `bestRef` | Aucun (redondance) | Une seule chaîne |
| 7 | Les 20 `request.security` évaluaient trois fois le même `ta.stdev` | Risque de dépassement du budget de calcul TradingView | Deux valeurs par appel |

---

## 5. Les vingt savanes, indépendantes

Chaque territoire porte sa propre ligne : `[✓ surveiller] [symbole] [seuil]`.
Un seuil à 0 hérite du seuil du profil. La savane locale a également le sien.

La migration classe par **excédent au-dessus du seuil propre**, pas par score
brut : un territoire exigeant à 1,10 pour un seuil de 1,20 est moins chassable
qu'un territoire tolérant à 0,45 pour un seuil de 0,30.

---

## 6. Avertissements

- **Volatilité cible 100 % et levier ×10 à ×15, c'est un régime de risque
  extrême.** La borne mortelle est à 50 % et le plancher d'extinction
  définitive à 50 % du capital : une mauvaise séquence peut éteindre la colonie
  pour de bon, sans retour possible dans le backtest. C'est le réglage demandé,
  il est appliqué tel quel — mais regardez le drawdown maximum du rapport de
  stratégie avant de le porter en réel.
- **`commission_value` doit être une constante Pine** : elle ne peut pas être
  un paramètre. Elle est à 0,05 % (valeur de vos captures). Pour le forex
  comptant, éditez l'en-tête : `commission_value = 0.01`. À 0,05 %, une
  respiration de 3 bougies sur un levier ×15 facture énormément.
- **L'or et le forex n'ont pas été backtestés ici.** Les valeurs des profils
  sont raisonnées à partir des coûts, volatilités et comportements réels de
  chaque classe, pas optimisées sur historique. Passez-les au banc d'essai.
- **L'eau (swap) reste de la comptabilité pure** : affichée, jamais facturée
  aux ordres — Pine n'offre pas de mécanisme propre. À ×10 de levier, 3 %/an de
  swap coûtent ~30 %/an du capital : lisez la ligne « profit après eau », pas
  seulement le profit net.
- **`MODE HÉRITAGE G9`** (groupe « Mode héritage ») rétablit les mathématiques
  de la G9 — annualisation calendaire, savanes en 252 bougies, conviction
  brute, Bip-Bip désarmé — et force le profil en Manuel. C'est le témoin de
  contrôle.
