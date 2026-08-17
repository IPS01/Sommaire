//+------------------------------------------------------------------+
//|                                            Roi_de_la_Savane.mq5 |
//|        LE ROI DE LA SAVANE — Écosystème Darwinien, Génération 9 |
//|        Portage MetaTrader 5 du script Pine (TradingView)        |
//+------------------------------------------------------------------+
//| PHILOSOPHIE : la savane est le marché. 17 espèces chassent en   |
//| permanence avec des instincts différents ; le capital va aux    |
//| formes vigoureuses (sélection darwinienne). Le roi jauge le     |
//| territoire avant de chasser ; la lignée est protégée par la     |
//| température, le bouclier et le plancher de survie.              |
//|                                                                  |
//| DIFFÉRENCES AVEC LA VERSION PINE (honnêteté du portage) :        |
//| - L'Albatros lit le portage dans les SWAPS RÉELS du courtier    |
//|   (SYMBOL_SWAP_LONG/SHORT) au lieu des taux 2 ans TVC.          |
//| - L'eau n'existe plus : MT5 facture les vrais swaps, y compris  |
//|   dans le testeur de stratégie. Le profit affiché est déjà      |
//|   « après eau ».                                                 |
//| - Les saisons (annonces de résultats) n'existent pas : utilisez |
//|   le PacteAbri (input) avant les grands événements.             |
//| - Les 20 savanes ne sont pas surveillées ici : une colonie MT5  |
//|   par graphique/symbole, le tableau TradingView reste votre     |
//|   carte du monde.                                                |
//| - L'Aigle lit un symbole dollar configurable (AigleSymbole) ;   |
//|   laissez vide s'il n'existe pas chez votre courtier : il dort. |
//|                                                                  |
//| INSTALLATION : MetaEditor -> nouveau fichier -> coller -> F7    |
//| (compiler) -> glisser l'EA sur le graphique du territoire       |
//| (XAUUSD D1, USDJPY W1...). TOUJOURS valider au Testeur de       |
//| Stratégie MT5 avant tout compte réel : ce portage doit refaire  |
//| ses preuves dans sa nouvelle arène. Compte NETTING recommandé.  |
//+------------------------------------------------------------------+
#property copyright "Écosystème darwinien - projet Roi de la Savane"
#property version   "9.00"
#property description "17 espèces, sélection naturelle, ciblage de volatilité, plancher de survie"

#include <Trade/Trade.mqh>
CTrade trade;

//=================== PARAMÈTRES ===================
input group "Direction"
input bool   EnableLongs   = true;   // Autoriser les achats
input bool   EnableShorts  = true;   // Autoriser les ventes

input group "Sélection naturelle"
input int    FitMem        = 63;     // Mémoire de la forme (demi-vie, bougies)
input double Frais         = 0.1;    // Frais virtuels par retournement (%)
input double DivBonus      = 0.5;    // Bonus de niche (décorrélation)
input double ContMax       = 50.0;   // Part max des contrariennes (%)
input bool   RespectFond   = true;   // Jamais contre la tendance 252 bougies

input group "La meute (le lion)"
input double Hierarchie    = 2.0;    // Part du lion (exposant)
input double ProieMin      = 0.2;    // Conviction minimale pour charger

input group "La savane (le territoire)"
input double SavaneMin     = 0.6;    // Score minimal du territoire
input int    WEnt          = 96;     // Fenêtre d'entropie de Shannon
input double EntMax        = 0.995;  // Entropie maximale tolérée

input group "Évolution"
input int    StarveMax     = 150;    // Famine mortelle (bougies)
input double SoinParent    = 25.0;   // Héritage du champion (%)

input group "Homéostasie"
input double TargetVol     = 25.0;   // Volatilité cible (% par an)
input int    VolWin        = 63;     // Fenêtre de volatilité
input double ExpoMax       = 3.0;    // Exposition maximale (x capital)
input double RebalPct      = 25.0;   // Zone morte de rééquilibrage (%)
input int    Respire       = 5;      // Respiration (bougies) - 5 en D1, 2 en W1

input group "Régulation thermique (survie)"
input double DdMax         = 30.0;   // Borne mortelle (% depuis le sommet)
input int    GuerJours     = 500;    // Guérison : demi-vie du sommet (jours)
input double Plancher      = 50.0;   // Plancher de survie (% du capital initial)
input double CapitalInitial= 10000;  // Capital initial de la colonie

input group "Système immunitaire"
input double ChocSeuil     = 4.0;    // Choc (écarts-types)
input int    ChocDuree     = 10;     // Convalescence (bougies)
input bool   ImmAcqOn      = false;  // Armer l'immunité acquise (anticorps)

input group "L'essaim (sentinelles)"
input bool   FourmisOn     = false;  // Armer les fourmis (orage micro)

input group "L'Homme (le souverain)"
input bool   PacteAbri     = false;  // ORDRE SOUVERAIN : tout à l'abri

input group "L'Aigle (dollar inversé)"
input string AigleSymbole  = "";     // Symbole indice dollar (vide = l'Aigle dort)

input group "Notifications"
input bool   AlertesPopup  = true;   // Alertes à l'écran
input bool   AlertesPush   = false;  // Notifications mobiles (SendNotification)

input group "Technique"
input ulong  MagicNumber   = 20260817; // Signature des ordres de la colonie

//=================== L'ÉTAT DE LA COLONIE ===================
#define NSP 17
// Espèces : 0 Guépard 1 Loup 2 Ours 3 Éléphant 4 Baleine (tendance mutables)
//           5 Colibri 6 Renard 7 Chouette (contrariennes mutables)
//           8 Aigle 9 Crocodile 10 Hyène (fossiles/charognard)
//           11 Panthère 12 Lynx 13 Bison (tendance mutables) 14 Serpent (contr.)
//           15 Vautour (charognard fossile) 16 Albatros (portage, fossile)
int      L[NSP]        = {10,21,63,126,252, 2,5,10, 252,55,20, 8,30,150,3, 40, 252};
int      habMin[NSP]   = {5,15,40,90,180, 2,4,8, 0,0,0, 5,25,120,2, 0, 0};
int      habMax[NSP]   = {20,40,100,200,400, 6,12,30, 0,0,0, 15,60,300,8, 0, 0};
bool     mutable_[NSP] = {true,true,true,true,true, true,true,true, false,false,false, true,true,true,true, false, false};
bool     contr[NSP]    = {false,false,false,false,false, true,true,true, false,false,true, false,false,false,true, true, false};
double   fit[NSP], stv[NSP], sigPrev[NSP], sigNow[NSP], w[NSP];
int      gen[NSP], age[NSP];

#define QWIN 100
double   pHist[NSP][QWIN];        // gains virtuels récents (niches)
double   pEcoHist[QWIN];
int      histN = 0;

double   eqPeak = 0.0;
bool     eteint = false;
double   immun = 0.0;             // bouclier réflexe (bougies restantes)
double   anticorps = 0.0;         // immunité acquise
long     barCount = 0;
datetime lastBar = 0;
double   lamF, lamA, fr;
int      naissances = 0;
bool     lastCharge=false, lastSterile=false;

//=================== OUTILS ===================
double Clamp(double x, double lo, double hi){ return MathMax(lo, MathMin(hi, x)); }

double CloseAt(int shift){ return iClose(_Symbol, _Period, shift); }
double HighAt(int shift) { return iHigh(_Symbol, _Period, shift); }
double LowAt(int shift)  { return iLow(_Symbol, _Period, shift); }
double OpenAt(int shift) { return iOpen(_Symbol, _Period, shift); }

// écart-type des rendements log sur n bougies (bougies clôturées, base shift=1)
double SdBar(int n)
{
   double m=0, s=0; int cnt=0;
   for(int i=1;i<=n;i++){
      double c0=CloseAt(i), c1=CloseAt(i+1);
      if(c1<=0||c0<=0) break;
      double r=MathLog(c0/c1); m+=r; cnt++;
   }
   if(cnt<2) return 0;
   m/=cnt;
   for(int i=1;i<=cnt;i++){
      double r=MathLog(CloseAt(i)/CloseAt(i+1));
      s+=(r-m)*(r-m);
   }
   return MathSqrt(s/(cnt-1));
}

double Momentum(int len){ // log(close/close[len]) sur bougies clôturées
   double c0=CloseAt(1), cL=CloseAt(1+len);
   if(cL<=0||c0<=0) return 0;
   return MathLog(c0/cL);
}

double HighestClose(int len){ double h=0; for(int i=1;i<=len;i++) h=MathMax(h,CloseAt(i)); return h; }
double LowestClose(int len){ double l=DBL_MAX; for(int i=1;i<=len;i++) l=MathMin(l,CloseAt(i)); return l; }

double Correl(int sp)
{
   int n=MathMin(histN,QWIN); if(n<20) return 1.0;
   double mx=0,my=0;
   for(int i=0;i<n;i++){ mx+=pHist[sp][i]; my+=pEcoHist[i]; }
   mx/=n; my/=n;
   double sxy=0,sxx=0,syy=0;
   for(int i=0;i<n;i++){
      double dx=pHist[sp][i]-mx, dy=pEcoHist[i]-my;
      sxy+=dx*dy; sxx+=dx*dx; syy+=dy*dy;
   }
   if(sxx<=0||syy<=0) return 1.0;
   return sxy/MathSqrt(sxx*syy);
}

void Prevenir(string titre, string msg)
{
   if(AlertesPopup) Alert("Roi de la Savane [", _Symbol, "] ", titre, " — ", msg);
   if(AlertesPush)  SendNotification("RoiSavane "+_Symbol+" : "+titre+" — "+msg);
}

double VolumeNormalise(double lots)
{
   double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double vstep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(vstep<=0) vstep=0.01;
   double v=MathFloor(MathAbs(lots)/vstep)*vstep;
   if(v<vmin) return 0;
   return MathMin(v,vmax);
}

double PositionNette() // volume signé de NOTRE colonie (netting)
{
   if(!PositionSelect(_Symbol)) return 0;
   if(PositionGetInteger(POSITION_MAGIC)!=(long)MagicNumber && PositionGetInteger(POSITION_MAGIC)!=0)
      return 0; // position d'un autre robot : on n'y touche pas
   double v=PositionGetDouble(POSITION_VOLUME);
   return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)? v : -v;
}

//=================== INITIALISATION ===================
int OnInit()
{
   lamF = MathPow(0.5, 1.0/FitMem);
   lamA = MathPow(0.5, 1.0/252.0);
   fr   = Frais/100.0;
   ArrayInitialize(fit,0); ArrayInitialize(stv,0);
   ArrayInitialize(sigPrev,0); ArrayInitialize(sigNow,0);
   for(int i=0;i<NSP;i++){ gen[i]=1; age[i]=0; }
   trade.SetExpertMagicNumber(MagicNumber);
   eqPeak = AccountInfoDouble(ACCOUNT_EQUITY);
   Print("Le Roi de la Savane G9 s'éveille sur ", _Symbol, " ", EnumToString(_Period));
   return INIT_SUCCEEDED;
}

//=================== LE CŒUR : UNE BOUGIE CLÔTURÉE ===================
void OnTick()
{
   datetime t0 = iTime(_Symbol,_Period,0);
   if(t0==lastBar) return;          // on ne travaille qu'à la bougie nouvelle
   lastBar = t0;
   barCount++;
   if(Bars(_Symbol,_Period) < 320) return;   // amorçage : 300 bougies + marge

   //---------- terrain de base ----------
   double v = MathLog(CloseAt(1)/CloseAt(2));       // rendement de la bougie close
   double sdB = SdBar(50);
   bool   ready = (barCount>10);                     // l'historique MT5 est déjà chargé

   //---------- les 17 instincts ----------
   for(int i=0;i<NSP;i++) sigPrev[i]=sigNow[i];
   for(int i=0;i<NSP;i++)
   {
      double s=0;
      if(i==8){ // AIGLE : inverse de la tendance annuelle du dollar
         if(StringLen(AigleSymbole)>0){
            double a0=iClose(AigleSymbole,_Period,1), aL=iClose(AigleSymbole,_Period,253);
            double sdA=0; { double m=0; int c=0;
               for(int k=1;k<=50;k++){ double x0=iClose(AigleSymbole,_Period,k), x1=iClose(AigleSymbole,_Period,k+1); if(x0<=0||x1<=0)break; m+=MathLog(x0/x1); c++; }
               if(c>2){ m/=c; double ss=0; for(int k=1;k<=c;k++){ double r=MathLog(iClose(AigleSymbole,_Period,k)/iClose(AigleSymbole,_Period,k+1)); ss+=(r-m)*(r-m);} sdA=MathSqrt(ss/(c-1)); } }
            double d=sdA*MathSqrt(252.0);
            if(a0>0 && aL>0 && d>0) s = -Clamp(MathLog(a0/aL)/d, -1, 1);
         }
      }
      else if(i==9){ // CROCODILE : canal de Donchian 55
         double h=HighestClose(55), l=LowestClose(55);
         if(h-l>0) s = Clamp((CloseAt(1)-(h+l)/2.0)/((h-l)/2.0), -1, 1);
      }
      else if(i==10){ // HYÈNE : capitulation 20 bougies
         double h=HighestClose(20);
         if(sdB>0 && h>0){ double chute=MathLog(CloseAt(1)/h)/(sdB*MathSqrt(20.0)); s=Clamp((-chute-1.5)/1.5, 0, 1); }
      }
      else if(i==15){ // VAUTOUR : grands charniers 40 bougies
         double h=HighestClose(40);
         if(sdB>0 && h>0){ double chute=MathLog(CloseAt(1)/h)/(sdB*MathSqrt(40.0)); s=Clamp((-chute-2.5)/2.0, 0, 1); }
      }
      else if(i==16){ // ALBATROS : le portage lu dans les SWAPS RÉELS du courtier
         double swL=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_LONG);
         double swS=SymbolInfoDouble(_Symbol,SYMBOL_SWAP_SHORT);
         double den=MathAbs(swL)+MathAbs(swS);
         if(den>0) s = Clamp((swL-swS)/den, -1, 1); // >0 : être long est payé
      }
      else{ // suiveuses et contrariennes : z-score borné du momentum
         double d=sdB*MathSqrt((double)L[i]);
         if(d>0) s=Clamp(Momentum(L[i])/d, -1, 1);
         if(contr[i]) s=-s;
      }
      sigNow[i]=s;
   }

   //---------- la chasse virtuelle et la forme ----------
   double p[NSP]; double pEco=0;
   for(int i=0;i<NSP;i++){
      p[i] = sigPrev[i]*v - MathAbs(sigNow[i]-sigPrev[i])*0.5*fr;
      pEco += p[i];
   }
   pEco/=NSP;
   int slot=histN%QWIN;
   for(int i=0;i<NSP;i++) pHist[i][slot]=p[i];
   pEcoHist[slot]=pEco; histN++;
   for(int i=0;i<NSP;i++) fit[i]=lamF*fit[i]+(1.0-lamF)*p[i];

   //---------- évolution : famine, croisement, mutation ----------
   double bestFit=-DBL_MAX, scndFit=-DBL_MAX; int bi=-1, si=-1;
   for(int i=0;i<NSP;i++) if(fit[i]>bestFit){ bestFit=fit[i]; bi=i; }
   for(int i=0;i<NSP;i++) if(i!=bi && fit[i]>scndFit){ scndFit=fit[i]; si=i; }
   double croise=MathSqrt(MathMax(2,(double)L[bi])*MathMax(2,(double)L[si]));
   double heritage=MathMax(bestFit,0.0)*SoinParent/100.0;
   double fmut=0.5+MathAbs(MathSin((double)barCount*12.9898));
   bool naissanceCeBar=false;
   for(int i=0;i<NSP;i++){
      stv[i]=(fit[i]<=0)? stv[i]+1 : 0;
      age[i]++;
      if(mutable_[i] && stv[i]>StarveMax){
         // l'enfant : croisement des 2 meilleurs rythmes, muté, ramené à
         // l'échelle de l'habitat du slot (anti-consanguinité)
         int nouveau=(int)MathRound(croise*fmut*((double)habMin[i]+(double)habMax[i])/(2.0*55.0));
         L[i]=(int)Clamp(nouveau, habMin[i], habMax[i]);
         fit[i]=heritage; stv[i]=0; gen[i]++; age[i]=0; naissances++; naissanceCeBar=true;
      }
   }
   if(naissanceCeBar) Prevenir("naissance", "une espèce affamée renaît, croisée et mutée");

   //---------- niches, meute, plafond des contrariennes ----------
   double fitRef=MathMax(bestFit,1e-12);
   double wT=0, wCr=0;
   for(int i=0;i<NSP;i++){
      double q=Correl(i);
      w[i]=MathPow(MathMax(0.0,fit[i])/fitRef, Hierarchie)*(1.0+DivBonus*(1.0-q));
      if(contr[i]) wCr+=w[i]; else wT+=w[i];
   }
   double cC=ContMax/100.0;
   double scaleC=(wCr>0 && cC<1.0)? MathMin(1.0, cC*wT/MathMax(1e-12,(1.0-cC)*wCr)) : 1.0;
   double wTot=0, dir=0; int vivantes=0;
   for(int i=0;i<NSP;i++){
      double wi=contr[i]? w[i]*scaleC : w[i];
      wTot+=wi; dir+=wi*sigNow[i];
      if(wi>0) vivantes++;
   }
   dir = (wTot>0)? dir/wTot : 0;

   //---------- immunité ----------
   bool choc = ready && sdB>0 && MathAbs(v)>ChocSeuil*sdB;
   if(choc){ immun=ChocDuree; anticorps+=1.0; Prevenir("choc immunitaire","mouvement anormal, bouclier levé"); }
   else immun=MathMax(0.0,immun-1.0);
   anticorps*=lamA;
   double bouclier=(immun>0)?0.5:1.0;
   double immAcqF=MathMax(0.5, 1.0/(1.0+0.25*anticorps));

   //---------- homéostasie ----------
   int perSec=PeriodSeconds(_Period);
   double sigA=SdBar(VolWin)*MathSqrt(31536000.0/(double)perSec);
   double levVol=(sigA>0)? MathMin(ExpoMax,(TargetVol/100.0)/sigA) : 0;

   //---------- thermique et plancher ----------
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double guerison=MathPow(0.5,(double)perSec/((double)GuerJours*86400.0));
   eqPeak=MathMax(eqPeak*guerison, equity);
   double dd=(eqPeak>0)? 1.0-equity/eqPeak : 0;
   double torpeur=Clamp(1.0-dd/(DdMax/100.0),0,1);
   if(!eteint && equity < Plancher/100.0*CapitalInitial){
      eteint=true; Prevenir("EXTINCTION DÉFINITIVE","plancher de survie franchi : plus aucune exposition");
   }

   //---------- la savane locale ----------
   double mom252=Momentum(252);
   double scoreLocal=(sigA>0)? MathAbs(mom252)/sigA : 0; // mom en log ≈ % ; cohérent avec Pine
   int cnt[8]; ArrayInitialize(cnt,0); int tot=0;
   for(int k=1;k<=WEnt;k++){
      int b0=(CloseAt(k)>CloseAt(k+1))?1:0;
      int b1=(CloseAt(k+1)>CloseAt(k+2))?2:0;
      int b2=(CloseAt(k+2)>CloseAt(k+3))?4:0;
      cnt[b0+b1+b2]++; tot++;
   }
   double H=0;
   for(int j=0;j<8;j++) if(cnt[j]>0){ double pr=(double)cnt[j]/tot; H-=pr*MathLog(pr); }
   double entropie=H/MathLog(2.0)/3.0;
   bool savaneOk=(SavaneMin<=0 || scoreLocal>=SavaneMin) && (entropie<=EntMax);
   if(savaneOk && lastSterile) Prevenir("savane propice","le territoire rouvre");
   if(!savaneOk && !lastSterile && ready) Prevenir("savane stérile","le territoire se referme");
   lastSterile=!savaneOk;

   //---------- les fourmis ----------
   double sdCourt=SdBar(10), sdLong=SdBar(100);
   bool fourmisAlerte = ready && sdLong>0 && (sdCourt/sdLong)>1.5;

   //---------- LA CHARGE DU LION : décision finale ----------
   double fond=(CloseAt(1)>CloseAt(253))?1.0:-1.0;
   double dirS=dir; // lissage court : la respiration fait déjà le lissage temporel
   double dirChasse=(MathAbs(dirS)>=ProieMin)? dirS : 0;
   double fCible=(ready && !eteint)? dirChasse*levVol*torpeur*bouclier : 0;
   if(!EnableLongs  && fCible>0) fCible=0;
   if(!EnableShorts && fCible<0) fCible=0;
   if(RespectFond && fCible*fond<0) fCible=0;
   if(!savaneOk) fCible=0;
   if(PacteAbri) fCible=0;
   if(FourmisOn && fourmisAlerte) fCible*=0.7;
   if(ImmAcqOn) fCible*=immAcqF;

   bool charge=(MathAbs(dirS)>=ProieMin);
   if(charge && !lastCharge) Prevenir("la meute charge","conviction "+DoubleToString(100*MathAbs(dirS),0)+" %");
   if(!charge && lastCharge) Prevenir("retour à l'affût","conviction retombée");
   lastCharge=charge;

   //---------- CORRECTION : rééquilibrage respiré ----------
   if(barCount % MathMax(1,Respire) == 0)
   {
      double px=CloseAt(1);
      double tickV=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double tickS=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      double valeurParLot=(tickS>0)? px*tickV/tickS : 0;   // notionnel d'1 lot en devise du compte
      if(valeurParLot>0)
      {
         double lotsCible=fCible*equity/valeurParLot;
         double lotsActu=PositionNette();
         double diff=lotsCible-lotsActu;
         double seuil=MathMax(RebalPct/100.0*MathAbs(lotsCible), 0.02*equity/valeurParLot);
         if(MathAbs(diff)>seuil)
         {
            double vol=VolumeNormalise(diff);
            if(vol>0)
            {
               bool okTrade=false;
               if(diff>0) okTrade=trade.Buy(vol,_Symbol,0,0,0,"RoiSavane cap "+DoubleToString(100*fCible,0)+"%");
               else       okTrade=trade.Sell(vol,_Symbol,0,0,0,"RoiSavane cap "+DoubleToString(100*fCible,0)+"%");
               if(okTrade) Prevenir((diff>0?"poussée haussière":"poussée baissière"),
                                    "exposition vers "+DoubleToString(100*fCible,1)+" %");
            }
         }
      }
   }

   //---------- LE POSTE DE COMMANDEMENT ----------
   string alphaNoms[NSP]={"Guépard","Loup","Ours","Éléphant","Baleine","Colibri","Renard","Chouette","Aigle","Crocodile","Hyène","Panthère","Lynx","Bison","Serpent","Vautour","Albatros"};
   string diag = eteint? "ÉTEINT : plancher franchi" :
                 PacteAbri? "l'Homme a ordonné l'abri" :
                 !savaneOk? "savane stérile — pas de chasse" :
                 !charge?   "meute à l'affût (proie trop maigre)" :
                            IntegerToString(vivantes)+"/17 vivantes · la meute charge";
   string tbl = "══ LE ROI DE LA SAVANE G9 ══ "+_Symbol+" "+EnumToString(_Period)+"\n"
      +"État : "+diag+"\n"
      +"Exposition cible : "+DoubleToString(100*fCible,1)+" %  ·  Levier : x"+DoubleToString(levVol,2)+" (vol "+DoubleToString(100*sigA,1)+" %)\n"
      +"Température : "+DoubleToString(100*dd,1)+" % / "+DoubleToString(DdMax,0)+" %  ·  Torpeur : "+DoubleToString(100*torpeur,0)+" %\n"
      +"Bouclier : "+(immun>0?("convalescence "+DoubleToString(immun,0)):"au repos")+"  ·  Anticorps : "+DoubleToString(anticorps,1)+"\n"
      +"Météo : score "+DoubleToString(scoreLocal,2)+" (min "+DoubleToString(SavaneMin,2)+") · entropie "+DoubleToString(100*entropie,1)+" % "+(savaneOk?"✓":"✗")+"\n"
      +"Le lion : "+alphaNoms[bi]+" "+IntegerToString(L[bi])+"b · forme "+DoubleToString(10000*bestFit,1)+" pb\n"
      +"Fond 252b : "+(fond>0?"haussier":"baissier")+"  ·  Naissances : "+IntegerToString(naissances)+"\n"
      +"Albatros (swaps) : "+DoubleToString(sigNow[16],2)+"  ·  Fourmis : "+(fourmisAlerte?"ORAGE":"calmes")+"\n";
   for(int i=0;i<NSP;i++)
      tbl += StringFormat("%s %db g%d %s · %.1f pb\n", alphaNoms[i], L[i], gen[i],
                          (sigNow[i]>0?"▲":(sigNow[i]<0?"▼":"—")), 10000*fit[i]);
   Comment(tbl);
}
//+------------------------------------------------------------------+
