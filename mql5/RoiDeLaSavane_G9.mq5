//+------------------------------------------------------------------+
//|                                          RoiDeLaSavane_G9.mq5    |
//|                        Copyright 2025, patrice_cloquet59         |
//|                                                                  |
//|   LE ROI DE LA SAVANE — Ecosysteme Darwinien Complet, G9         |
//|   Portage fidele du Pine Script v6 vers MQL5.                    |
//|                                                                  |
//|   Seize especes, vingt savanes, l'essaim de sentinelles,         |
//|   l'eau (swap), le miroir. Rien n'a ete supprime.                |
//|                                                                  |
//|   ORGANES NEUTRES PAR DEFAUT (comme en Pine) :                   |
//|     L'EAU     — comptabilite pure, n'agit jamais sur les ordres  |
//|     LE MIROIR — affichage et alerte seulement                    |
//|     LES TERMITES — affichage seulement                           |
//|     FOURMIS / ABEILLES / ANTICORPS — n'agissent que si armes     |
//|                                                                  |
//|   CORRECTIONS APPORTEES AU PORTAGE (documentees une par une      |
//|   la ou elles se trouvent dans le code) :                        |
//|     C1. Annualisation en bougies de BOURSE et non en secondes    |
//|         calendaires : le Pine divisait 31 536 000 par la duree   |
//|         d'une bougie, ce qui suppose que le marche cote 365      |
//|         jours sur 365. La volatilite en sortait ~23 % trop haute |
//|         en journalier, donc le levier ~23 % trop bas.            |
//|     C2. Fenetre d'un an REELLE selon l'unite de temps (252 en    |
//|         journalier, 52 en hebdomadaire, 12 en mensuel) au lieu   |
//|         de 252 bougies partout : en hebdomadaire, 252 bougies    |
//|         font cinq ans, pas un an.                                |
//|     C3. Part des contrariennes affichee : le Pine oubliait la    |
//|         Hyene, le Serpent et le Vautour dans le pourcentage      |
//|         affiche, alors que le plafond, lui, les comptait.        |
//|     C4. Plancher de torpeur : a torpeur nulle l'exposition tombe |
//|         a zero, l'equite se fige, le sommet memorise reste haut  |
//|         et la torpeur ne peut plus jamais se rouvrir. Un frein   |
//|         doit freiner, pas condamner. Reglable, defaut 15 %.      |
//|     C5. Dimensionnement en LOTS reels via la valeur du tick :    |
//|         seule maniere correcte de convertir une exposition en    |
//|         fraction du capital vers un volume MetaTrader.           |
//+------------------------------------------------------------------+
#property copyright "patrice_cloquet59"
#property link      ""
#property version   "9.00"
#property description "Le Roi de la Savane G9 — ecosysteme darwinien, 16 especes, 20 savanes"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| PARAMETRES                                                       |
//+------------------------------------------------------------------+
input group "=== Direction ==="
input bool   InpEnableLongs     = true;    // Autoriser les achats (long)
input bool   InpEnableShorts    = true;    // Autoriser les ventes (short)

input group "=== Selection naturelle ==="
input int    InpFitMem          = 63;      // Memoire de la forme (demi-vie, bougies)
input double InpFrais           = 0.1;     // Frais par unite d'exposition retournee (%)
input double InpDivBonus        = 0.5;     // Bonus de niche (recompense de la difference)
input double InpContMax         = 50.0;    // Part maximale des contrariennes (%)
input bool   InpRespectFond     = true;    // Ne jamais chasser contre la tendance de fond

input group "=== La meute (le lion) ==="
input double InpHierarchie      = 2.0;     // Part du lion (hierarchie de la meute)
input double InpProieMin        = 0.2;     // Proie minimale (conviction requise)

input group "=== La savane locale (le territoire) ==="
input double InpSavaneMin       = 0.8;     // Savane propice a partir d'un score de
input int    InpWEnt            = 96;      // Fenetre d'entropie de Shannon (bougies)
input double InpEntMax          = 0.995;   // Entropie maximale toleree (1 = desactivee)

input group "=== Les vingt savanes (migration) ==="
input string InpSym1  = "XAUUSD";   // Savane 1 (or)
input string InpSym2  = "XAGUSD";   // Savane 2 (argent)
input string InpSym3  = "USOIL";    // Savane 3 (petrole)
input string InpSym4  = "EURUSD";   // Savane 4 (euro-dollar)
input string InpSym5  = "GBPUSD";   // Savane 5 (livre-dollar)
input string InpSym6  = "USDJPY";   // Savane 6 (dollar-yen)
input string InpSym7  = "SPX500";   // Savane 7 (S&P 500)
input string InpSym8  = "NAS100";   // Savane 8 (Nasdaq 100)
input string InpSym9  = "BTCUSD";   // Savane 9 (bitcoin)
input string InpSym10 = "USDX";     // Savane 10 (indice dollar) — lu aussi par l'Aigle
input string InpSym11 = "AUDUSD";   // Savane 11 (dollar australien)
input string InpSym12 = "NZDUSD";   // Savane 12 (dollar neo-zelandais)
input string InpSym13 = "USDCAD";   // Savane 13 (dollar canadien)
input string InpSym14 = "USDCHF";   // Savane 14 (franc suisse)
input string InpSym15 = "EURJPY";   // Savane 15 (euro-yen)
input string InpSym16 = "XPTUSD";   // Savane 16 (platine)
input string InpSym17 = "XPDUSD";   // Savane 17 (palladium)
input string InpSym18 = "ETHUSD";   // Savane 18 (ethereum)
input string InpSym19 = "UKOIL";    // Savane 19 (brent)
input string InpSym20 = "EURGBP";   // Savane 20 (euro-livre)

input group "=== Evolution (croisement + mutation) ==="
input int    InpStarveMax       = 150;     // Famine mortelle (bougies en forme negative)
input double InpSoinParent      = 25.0;    // Soin parental (% de vigueur heritee)

input group "=== Homeostasie ==="
input double InpTargetVol       = 25.0;    // Volatilite cible du portefeuille (% par an)
input int    InpVolWin          = 63;      // Fenetre de mesure de volatilite (bougies)
input double InpExpoMax         = 5.0;     // Exposition maximale (x capital)
input double InpRebalPct        = 25.0;    // Zone morte de reequilibrage (% d'ecart)
input int    InpRespire         = 5;       // Respiration : reequilibrage toutes les X bougies

input group "=== Regulation thermique (survie) ==="
input double InpDdMax           = 30.0;    // Borne mortelle : perte max depuis le sommet (%)
input int    InpGuerJours       = 500;     // Guerison : demi-vie de la memoire du sommet (jours)
input double InpTorpeurMin      = 15.0;    // C4 : plancher de chasse en torpeur (%)
input double InpPlancher        = 50.0;    // Plancher de survie : extinction sous (% capital initial)

input group "=== Systeme immunitaire ==="
input double InpChocSeuil       = 4.0;     // Choc immunitaire (mouvement en ecarts-types)
input int    InpChocDuree       = 10;      // Convalescence apres choc (bougies)

input group "=== L'Homme (le souverain) ==="
input bool   InpPacteAbri       = false;   // ORDRE SOUVERAIN : toute la colonie a l'abri

input group "=== Les organes de la G9 ==="
input double InpSwapAnnuel      = 3.0;     // L'eau : cout de financement du levier (% par an)
input bool   InpFourmisOn       = false;   // Armer les fourmis (orage micro)
input bool   InpAbeillesOn      = false;   // Armer les abeilles (tempete systemique)
input bool   InpImmAcqOn        = false;   // Armer l'immunite acquise
input int    InpMiroirWin       = 126;     // Le miroir : fenetre du present (bougies)

input group "=== Corrections du portage ==="
input bool   InpCorrigerAnnu    = true;    // C1 : annualiser en bougies de bourse
input bool   InpCorrigerFenetre = true;    // C2 : fenetre d'un an selon l'unite de temps

input group "=== Execution ==="
input long   InpMagic           = 909090;  // Numero magique
input int    InpSlippage        = 20;      // Deviation maximale (points)
input bool   InpAfficherTableau = true;    // Afficher le poste de commandement
input bool   InpAlertesOn       = false;   // Emettre les alertes du souverain

//+------------------------------------------------------------------+
//| ETAT GLOBAL — l'equivalent des variables "var" de Pine           |
//+------------------------------------------------------------------+
CTrade         g_trade;
CPositionInfo  g_pos;

#define NESP  17          // especes 1..16 (indice 0 inutilise)
#define NSAV  21          // savanes  1..20 (indice 0 inutilise)
#define HIST  100         // profondeur d'historique pour les correlations

// --- genome (rythmes mutables) et etat civil
int    L[NESP];           // rythme de chaque espece
int    G[NESP];           // generation
int    AGE[NESP];         // age en bougies
double STV[NESP];         // compteur de famine
double FIT[NESP];         // forme (vigueur)
double SIGV[NESP];        // signal courant
double SIGP[NESP];        // signal de la bougie precedente
double PGAIN[NESP];       // gain virtuel de la bougie
double W[NESP];           // poids apres plafond contrarien

// --- historiques pour les correlations de niche
// Historique aplati : MQL5 refuse qu'on passe une ligne d'un tableau 2D a
// une fonction prenant "double &arr[]". On indexe donc a la main :
// l'espece e occupe les cases [e*HIST .. e*HIST+HIST-1].
double g_pHist[NESP * HIST];
double g_pEcoHist[HIST];
int    g_histN = 0;

// --- organes
double g_immun      = 0.0;
double g_anticorps  = 0.0;
double g_eqPeak     = 0.0;
bool   g_eteint     = false;
double g_extN       = 0.0;
double g_eauCum     = 0.0;
int    g_barIndex   = 0;
datetime g_lastBar  = 0;

// --- memoire des etats precedents (pour les alertes sur transition)
bool   g_prevSavaneOk   = false;
bool   g_prevFourmis    = false;
bool   g_prevAbeilles   = false;
bool   g_prevDecroche   = false;
bool   g_prevEteint     = false;
bool   g_prevCharge     = false;
double g_prevTorpeur    = 1.0;
double g_prevSig11      = 0.0;
double g_prevSig16      = 0.0;

// --- historique de l'equite pour le miroir (tampon circulaire borne :
//     un tableau qui grandit a chaque bougie finirait par saturer la memoire
//     d'un compte laisse tourner des annees).
#define EQMAX 1024
double g_eqHist[EQMAX];
int    g_eqHistN = 0;

// --- symboles des savanes
string g_sav[NSAV];

// --- valeurs affichees
string g_savBest = "";
double g_scSav[NSAV];
double g_moSav[NSAV];
double g_voSav[NSAV];

//+------------------------------------------------------------------+
//| Ecart-type de POPULATION (identique a ta.stdev de Pine)          |
//+------------------------------------------------------------------+
double StdevPop(const double &arr[], const int count)
  {
   if(count <= 1)
      return(0.0);
   double s = 0.0;
   for(int i = 0; i < count; i++)
      s += arr[i];
   const double m = s / count;
   double s2 = 0.0;
   for(int i = 0; i < count; i++)
      s2 += (arr[i] - m) * (arr[i] - m);
   const double v = s2 / count;
   return(v > 0.0 ? MathSqrt(v) : 0.0);
  }

//+------------------------------------------------------------------+
//| Correlation glissante (identique a ta.correlation de Pine)       |
//| Renvoie 1.0 si l'historique est trop court ou la variance nulle, |
//| exactement comme le nz(..., 1.0) du Pine.                        |
//+------------------------------------------------------------------+
double CorrelationPop(const double &x[], const double &y[], const int n)
  {
   if(n < 2)
      return(1.0);
   double sx = 0.0, sy = 0.0;
   for(int i = 0; i < n; i++)
     {
      sx += x[i];
      sy += y[i];
     }
   const double mx = sx / n;
   const double my = sy / n;
   double cxy = 0.0, cxx = 0.0, cyy = 0.0;
   for(int i = 0; i < n; i++)
     {
      const double dx = x[i] - mx;
      const double dy = y[i] - my;
      cxy += dx * dy;
      cxx += dx * dx;
      cyy += dy * dy;
     }
   if(cxx <= 1e-18 || cyy <= 1e-18)
      return(1.0);
   double r = cxy / MathSqrt(cxx * cyy);
   return(MathMax(-1.0, MathMin(1.0, r)));
  }

//+------------------------------------------------------------------+
//| Bornage a +/-1, l'equivalent du math.max(-1, math.min(1, x))     |
//+------------------------------------------------------------------+
double Clamp(const double x, const double lo = -1.0, const double hi = 1.0)
  {
   return(x < lo ? lo : (x > hi ? hi : x));
  }

//+------------------------------------------------------------------+
//| C2 : combien de bougies dans une annee, selon l'unite de temps ? |
//| Le Pine supposait 252 partout. En hebdomadaire, 252 bougies font |
//| cinq ans : le score de savane en sortait gonfle d'un facteur 2.  |
//+------------------------------------------------------------------+
int BarresParAn()
  {
   if(!InpCorrigerFenetre)
      return(252);
   const ENUM_TIMEFRAMES tf = Period();
   if(tf == PERIOD_MN1)
      return(12);
   if(tf == PERIOD_W1)
      return(52);
   if(tf == PERIOD_D1)
      return(252);
   const int sec = PeriodSeconds(tf);
   if(sec <= 0)
      return(252);
   // 252 seances de bourse par an, chacune de 24 h sur le forex
   const int n = (int)MathRound(252.0 * 86400.0 / sec);
   return(MathMax(2, n));
  }

//+------------------------------------------------------------------+
//| C1 : facteur d'annualisation de la volatilite.                   |
//| Le Pine faisait sqrt(31 536 000 / duree_bougie), c'est-a-dire    |
//| qu'il supposait 365 jours de cotation par an. Sur des bougies de |
//| bourse la volatilite ressortait ~23 % trop haute en journalier,  |
//| donc le levier ~23 % trop bas.                                   |
//+------------------------------------------------------------------+
double FacteurAnnualisation()
  {
   if(!InpCorrigerAnnu)
      return(31536000.0 / MathMax(60.0, (double)PeriodSeconds(Period())));
   return((double)BarresParAn());
  }

//+------------------------------------------------------------------+
//| Decalage d'un tableau-historique vers la droite, ajout en tete   |
//+------------------------------------------------------------------+
void PousserHist(double &arr[], const int taille, const double val)
  {
   for(int i = taille - 1; i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0] = val;
  }

//+------------------------------------------------------------------+
//| Le roi jauge une savane voisine : tendance sur un an et bruit.   |
//| Renvoie false si le symbole n'est pas disponible — la savane est |
//| alors ignoree au lieu de polluer le classement avec des zeros.   |
//+------------------------------------------------------------------+
bool JaugerSavane(const string sym, const int lbAn, double &mom, double &vol)
  {
   mom = 0.0;
   vol = 0.0;
   if(StringLen(sym) == 0)
      return(false);
   if(!SymbolSelect(sym, true))
      return(false);

   const int besoin = lbAn + 70;
   double cl[];
   ArraySetAsSeries(cl, true);
   const int got = CopyClose(sym, Period(), 0, besoin, cl);
   if(got < besoin)
      return(false);
   if(cl[lbAn] <= 0.0 || cl[0] <= 0.0)
      return(false);

   mom = cl[0] / cl[lbAn] - 1.0;

   // bruit : ecart-type des rendements log sur 63 bougies, annualise
   double r[63];
   for(int i = 0; i < 63; i++)
     {
      if(cl[i + 1] <= 0.0)
         return(false);
      r[i] = MathLog(cl[i] / cl[i + 1]);
     }
   vol = StdevPop(r, 63) * MathSqrt(FacteurAnnualisation());
   return(true);
  }

//+------------------------------------------------------------------+
//| Valeur notionnelle d'un lot, exprimee dans la devise du compte.  |
//| C5 : c'est la seule conversion correcte d'une exposition en      |
//| fraction du capital vers un volume MetaTrader. On passe par la   |
//| valeur du tick, qui integre deja toutes les conversions de       |
//| devises faites par le courtier.                                  |
//+------------------------------------------------------------------+
double NotionnelParLot(const string sym, const double prix)
  {
   const double tickVal  = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   const double tickSize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal > 0.0 && tickSize > 0.0 && prix > 0.0)
      return(prix / tickSize * tickVal);

   // repli : taille de contrat brute, valable quand le tick est absent
   const double contrat = SymbolInfoDouble(sym, SYMBOL_TRADE_CONTRACT_SIZE);
   return(contrat > 0.0 ? contrat * prix : 0.0);
  }

//+------------------------------------------------------------------+
//| Position nette courante en lots (signee), toutes positions du    |
//| meme magique confondues. Fonctionne en netting comme en hedging. |
//+------------------------------------------------------------------+
double PositionNetteLots()
  {
   double net = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!g_pos.SelectByIndex(i))
         continue;
      if(g_pos.Symbol() != _Symbol)
         continue;
      if(g_pos.Magic() != InpMagic)
         continue;
      net += (g_pos.PositionType() == POSITION_TYPE_BUY ? g_pos.Volume() : -g_pos.Volume());
     }
   return(net);
  }

//+------------------------------------------------------------------+
//| Normalisation d'un volume aux contraintes du symbole             |
//+------------------------------------------------------------------+
double NormaliserLots(const double lots)
  {
   const double pas  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   const double mini = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double maxi = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(pas <= 0.0)
      return(lots);
   double v = MathFloor(lots / pas + 0.5) * pas;
   v = MathMax(mini, MathMin(maxi, v));
   // arrondi propre au pas pour eviter les rejets du serveur
   const int dec = (int)MathMax(0, MathRound(-MathLog10(pas)));
   return(NormalizeDouble(v, dec));
  }

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   // --- genome initial, identique aux "var" du Pine
   for(int i = 1; i < NESP; i++)
     {
      L[i]    = 0;
      G[i]    = 1;
      AGE[i]  = 0;
      STV[i]  = 0.0;
      FIT[i]  = 0.0;
      SIGV[i] = 0.0;
      SIGP[i] = 0.0;
      PGAIN[i] = 0.0;
      W[i]    = 0.0;
      for(int k = 0; k < HIST; k++)
         g_pHist[i * HIST + k] = 0.0;
     }
   L[1] = 10;   L[2] = 21;   L[3] = 63;   L[4] = 126;  L[5] = 252;
   L[6] = 2;    L[7] = 5;    L[8] = 10;
   L[9] = 0;    L[10] = 0;   L[11] = 0;                 // fossiles et charognard : rythme fige
   L[12] = 8;   L[13] = 30;  L[14] = 150; L[15] = 3;
   L[16] = 0;                                            // Vautour : rythme fige

   for(int k = 0; k < HIST; k++)
      g_pEcoHist[k] = 0.0;
   g_histN = 0;

   // --- les vingt savanes
   g_sav[1] = InpSym1;   g_sav[2] = InpSym2;   g_sav[3] = InpSym3;   g_sav[4] = InpSym4;
   g_sav[5] = InpSym5;   g_sav[6] = InpSym6;   g_sav[7] = InpSym7;   g_sav[8] = InpSym8;
   g_sav[9] = InpSym9;   g_sav[10] = InpSym10; g_sav[11] = InpSym11; g_sav[12] = InpSym12;
   g_sav[13] = InpSym13; g_sav[14] = InpSym14; g_sav[15] = InpSym15; g_sav[16] = InpSym16;
   g_sav[17] = InpSym17; g_sav[18] = InpSym18; g_sav[19] = InpSym19; g_sav[20] = InpSym20;
   for(int i = 1; i < NSAV; i++)
     {
      if(StringLen(g_sav[i]) > 0)
         SymbolSelect(g_sav[i], true);
      g_scSav[i] = 0.0;
      g_moSav[i] = 0.0;
      g_voSav[i] = 0.0;
     }

   ArrayInitialize(g_eqHist, 0.0);
   g_eqHistN = 0;
   g_eqPeak  = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastBar = 0;
   g_barIndex = 0;

   Print("Roi de la Savane G9 — initialise. Barres par an : ", BarresParAn(),
         " | annualisation : ", DoubleToString(FacteurAnnualisation(), 1));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }

//+------------------------------------------------------------------+
//| OnTick — tout le moteur tourne UNE FOIS PAR BOUGIE CLOTUREE,     |
//| ce qui reproduit exactement le comportement du Pine compile avec |
//| calc_on_every_tick = false et process_orders_on_close = true.     |
//+------------------------------------------------------------------+
void OnTick()
  {
   const datetime tBar = iTime(_Symbol, Period(), 0);
   if(tBar == g_lastBar)
      return;                       // pas de nouvelle bougie : on ne fait rien
   g_lastBar = tBar;
   g_barIndex++;

   TraiterBougie();
  }

//+------------------------------------------------------------------+
//| Le corps du moteur, execute a chaque bougie confirmee            |
//+------------------------------------------------------------------+
void TraiterBougie()
  {
   const int lbAn  = BarresParAn();
   const double annuF = FacteurAnnualisation();

   //--- il faut assez d'histoire pour la plus longue espece
   const int besoin = MathMax(lbAn, 400) + 60;
   double cl[], hi[], lo[], op[];
   ArraySetAsSeries(cl, true);
   ArraySetAsSeries(hi, true);
   ArraySetAsSeries(lo, true);
   ArraySetAsSeries(op, true);
   if(CopyClose(_Symbol, Period(), 0, besoin, cl) < besoin)
      return;
   if(CopyHigh(_Symbol, Period(), 0, 60, hi) < 60)
      return;
   if(CopyLow(_Symbol, Period(), 0, 60, lo) < 60)
      return;
   if(CopyOpen(_Symbol, Period(), 0, 60, op) < 60)
      return;

   //--- indice 1 = derniere bougie CLOTUREE (indice 0 = bougie en cours)
   const double close0 = cl[1];
   if(close0 <= 0.0)
      return;

   //=================================================================
   // LE TERRAIN DE CHASSE : MESURES DE BASE
   //=================================================================
   double v[50];
   for(int i = 0; i < 50; i++)
      v[i] = MathLog(cl[1 + i] / cl[2 + i]);
   const double vNow  = v[0];
   const double sdBar = StdevPop(v, 50);

   double vPrev[50];
   for(int i = 0; i < 50; i++)
      vPrev[i] = MathLog(cl[2 + i] / cl[3 + i]);
   const double sdBarPrev = StdevPop(vPrev, 50);

   const double lamF  = MathPow(0.5, 1.0 / MathMax(1, InpFitMem));
   const double fr    = InpFrais / 100.0;
   const bool   ready = (g_barIndex > 300) && (Bars(_Symbol, Period()) > besoin);

   //=================================================================
   // L'INSTINCT GRADUE : conviction = mouvement / bruit, bornee a +/-1
   //=================================================================
   for(int i = 1; i < NESP; i++)
      SIGP[i] = SIGV[i];

   // --- les huit especes mutables de la premiere meute
   int lst1[8] = {1, 2, 3, 4, 5, 6, 7, 8};
   for(int k = 0; k < 8; k++)
     {
      const int e = lst1[k];
      const int lb = MathMax(1, L[e]);
      const double d = sdBar * MathSqrt((double)lb);
      double s = 0.0;
      if(d > 0.0 && cl[1 + lb] > 0.0)
         s = Clamp(MathLog(cl[1] / cl[1 + lb]) / d);
      // 6, 7, 8 sont contrariennes : elles inversent le signe
      SIGV[e] = (e >= 6 && e <= 8) ? -s : s;
     }

   // --- L'AIGLE (9) : il lit l'indice dollar, pas le symbole courant
   {
      double sa = 0.0;
      double ad[];
      ArraySetAsSeries(ad, true);
      if(StringLen(g_sav[10]) > 0 && SymbolSelect(g_sav[10], true) &&
         CopyClose(g_sav[10], Period(), 0, lbAn + 60, ad) >= lbAn + 60)
        {
         double va[50];
         bool ok = true;
         for(int i = 0; i < 50 && ok; i++)
           {
            if(ad[2 + i] <= 0.0)
               ok = false;
            else
               va[i] = MathLog(ad[1 + i] / ad[2 + i]);
           }
         if(ok && ad[1 + lbAn] > 0.0)
           {
            const double dA = StdevPop(va, 50) * MathSqrt((double)lbAn);
            if(dA > 0.0)
               sa = -Clamp(MathLog(ad[1] / ad[1 + lbAn]) / dA);
           }
        }
      SIGV[9] = sa;
   }

   // --- LE CROCODILE (10) : embuscade dans le canal des 55 bougies
   {
      double hC = cl[1], lC = cl[1];
      for(int i = 1; i <= 55; i++)
        {
         hC = MathMax(hC, cl[i]);
         lC = MathMin(lC, cl[i]);
        }
      SIGV[10] = (hC - lC) > 0.0 ? Clamp((cl[1] - (hC + lC) / 2.0) / ((hC - lC) / 2.0)) : 0.0;
   }

   // --- LA HYENE (11) : charognard sur capitulation a 20 bougies
   {
      double hH = cl[1];
      for(int i = 1; i <= 20; i++)
         hH = MathMax(hH, cl[i]);
      const double chuteH = (sdBar > 0.0 && hH > 0.0)
                            ? MathLog(cl[1] / hH) / (sdBar * MathSqrt(20.0)) : 0.0;
      SIGV[11] = Clamp((-chuteH - 1.5) / 1.5, 0.0, 1.0);
   }

   // --- LA GRANDE MEUTE : quatre chasseurs mutables de plus
   int lst2[4] = {12, 13, 14, 15};
   for(int k = 0; k < 4; k++)
     {
      const int e = lst2[k];
      const int lb = MathMax(1, L[e]);
      const double d = sdBar * MathSqrt((double)lb);
      double s = 0.0;
      if(d > 0.0 && cl[1 + lb] > 0.0)
         s = Clamp(MathLog(cl[1] / cl[1 + lb]) / d);
      SIGV[e] = (e == 15) ? -s : s;     // le Serpent est contrarien
     }

   // --- LE VAUTOUR (16) : les grands charniers a 40 bougies
   {
      double hV = cl[1];
      for(int i = 1; i <= 40; i++)
         hV = MathMax(hV, cl[i]);
      const double chuteV = (sdBar > 0.0 && hV > 0.0)
                            ? MathLog(cl[1] / hV) / (sdBar * MathSqrt(40.0)) : 0.0;
      SIGV[16] = Clamp((-chuteV - 2.5) / 2.0, 0.0, 1.0);
   }

   //=================================================================
   // LA CHASSE VIRTUELLE : gain de chaque espece, frais deduits
   //=================================================================
   double pEco = 0.0;
   for(int i = 1; i <= 16; i++)
     {
      PGAIN[i] = SIGP[i] * vNow - MathAbs(SIGV[i] - SIGP[i]) * 0.5 * fr;
      pEco += PGAIN[i];
     }
   pEco /= 16.0;

   //=================================================================
   // LA FORME : vigueur de chaque espece (memoire exponentielle)
   //=================================================================
   for(int i = 1; i <= 16; i++)
      FIT[i] = lamF * FIT[i] + (1.0 - lamF) * PGAIN[i];

   //=================================================================
   // NICHES ECOLOGIQUES : la difference est recompensee
   //=================================================================
   for(int i = 1; i <= 16; i++)
     {
      const int base = i * HIST;
      for(int k = HIST - 1; k > 0; k--)
         g_pHist[base + k] = g_pHist[base + k - 1];
      g_pHist[base] = PGAIN[i];
     }
   PousserHist(g_pEcoHist, HIST, pEco);
   if(g_histN < HIST)
      g_histN++;

   double Q[NESP];
   for(int i = 1; i <= 16; i++)
     {
      if(g_histN < HIST)
         Q[i] = 1.0;
      else
        {
         double xi[HIST], ye[HIST];
         const int base = i * HIST;
         for(int k = 0; k < HIST; k++)
           {
            xi[k] = g_pHist[base + k];
            ye[k] = g_pEcoHist[k];
           }
         Q[i] = CorrelationPop(xi, ye, HIST);
        }
     }

   //=================================================================
   // LA MEUTE : le lion mange le premier (forme ^ hierarchie)
   //=================================================================
   double bestFit = FIT[1];
   int    bestE   = 1;
   for(int i = 2; i <= 16; i++)
      if(FIT[i] > bestFit)
        {
         bestFit = FIT[i];
         bestE = i;
        }
   const double fitRef = MathMax(bestFit, 1e-12);

   double Wr[NESP];
   for(int i = 1; i <= 16; i++)
      Wr[i] = MathPow(MathMax(0.0, FIT[i]) / fitRef, InpHierarchie)
              * (1.0 + InpDivBonus * (1.0 - Q[i]));

   // --- PLAFOND DES CONTRARIENNES : 6, 7, 8, 11, 15, 16
   //     (C3 : la Hyene, le Serpent et le Vautour en font bien partie,
   //      le Pine les oubliait dans le POURCENTAGE AFFICHE alors que
   //      le plafond, lui, les comptait deja.)
   int contra[6] = {6, 7, 8, 11, 15, 16};
   double wT = 0.0, wCr = 0.0;
   for(int i = 1; i <= 16; i++)
     {
      bool estContra = false;
      for(int k = 0; k < 6; k++)
         if(contra[k] == i)
            estContra = true;
      if(estContra)
         wCr += Wr[i];
      else
         wT += Wr[i];
     }
   const double cC = InpContMax / 100.0;
   double scaleC = 1.0;
   if(wCr > 0.0 && cC < 1.0)
      scaleC = MathMin(1.0, cC * wT / MathMax(1e-12, (1.0 - cC) * wCr));

   double wTot = 0.0, wContraTot = 0.0;
   for(int i = 1; i <= 16; i++)
     {
      bool estContra = false;
      for(int k = 0; k < 6; k++)
         if(contra[k] == i)
            estContra = true;
      W[i] = estContra ? Wr[i] * scaleC : Wr[i];
      wTot += W[i];
      if(estContra)
         wContraTot += W[i];
     }

   double dir = 0.0;
   if(wTot > 0.0)
     {
      for(int i = 1; i <= 16; i++)
         dir += W[i] * SIGV[i];
      dir /= wTot;
     }

   int vivantes = 0;
   for(int i = 1; i <= 16; i++)
      if(W[i] > 0.0)
         vivantes++;

   //=================================================================
   // EVOLUTION : famine, mort, croisement des deux meilleures, mutation
   //=================================================================
   int LFIXE[NESP];
   for(int i = 1; i <= 16; i++)
      LFIXE[i] = L[i];
   LFIXE[9] = lbAn;   LFIXE[10] = 55;   LFIXE[11] = 20;   LFIXE[16] = 40;

   double scndFit = -1e9;
   int    scndE   = bestE;
   for(int i = 1; i <= 16; i++)
      if(i != bestE && FIT[i] > scndFit)
        {
         scndFit = FIT[i];
         scndE = i;
        }
   const double croise   = MathSqrt((double)MathMax(2, LFIXE[bestE]) * (double)MathMax(2, LFIXE[scndE]));
   const double heritage = MathMax(bestFit, 0.0) * InpSoinParent / 100.0;

   int mutables[12] = {1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15};
   int bmin[12] = {5, 15, 40, 90, 180, 2, 4, 8, 5, 25, 120, 2};
   int bmax[12] = {20, 40, 100, 200, 400, 6, 12, 30, 15, 60, 300, 8};
   double bmul[12] = {1.0, 1.13, 0.87, 1.29, 0.71, 0.2, 0.3, 0.4, 0.35, 0.55, 1.5, 0.15};

   const double fmut = 0.5 + MathAbs(MathSin((double)g_barIndex * 12.9898)) * 1.0;
   bool naissance = false;

   for(int k = 0; k < 12; k++)
     {
      const int e = mutables[k];
      STV[e] = (FIT[e] <= 0.0) ? STV[e] + 1.0 : 0.0;
      if(STV[e] > InpStarveMax)
        {
         const int nouveau = (int)MathRound(croise * fmut * bmul[k]);
         L[e]   = MathMax(bmin[k], MathMin(bmax[k], nouveau));
         FIT[e] = heritage;
         STV[e] = 0.0;
         G[e]   = G[e] + 1;
         AGE[e] = 0;
         naissance = true;
        }
      else
         AGE[e] = AGE[e] + 1;
     }

   //=================================================================
   // RE-ENSEMENCEMENT : apres 100 bougies d'extinction, les spores
   //=================================================================
   g_extN = (ready && wTot == 0.0) ? g_extN + 1.0 : 0.0;
   if(g_extN > 100.0)
     {
      L[1] = 10;  L[2] = 21;  L[3] = 63;  L[4] = 126; L[5] = 252;
      L[6] = 2;   L[7] = 5;   L[8] = 8;
      L[12] = 8;  L[13] = 30; L[14] = 150; L[15] = 3;
      for(int i = 1; i <= 16; i++)
        {
         FIT[i] = 0.0;
         STV[i] = 0.0;
        }
      g_extN = 0.0;
      naissance = true;
     }

   int naissances = 0;
   for(int k = 0; k < 12; k++)
      naissances += G[mutables[k]] - 1;
   int doyenne = 0;
   for(int k = 0; k < 12; k++)
      doyenne = MathMax(doyenne, AGE[mutables[k]]);

   //=================================================================
   // SYSTEME IMMUNITAIRE : bouclier apres choc anormal
   //=================================================================
   const bool choc = ready && (sdBarPrev > 0.0)
                     && (MathAbs(vNow) > InpChocSeuil * sdBarPrev);
   g_immun = choc ? (double)InpChocDuree : MathMax(0.0, g_immun - 1.0);
   const double bouclier = (g_immun > 0.0) ? 0.5 : 1.0;

   // --- IMMUNITE ACQUISE : la memoire des chocs, demi-vie d'un an
   const double lamA = MathPow(0.5, 1.0 / (double)lbAn);
   g_anticorps = g_anticorps * lamA + (choc ? 1.0 : 0.0);
   const double immAcqF = MathMax(0.5, 1.0 / (1.0 + 0.25 * g_anticorps));

   //=================================================================
   // HOMEOSTASIE : ciblage de volatilite
   //=================================================================
   double vv[];
   ArrayResize(vv, InpVolWin);
   for(int i = 0; i < InpVolWin; i++)
      vv[i] = MathLog(cl[1 + i] / cl[2 + i]);
   const double sigA   = StdevPop(vv, InpVolWin) * MathSqrt(annuF);
   const double levVol = (sigA > 0.0) ? MathMin(InpExpoMax, (InpTargetVol / 100.0) / sigA) : 0.0;

   //=================================================================
   // REGULATION THERMIQUE : torpeur, hibernation, plancher de survie
   //=================================================================
   const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   const double guerison = MathPow(0.5, (double)PeriodSeconds(Period())
                                   / ((double)InpGuerJours * 86400.0));
   if(g_eqPeak <= 0.0)
      g_eqPeak = equity;
   g_eqPeak = MathMax(g_eqPeak * guerison, equity);
   const double dd = (g_eqPeak > 0.0) ? 1.0 - equity / g_eqPeak : 0.0;

   // C4 : PLANCHER DE TORPEUR. A torpeur nulle l'exposition tombe a zero,
   // l'equite se fige, le sommet memorise reste haut et la torpeur ne peut
   // plus jamais se rouvrir : le frein devient une condamnation. Le Pine
   // s'en sortait grace a l'oubli du sommet (guerJours), mais si l'oubli
   // est regle trop lentement le verrou se referme quand meme.
   const double torpeurLibre = MathMax(0.0, MathMin(1.0, 1.0 - dd / (InpDdMax / 100.0)));
   const double torpeur = MathMax(InpTorpeurMin / 100.0, torpeurLibre);

   if(ready && equity < InpPlancher / 100.0 * AccountInfoDouble(ACCOUNT_BALANCE))
      g_eteint = true;

   //=================================================================
   // LA SAVANE LOCALE : le roi jauge son territoire avant de chasser
   //=================================================================
   const double mom252L   = (cl[1 + lbAn] > 0.0) ? cl[1] / cl[1 + lbAn] - 1.0 : 0.0;
   const double scoreLocal = (sigA > 0.0) ? MathAbs(mom252L) / sigA : 0.0;

   // --- entropie de Shannon sur les motifs de trois bougies
   int cnt[8];
   ArrayInitialize(cnt, 0);
   for(int i = 0; i < InpWEnt; i++)
     {
      const int b0 = (cl[1 + i] > cl[2 + i]) ? 1 : 0;
      const int b1 = (cl[2 + i] > cl[3 + i]) ? 2 : 0;
      const int b2 = (cl[3 + i] > cl[4 + i]) ? 4 : 0;
      cnt[b0 + b1 + b2]++;
     }
   double tot = 0.0;
   for(int i = 0; i < 8; i++)
      tot += (double)cnt[i];
   double ent = 1.0;
   if(tot > 0.0)
     {
      double s = 0.0;
      for(int i = 0; i < 8; i++)
         if(cnt[i] > 0)
           {
            const double pr = (double)cnt[i] / tot;
            s += pr * MathLog(pr);
           }
      ent = -s / MathLog(2.0) / 3.0;
     }
   const bool ordreOk  = (ent <= InpEntMax);
   const bool savaneOk = ((InpSavaneMin <= 0.0) || (scoreLocal >= InpSavaneMin)) && ordreOk;

   //=================================================================
   // LES VINGT SAVANES : le roi scrute les territoires voisins
   //=================================================================
   double scBest = -1e9;
   g_savBest = "aucune savane disponible";
   double sommeVol = 0.0;
   int    nVol = 0;
   for(int i = 1; i < NSAV; i++)
     {
      double mo = 0.0, vo = 0.0;
      if(JaugerSavane(g_sav[i], lbAn, mo, vo))
        {
         g_moSav[i] = mo;
         g_voSav[i] = vo;
         g_scSav[i] = (vo > 0.0) ? MathAbs(mo) / vo : 0.0;
         sommeVol += vo;
         nVol++;
         if(g_scSav[i] > scBest)
           {
            scBest = g_scSav[i];
            g_savBest = g_sav[i];
           }
        }
      else
        {
         g_moSav[i] = 0.0;
         g_voSav[i] = 0.0;
         g_scSav[i] = 0.0;
        }
     }

   //=================================================================
   // L'ESSAIM : les insectes sentinelles. Ils ne chassent jamais.
   //=================================================================
   double v10[10], v100[100];
   for(int i = 0; i < 10; i++)
      v10[i] = MathLog(cl[1 + i] / cl[2 + i]);
   for(int i = 0; i < 100; i++)
      v100[i] = MathLog(cl[1 + i] / cl[2 + i]);
   const double sdCourt = StdevPop(v10, 10);
   const double sdLong  = StdevPop(v100, 100);
   const double orage   = (sdLong > 0.0) ? sdCourt / sdLong : 1.0;
   const bool fourmisAlerte = ready && (orage > 1.5);

   const double ruche = (nVol > 0) ? sommeVol / nVol : 0.0;
   static double s_rucheHist[252];
   static int    s_rucheN = 0;
   PousserHist(s_rucheHist, 252, ruche);
   if(s_rucheN < 252)
      s_rucheN++;
   double rucheMoy = 0.0;
   for(int i = 0; i < s_rucheN; i++)
      rucheMoy += s_rucheHist[i];
   rucheMoy = (s_rucheN > 0) ? rucheMoy / s_rucheN : 0.0;
   const bool abeillesAlerte = ready && (s_rucheN >= 252) && (rucheMoy > 0.0)
                               && (ruche > 1.4 * rucheMoy);

   double meches = 0.0;
   for(int i = 1; i <= 50; i++)
     {
      const double amp = MathMax(hi[i] - lo[i], SymbolInfoDouble(_Symbol, SYMBOL_POINT));
      meches += (hi[i] - lo[i] - MathAbs(cl[i] - op[i])) / amp;
     }
   meches /= 50.0;
   const bool solTraitre = (meches > 0.55);

   //=================================================================
   // TENDANCE DE FOND : on ne chasse jamais contre la derive longue
   //=================================================================
   const int fond = (cl[1 + lbAn] > 0.0 && cl[1] > cl[1 + lbAn]) ? 1 : -1;

   //=================================================================
   // LA CHARGE DU LION : decision finale
   //=================================================================
   static double s_dirHist[21];
   PousserHist(s_dirHist, 21, dir);
   const int nResp = MathMax(1, MathMin(21, InpRespire));
   double dirS = 0.0;
   for(int i = 0; i < nResp; i++)
      dirS += s_dirHist[i];
   dirS /= nResp;

   const double dirChasse = (MathAbs(dirS) >= InpProieMin) ? dirS : 0.0;

   double fCible = (ready && !g_eteint)
                   ? dirChasse * levVol * torpeur * bouclier : 0.0;
   if(!InpEnableLongs && fCible > 0.0)
      fCible = 0.0;
   if(!InpEnableShorts && fCible < 0.0)
      fCible = 0.0;
   if(InpRespectFond && fCible * fond < 0.0)
      fCible = 0.0;
   if(!savaneOk)
      fCible = 0.0;
   if(InpPacteAbri)
      fCible = 0.0;
   // L'essaim et les anticorps ne mordent que si le souverain les a armes :
   // par defaut ces trois lignes ne changent rien (garantie du Pine).
   if(InpFourmisOn && fourmisAlerte)
      fCible *= 0.7;
   if(InpAbeillesOn && abeillesAlerte)
      fCible *= 0.7;
   if(InpImmAcqOn)
      fCible *= immAcqF;

   //=================================================================
   // L'EAU : le loyer du levier. Comptabilite pure, aucun ordre.
   //=================================================================
   const double notLot = NotionnelParLot(_Symbol, close0);
   const double posLots = PositionNetteLots();
   const double expoActu = (equity > 0.0 && notLot > 0.0)
                           ? posLots * notLot / equity : 0.0;
   g_eauCum += MathAbs(expoActu) * (InpSwapAnnuel / 100.0)
               * ((double)PeriodSeconds(Period()) / 31536000.0) * equity;

   //=================================================================
   // LE MIROIR : le present tient-il la promesse du passe ?
   //=================================================================
   // tampon circulaire : la case 0 est toujours la bougie courante
   for(int i = EQMAX - 1; i > 0; i--)
      g_eqHist[i] = g_eqHist[i - 1];
   g_eqHist[0] = equity;
   if(g_eqHistN < EQMAX)
      g_eqHistN++;
   const double capital0 = AccountInfoDouble(ACCOUNT_BALANCE) - GetProfitFerme();
   double retPresent = 0.0;
   if(g_eqHistN > InpMiroirWin && InpMiroirWin < EQMAX)
     {
      const double ref = MathMax(g_eqHist[InpMiroirWin], 1e-9);
      retPresent = equity / ref - 1.0;
     }
   const double nFen = MathMax(1.0, ((double)g_barIndex - 300.0) / (double)InpMiroirWin);
   const double base0 = MathMax(capital0, 1e-9);
   const double retRythme = MathPow(MathMax(equity / base0, 1e-9), 1.0 / nFen) - 1.0;
   const bool decroche = ready && (HistoryTradesCount() > 10)
                         && (retPresent < retRythme - 0.10);

   //=================================================================
   // REEQUILIBRAGE AVEC ZONE MORTE ET RESPIRATION
   //=================================================================
   const bool souffle = (g_barIndex % nResp == 0);
   if(souffle && notLot > 0.0)
     {
      const double lotsCible = fCible * equity / notLot;
      const double diffLots  = lotsCible - posLots;
      const double pasMin    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      const double seuilLots = MathMax(MathMax(InpRebalPct / 100.0 * MathAbs(lotsCible),
                                               0.02 * equity / notLot), pasMin);
      if(MathAbs(diffLots) > seuilLots)
         AjusterPosition(diffLots, fCible);
     }

   //=================================================================
   // LES ALERTES DU SOUVERAIN
   //=================================================================
   if(InpAlertesOn)
     {
      if(naissance)
         Alert("Roi : naissance d'une espece");
      if(choc)
         Alert("Roi : choc immunitaire — bouclier leve");
      if(savaneOk && !g_prevSavaneOk)
         Alert("Roi : la savane redevient propice");
      if(!savaneOk && g_prevSavaneOk)
         Alert("Roi : la savane devient sterile — migration : " + g_savBest);
      if(torpeurLibre < 0.5 && g_prevTorpeur >= 0.5)
         Alert("Roi : torpeur profonde");
      if(torpeurLibre <= 0.0 && g_prevTorpeur > 0.0)
         Alert("Roi : hibernation — borne mortelle atteinte");
      if(g_eteint && !g_prevEteint)
         Alert("Roi : EXTINCTION DEFINITIVE — plancher de survie franchi");
      const bool charge = (MathAbs(dirS) >= InpProieMin);
      if(charge && !g_prevCharge)
         Alert("Roi : la meute charge");
      if(!charge && g_prevCharge)
         Alert("Roi : retour a l'affut");
      if(SIGV[11] > 0.0 && g_prevSig11 <= 0.0)
         Alert("Roi : festin de la Hyene");
      if(SIGV[16] > 0.0 && g_prevSig16 <= 0.0)
         Alert("Roi : le Vautour descend");
      if(fourmisAlerte && !g_prevFourmis)
         Alert("Roi : les fourmis sentent l'orage");
      if(abeillesAlerte && !g_prevAbeilles)
         Alert("Roi : les abeilles fuient la ruche");
      if(decroche && !g_prevDecroche)
         Alert("Roi : le miroir decroche");
      g_prevCharge = charge;
     }
   g_prevSavaneOk = savaneOk;
   g_prevFourmis  = fourmisAlerte;
   g_prevAbeilles = abeillesAlerte;
   g_prevDecroche = decroche;
   g_prevEteint   = g_eteint;
   g_prevTorpeur  = torpeurLibre;
   g_prevSig11    = SIGV[11];
   g_prevSig16    = SIGV[16];

   //=================================================================
   // LE POSTE DE COMMANDEMENT
   //=================================================================
   if(InpAfficherTableau)
      AfficherTableau(ready, savaneOk, vivantes, naissances, doyenne, bestE, bestFit,
                      dir, dirS, fCible, expoActu, sigA, levVol, dd, torpeur, torpeurLibre,
                      scoreLocal, ent, fond, wTot, wContraTot, orage, ruche, rucheMoy,
                      meches, solTraitre, fourmisAlerte, abeillesAlerte, decroche,
                      retPresent, retRythme, lbAn, choc);
  }

//+------------------------------------------------------------------+
//| Ajuste la position vers la cible, en un seul ordre net.          |
//| Gere le netting comme le hedging : on solde d'abord ce qui va    |
//| a contre-sens, puis on ouvre le complement.                      |
//+------------------------------------------------------------------+
void AjusterPosition(const double diffLots, const double fCible)
  {
   const string cmt = StringFormat("cap %.0f%%", 100.0 * fCible);
   double reste = diffLots;

   //--- 1) solder ce qui s'oppose au sens demande
   for(int i = PositionsTotal() - 1; i >= 0 && MathAbs(reste) > 0.0; i--)
     {
      if(!g_pos.SelectByIndex(i))
         continue;
      if(g_pos.Symbol() != _Symbol || g_pos.Magic() != InpMagic)
         continue;
      const bool estAchat = (g_pos.PositionType() == POSITION_TYPE_BUY);
      const bool opposee  = (reste > 0.0 && !estAchat) || (reste < 0.0 && estAchat);
      if(!opposee)
         continue;
      const double aFermer = MathMin(g_pos.Volume(), MathAbs(reste));
      const double vol = NormaliserLots(aFermer);
      if(vol <= 0.0)
         continue;
      if(vol >= g_pos.Volume() - 1e-8)
        {
         if(g_trade.PositionClose(g_pos.Ticket(), InpSlippage))
            reste -= (estAchat ? -g_pos.Volume() : g_pos.Volume());
        }
      else
        {
         if(g_trade.PositionClosePartial(g_pos.Ticket(), vol, InpSlippage))
            reste -= (estAchat ? -vol : vol);
        }
     }

   //--- 2) ouvrir le complement dans le sens voulu
   if(MathAbs(reste) <= 0.0)
      return;
   const double vol = NormaliserLots(MathAbs(reste));
   if(vol <= 0.0)
      return;
   if(!VerifierMarge(reste > 0.0, vol))
     {
      Print("Roi : marge insuffisante pour ", DoubleToString(vol, 2), " lots — ordre abandonne");
      return;
     }
   if(reste > 0.0)
      g_trade.Buy(vol, _Symbol, 0.0, 0.0, 0.0, cmt);
   else
      g_trade.Sell(vol, _Symbol, 0.0, 0.0, 0.0, cmt);
  }

//+------------------------------------------------------------------+
//| Verifie que la marge libre suffit avant d'envoyer l'ordre        |
//+------------------------------------------------------------------+
bool VerifierMarge(const bool achat, const double lots)
  {
   const double prix = achat ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                     : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double marge = 0.0;
   if(!OrderCalcMargin(achat ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                       _Symbol, lots, prix, marge))
      return(true);              // en cas de doute on laisse le serveur trancher
   return(marge < AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.95);
  }

//+------------------------------------------------------------------+
//| Nombre de positions deja fermees par cet expert                  |
//+------------------------------------------------------------------+
int HistoryTradesCount()
  {
   static int s_cache = 0;
   static datetime s_last = 0;
   const datetime now = TimeCurrent();
   if(now - s_last < 60)
      return(s_cache);
   s_last = now;
   if(!HistorySelect(0, now))
      return(s_cache);
   int n = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong t = HistoryDealGetTicket(i);
      if(t == 0)
         continue;
      if(HistoryDealGetInteger(t, DEAL_MAGIC) != InpMagic)
         continue;
      if(HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         n++;
     }
   s_cache = n;
   return(n);
  }

//+------------------------------------------------------------------+
//| Profit cumule des positions fermees par cet expert               |
//+------------------------------------------------------------------+
double GetProfitFerme()
  {
   static double s_cache = 0.0;
   static datetime s_last = 0;
   const datetime now = TimeCurrent();
   if(now - s_last < 60)
      return(s_cache);
   s_last = now;
   if(!HistorySelect(0, now))
      return(s_cache);
   double p = 0.0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong t = HistoryDealGetTicket(i);
      if(t == 0)
         continue;
      if(HistoryDealGetInteger(t, DEAL_MAGIC) != InpMagic)
         continue;
      p += HistoryDealGetDouble(t, DEAL_PROFIT)
           + HistoryDealGetDouble(t, DEAL_SWAP)
           + HistoryDealGetDouble(t, DEAL_COMMISSION);
     }
   s_cache = p;
   return(p);
  }

//+------------------------------------------------------------------+
//| Nom lisible d'une espece                                         |
//+------------------------------------------------------------------+
string NomEspece(const int e, const int lbAn)
  {
   switch(e)
     {
      case 1:  return("Guepard " + IntegerToString(L[1]));
      case 2:  return("Loup " + IntegerToString(L[2]));
      case 3:  return("Ours " + IntegerToString(L[3]));
      case 4:  return("Elephant " + IntegerToString(L[4]));
      case 5:  return("Baleine " + IntegerToString(L[5]));
      case 6:  return("Colibri " + IntegerToString(L[6]));
      case 7:  return("Renard " + IntegerToString(L[7]));
      case 8:  return("Chouette " + IntegerToString(L[8]));
      case 9:  return("Aigle " + IntegerToString(lbAn) + " (dollar inverse)");
      case 10: return("Crocodile 55 (embuscade)");
      case 11: return("Hyene 20 (charognard)");
      case 12: return("Panthere " + IntegerToString(L[12]));
      case 13: return("Lynx " + IntegerToString(L[13]));
      case 14: return("Bison " + IntegerToString(L[14]));
      case 15: return("Serpent " + IntegerToString(L[15]));
      case 16: return("Vautour 40 (grands charniers)");
     }
   return("?");
  }

//+------------------------------------------------------------------+
//| Le poste de commandement : tout ce que le tableau Pine affichait |
//+------------------------------------------------------------------+
void AfficherTableau(const bool ready, const bool savaneOk, const int vivantes,
                     const int naissances, const int doyenne, const int bestE,
                     const double bestFit, const double dir, const double dirS,
                     const double fCible, const double expoActu, const double sigA,
                     const double levVol, const double dd, const double torpeur,
                     const double torpeurLibre, const double scoreLocal, const double ent,
                     const int fond, const double wTot, const double wContraTot,
                     const double orage, const double ruche, const double rucheMoy,
                     const double meches, const bool solTraitre, const bool fourmisAlerte,
                     const bool abeillesAlerte, const bool decroche,
                     const double retPresent, const double retRythme,
                     const int lbAn, const bool choc)
  {
   const bool desert = (PeriodSeconds(Period()) < 14400);
   string diag;
   if(g_eteint)
      diag = "ETEINT : plancher de survie franchi, plus aucune exposition";
   else if(InpPacteAbri)
      diag = "l'Homme a ordonne l'abri — la savane attend son retour";
   else if(!ready)
      diag = "amorcage : encore " + IntegerToString(MathMax(0, 301 - g_barIndex)) + " bougies";
   else if(desert)
      diag = "DESERT : frais > proies sur cette unite de temps — passez en D1";
   else if(!savaneOk)
      diag = "savane locale sterile — migration conseillee vers " + g_savBest;
   else if(vivantes == 0)
      diag = "extinction : tout le monde a l'abri";
   else if(MathAbs(dirS) < InpProieMin)
      diag = StringFormat("meute a l'affut : proie trop maigre (conviction %.0f %% < %.0f %%)",
                          100.0 * MathAbs(dirS), 100.0 * InpProieMin);
   else
      diag = StringFormat("%d/16 vivantes · %d naissances · la meute charge, cap %s",
                          vivantes, naissances,
                          (dir > 0.05 ? "haussier" : (dir < -0.05 ? "baissier" : "neutre")));

   string t = "";
   t += "=== LE ROI DE LA SAVANE G9 ===\n";
   t += "Etat de l'ecosysteme : " + diag + "\n";
   t += StringFormat("Exposition cible / reelle : %+.1f %% / %+.1f %%\n",
                     100.0 * fCible, 100.0 * expoActu);
   t += "--- Les seize especes (rythme · generation · forme · part) ---\n";
   for(int i = 1; i <= 16; i++)
     {
      const double part = (wTot > 0.0) ? 100.0 * W[i] / wTot : 0.0;
      t += StringFormat("  %-30s g%-2d %s %+7.1f pb  %3.0f %%%s\n",
                        NomEspece(i, lbAn), G[i],
                        (SIGV[i] > 0.0 ? "H" : (SIGV[i] < 0.0 ? "B" : "-")),
                        10000.0 * FIT[i], part,
                        (i == bestE ? "   <-- le lion" : ""));
     }
   t += StringFormat("Systeme immunitaire : %s\n",
                     (g_immun > 0.0
                      ? StringFormat("BOUCLIER, convalescence %.0f bougies", g_immun)
                      : StringFormat("au repos, seuil %.1f ecarts-types", InpChocSeuil)));
   t += StringFormat("Etat civil : %d naissances · doyenne %d bougies\n", naissances, doyenne);
   t += StringFormat("Volatilite realisee -> levier : %.1f %% -> x%.2f\n",
                     100.0 * sigA, levVol);
   t += StringFormat("Trades fermes : %d · profit ferme : %.2f\n",
                     HistoryTradesCount(), GetProfitFerme());
   t += StringFormat("Temperature (perte / borne %.0f %%) : %.1f %% depuis le sommet · %s\n",
                     InpDdMax, 100.0 * dd,
                     (torpeurLibre >= 0.99 ? "metabolisme normal"
                      : (torpeurLibre > 0.5
                         ? StringFormat("fievre : poussee reduite a %.0f %%", 100.0 * torpeur)
                         : (torpeurLibre > 0.0
                            ? StringFormat("torpeur profonde : %.0f %%", 100.0 * torpeur)
                            : StringFormat("BORNE FRANCHIE : plancher de chasse %.0f %%",
                                           100.0 * torpeur)))));
   // C3 : la part contrarienne inclut bien la Hyene, le Serpent et le Vautour
   t += StringFormat("Tendance de fond (%d bougies) : %s%s · contrariennes %.0f %% (max %.0f %%)\n",
                     lbAn, (fond > 0 ? "haussiere H" : "baissiere B"),
                     (InpRespectFond
                      ? (fond > 0 ? " · shorts interdits" : " · longs interdits")
                      : " · filtre desactive"),
                     (wTot > 0.0 ? 100.0 * wContraTot / wTot : 0.0), InpContMax);
   t += StringFormat("Le lion (alpha, part ^%.1f) : %s · forme %.1f pb%s\n",
                     InpHierarchie, NomEspece(bestE, lbAn), 10000.0 * bestFit,
                     (bestFit > 0.0 ? " — il mange le premier" : " — toute la meute a faim"));
   t += StringFormat("Meteo de la savane locale : score %.2f (min %.2f) · entropie %.1f %% %s\n",
                     scoreLocal, InpSavaneMin, 100.0 * ent,
                     (savaneOk ? "propice" : "sterile"));
   t += StringFormat("L'Homme : %s\n",
                     (InpPacteAbri ? "a ordonne l'abri"
                      : "laisse regner ses lois : il legifere, il alloue, il n'intervient pas"));
   t += StringFormat("L'eau (financement du levier) : %.1f %%/an · cout cumule %.0f · profit apres eau %.0f\n",
                     InpSwapAnnuel, g_eauCum, GetProfitFerme() - g_eauCum);
   t += StringFormat("Le miroir : present %.1f %% / fenetre · rythme historique %.1f %% %s\n",
                     100.0 * retPresent, 100.0 * retRythme,
                     (decroche ? "DECROCHAGE" : "coherent"));
   t += StringFormat("L'essaim : fourmis %s%s · abeilles %s%s · sol %s · anticorps %.1f%s\n",
                     (fourmisAlerte ? "orage" : "calmes"), (InpFourmisOn ? "" : " (obs.)"),
                     (abeillesAlerte ? "tempete" : "calmes"), (InpAbeillesOn ? "" : " (obs.)"),
                     (solTraitre ? "traitre" : "sain"), g_anticorps,
                     (InpImmAcqOn ? " (armes)" : " (obs.)"));
   t += "--- Les vingt savanes (tendance / bruit -> score) ---\n";
   for(int i = 1; i < NSAV; i++)
     {
      if(StringLen(g_sav[i]) == 0)
         continue;
      string etat;
      if(g_voSav[i] <= 0.0)
         etat = "indisponible";
      else if(g_scSav[i] >= InpSavaneMin)
         etat = "grasse";
      else if(g_scSav[i] >= InpSavaneMin / 2.0)
         etat = "maigre";
      else
         etat = "desert";
      t += StringFormat("  %-10s %+5.0f %% / bruit %4.0f %% -> %5.2f  %s\n",
                        g_sav[i], 100.0 * g_moSav[i], 100.0 * g_voSav[i],
                        g_scSav[i], etat);
     }
   t += "Migration conseillee : " + g_savBest + "\n";
   Comment(t);
  }
//+------------------------------------------------------------------+
