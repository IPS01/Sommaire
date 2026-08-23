//+------------------------------------------------------------------+
//|                                                 DiagSavane.mq5   |
//|                                                                  |
//|   EXPERT DE DIAGNOSTIC — il ne cherche pas a gagner de l'argent. |
//|   Il repond a UNE question : ou est-ce que ca bloque ?           |
//|                                                                  |
//|   Il teste sept couches, dans l'ordre, et dit ce qu'il trouve :  |
//|     1. OnInit s'execute-t-il ?                                   |
//|     2. OnTick est-il appele ?                                    |
//|     3. Les nouvelles bougies sont-elles detectees ?              |
//|     4. L'historique du symbole est-il lisible ?                  |
//|     5. Le compte permet-il de calculer un volume ?               |
//|     6. Un ordre passe-t-il vraiment ?                            |
//|     7. Le score de savane autoriserait-il la chasse ?            |
//|                                                                  |
//|   A METTRE SUR LE MEME SYMBOLE ET LA MEME PERIODE que le test    |
//|   qui ne donne rien. Lisez l'onglet Journal du testeur.          |
//+------------------------------------------------------------------+
#property copyright "patrice_cloquet59"
#property version   "1.00"
#property description "Diagnostic : dit ou le Roi de la Savane se bloque"

#include <Trade\Trade.mqh>

input bool InpPasserUnOrdre = true;   // Passer UN ordre de test apres 30 bougies
input int  InpToutesLesN    = 100;    // Rapport detaille toutes les N bougies

CTrade   trade;
datetime g_lastBar = 0;
int      g_bars    = 0;
bool     g_ordreFait = false;
int      g_ticks   = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(777777);
   trade.SetDeviationInPoints(50);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("################################################################");
   Print("### DIAGNOSTIC — COUCHE 1 : OnInit S'EXECUTE. C'est deja ca. ###");
   Print("################################################################");
   Print("Symbole teste ......... ", _Symbol);
   Print("Periode ............... ", EnumToString(Period()),
         "  (", PeriodSeconds(Period()), " secondes par bougie)");
   Print("Bougies disponibles ... ", Bars(_Symbol, Period()));
   Print("Mode testeur .......... ", (bool)MQLInfoInteger(MQL_TESTER) ? "OUI" : "NON (temps reel)");
   Print("--- LE COMPTE ---");
   Print("Solde ................. ", AccountInfoDouble(ACCOUNT_BALANCE),
         " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("Equite ................ ", AccountInfoDouble(ACCOUNT_EQUITY));
   Print("Marge libre ........... ", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
   Print("Levier ................ 1:", AccountInfoInteger(ACCOUNT_LEVERAGE));
   Print("Trading autorise ...... ",
         (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ? "OUI" : "NON <<< PROBLEME");
   Print("Experts autorises ..... ",
         (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) ? "OUI" : "NON <<< PROBLEME");
   Print("--- LE SYMBOLE ---");
   Print("Point ................. ", SymbolInfoDouble(_Symbol, SYMBOL_POINT));
   Print("Taille de contrat ..... ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE));
   Print("Valeur du tick ........ ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
   Print("Taille du tick ........ ", SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
   Print("Volume min / pas / max  ",
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), " / ",
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP), " / ",
         SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   const long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   Print("Mode de negociation ... ", mode,
         (mode == SYMBOL_TRADE_MODE_DISABLED ? "  <<< NEGOCIATION DESACTIVEE" :
          (mode == SYMBOL_TRADE_MODE_CLOSEONLY ? "  <<< FERMETURE SEULE" : "  (negociable)")));
   Print("Stops level ........... ", SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));
   Print("################################################################");
   Comment("DIAGNOSTIC : OnInit passe. En attente du premier tick...");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("### FIN DU DIAGNOSTIC ###");
   Print("Ticks recus ........... ", g_ticks);
   Print("Bougies detectees ..... ", g_bars);
   Print("Ordre de test passe ... ", g_ordreFait ? "OUI" : "NON");
   if(g_ticks == 0)
      Print(">>> AUCUN TICK RECU. Le testeur n'a pas fourni de donnees : ",
            "verifiez la periode testee et l'historique du symbole.");
   else if(g_bars == 0)
      Print(">>> DES TICKS MAIS AUCUNE BOUGIE. Anomalie de donnees.");
   Comment("");
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   g_ticks++;
   if(g_ticks == 1)
      Print("### COUCHE 2 : PREMIER TICK RECU. Le testeur envoie des donnees. ###");

   const datetime tBar = iTime(_Symbol, Period(), 0);
   if(tBar == g_lastBar)
      return;
   g_lastBar = tBar;
   g_bars++;

   if(g_bars == 1)
      Print("### COUCHE 3 : PREMIERE BOUGIE DETECTEE a ", TimeToString(tBar), " ###");

   //--- COUCHE 4 : l'historique est-il lisible ?
   double cl[];
   ArraySetAsSeries(cl, true);
   const int veut = 460;
   const int eu = CopyClose(_Symbol, Period(), 0, veut, cl);

   if(g_bars % MathMax(1, InpToutesLesN) == 0 || g_bars == 1)
     {
      Print("--- bougie ", g_bars, " (", TimeToString(tBar), ") ---");
      Print("   COUCHE 4 : CopyClose demande ", veut, " -> obtenu ", eu,
            (eu < veut ? "  <<< PAS ASSEZ D'HISTORIQUE, le moteur attendrait ici" : "  OK"));
      Print("   Bars() = ", Bars(_Symbol, Period()),
            " | equite = ", AccountInfoDouble(ACCOUNT_EQUITY),
            " | marge libre = ", AccountInfoDouble(ACCOUNT_MARGIN_FREE));

      if(eu >= 300)
        {
         //--- COUCHE 7 : le score de savane autoriserait-il la chasse ?
         const int lb = MathMin(252, eu - 70);
         double r[63];
         for(int i = 0; i < 63; i++)
            r[i] = MathLog(cl[i] / cl[i + 1]);
         double m = 0.0;
         for(int i = 0; i < 63; i++) m += r[i];
         m /= 63.0;
         double s2 = 0.0;
         for(int i = 0; i < 63; i++) s2 += (r[i] - m) * (r[i] - m);
         const double sd = MathSqrt(s2 / 63.0) * MathSqrt(252.0);
         const double mom = cl[0] / cl[lb] - 1.0;
         const double score = (sd > 0.0) ? MathAbs(mom) / sd : 0.0;
         Print("   COUCHE 7 : tendance ", DoubleToString(100.0 * mom, 1), " % sur ", lb,
               " bougies | volatilite ", DoubleToString(100.0 * sd, 1), " %/an",
               " | SCORE DE SAVANE = ", DoubleToString(score, 2));
         Print("             seuil du Roi = 0.80 -> la savane serait ",
               (score >= 0.80 ? "PROPICE, la meute chasserait"
                : "STERILE : LE ROI NE CHASSERAIT PAS <<< C'EST PEUT-ETRE CA"));
        }
     }

   //--- COUCHES 5 et 6 : sait-on calculer un volume, et un ordre passe-t-il ?
   if(InpPasserUnOrdre && !g_ordreFait && g_bars >= 30 && eu >= 100)
     {
      const double prix = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      const double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      const double tickSz  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      const double notLot  = (tickVal > 0.0 && tickSz > 0.0 && prix > 0.0)
                             ? prix / tickSz * tickVal : 0.0;
      Print("### COUCHE 5 : CALCUL DU VOLUME ###");
      Print("   prix = ", prix, " | notionnel d'un lot = ", DoubleToString(notLot, 2),
            " ", AccountInfoString(ACCOUNT_CURRENCY));
      if(notLot <= 0.0)
        {
         Print("   <<< IMPOSSIBLE DE CALCULER LE NOTIONNEL : valeur ou taille de tick nulle.");
         Print("   <<< C'EST BLOQUANT : le Roi ne saurait pas dimensionner sa position.");
         g_ordreFait = true;
         return;
        }
      const double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      const double eq   = AccountInfoDouble(ACCOUNT_EQUITY);
      double lots = 0.10 * eq / notLot;      // 10 % du capital, volontairement petit
      const double pas = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      if(pas > 0.0) lots = MathFloor(lots / pas + 0.5) * pas;
      lots = MathMax(vmin, lots);
      Print("   volume calcule pour 10 % du capital = ", DoubleToString(lots, 2),
            " lots (minimum du courtier : ", vmin, ")");

      double marge = 0.0;
      if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, prix, marge))
         Print("   marge requise = ", DoubleToString(marge, 2),
               " | marge libre = ", DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2),
               (marge > AccountInfoDouble(ACCOUNT_MARGIN_FREE)
                ? "  <<< MARGE INSUFFISANTE" : "  OK"));

      Print("### COUCHE 6 : ENVOI D'UN ORDRE DE TEST ###");
      const bool ok = trade.Buy(lots, _Symbol, 0.0, 0.0, 0.0, "diagnostic");
      Print("   resultat = ", (ok ? "ACCEPTE" : "REFUSE"),
            " | retcode = ", trade.ResultRetcode(),
            " (", trade.ResultRetcodeDescription(), ")");
      if(ok)
        {
         Print("   >>> LE PIPELINE D'ORDRES FONCTIONNE. Si le Roi ne trade pas,");
         Print("   >>> ce n'est donc PAS un probleme d'execution : c'est une de");
         Print("   >>> ses conditions qui reste fausse (voir COUCHE 7 ci-dessus).");
         trade.PositionClose(_Symbol);
        }
      else
        {
         Print("   >>> L'ORDRE EST REFUSE. Le probleme est a l'execution, pas");
         Print("   >>> dans la strategie. Lisez le retcode ci-dessus.");
        }
      g_ordreFait = true;
     }

   Comment(StringFormat("DIAGNOSTIC\nbougies vues : %d\nticks : %d\nhistorique : %d/%d\nordre de test : %s",
                        g_bars, g_ticks, eu, veut, (g_ordreFait ? "fait" : "en attente de la bougie 30")));
  }
//+------------------------------------------------------------------+
