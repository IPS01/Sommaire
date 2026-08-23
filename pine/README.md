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

## 3. Le désert : chasser quand même

Le score de savane mesure la **tendance de l'année**. Un actif qui fait des
allers-retours toute l'année score près de zéro — et c'est exactement le
terrain où les espèces **contrariennes** se nourrissent le mieux. Fermer le
territoire sur ce critère revient à interdire la chasse là où la proie abonde.

Le test EURUSD 1D l'a montré noir sur blanc : savane déclarée « stérile » à
0,12, et pourtant le **Renard à +2,6 pb par bougie avec 74 % de la meute**, les
contrariennes collées à leur plafond de 85 %. Toutes les espèces de tendance en
négatif, toutes les contrariennes en positif. La proie était là ; c'est la jauge
de tendance qui regardait ailleurs.

**Donc : dans le désert, la MEUTE chasse**, avec ses poids du moment — ceux qui
se nourrissent vraiment — à une fraction réglable de son exposition (100 % en
forex, 75 % en métaux). Aucune espèce n'est désignée d'avance. Si personne ne se
nourrit, les poids sont nuls, `dir` vaut zéro et la colonie s'abrite d'elle-même :
la sélection décide, pas le code.

### Ce que faisait la première mouture, et pourquoi elle a perdu 52 %

Elle confiait **toute** la colonie au Bip-Bip dès que la savane se fermait. Sur
l'EURUSD la savane est stérile en permanence : il a donc chassé seul dix ans, à
×15 de levier — un momentum 3 bougies, c'est-à-dire la seule famille dont
*toutes* les espèces sont en négatif sur cet actif. La meute qui savait chasser
regardait, bridée.

Le Bip-Bip reste dans le jeu comme **17e espèce** (génome de momentum
ultra-court, gain ×3 à ×3,5 : il ne dose pas, il s'engage). Il ne reçoit du
capital que si sa forme est positive, comme tout le monde. Désarmé il n'existe
pas du tout et le moteur redevient rigoureusement celui des seize espèces.

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
