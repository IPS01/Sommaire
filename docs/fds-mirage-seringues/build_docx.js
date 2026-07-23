// Génération de la FDS « Poste de mirage de seringues » (.docx)
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle, ShadingType,
  ImageRun, PageBreak, TableOfContents, LevelFormat, PageNumber, Footer, Header,
} = require("docx");

const DIR = __dirname;
const img = (f) => fs.readFileSync(path.join(DIR, f));

const FONT = "Calibri";
const CW = 9026; // largeur utile A4 (twips), marges 2,54 cm

// ---------------------------------------------------------------- helpers
const p = (text, opts = {}) =>
  new Paragraph({
    spacing: { after: 120, line: 276 },
    alignment: AlignmentType.JUSTIFIED,
    ...opts.para,
    children: [new TextRun({ text, font: FONT, size: 22, ...opts.run })],
  });

const pRuns = (runs, opts = {}) =>
  new Paragraph({
    spacing: { after: 120, line: 276 },
    alignment: AlignmentType.JUSTIFIED,
    ...opts,
    children: runs.map((r) => new TextRun({ font: FONT, size: 22, ...r })),
  });

const h1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 320, after: 160 }, children: [new TextRun({ text: t, font: FONT })] });
const h2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 240, after: 120 }, children: [new TextRun({ text: t, font: FONT })] });
const h3 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_3, spacing: { before: 200, after: 100 }, children: [new TextRun({ text: t, font: FONT })] });

const bullet = (t, level = 0) =>
  new Paragraph({
    numbering: { reference: "puces", level },
    spacing: { after: 60 },
    children: [new TextRun({ text: t, font: FONT, size: 22 })],
  });

const bulletRuns = (runs, level = 0) =>
  new Paragraph({
    numbering: { reference: "puces", level },
    spacing: { after: 60 },
    children: runs.map((r) => new TextRun({ font: FONT, size: 22, ...r })),
  });

const cell = (t, { widthDxa, bold = false, shade = null, align = AlignmentType.LEFT } = {}) =>
  new TableCell({
    width: { size: widthDxa, type: WidthType.DXA },
    shading: shade ? { type: ShadingType.CLEAR, fill: shade } : undefined,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: (Array.isArray(t) ? t : [t]).map(
      (line) =>
        new Paragraph({
          alignment: align,
          spacing: { after: 0 },
          children: [new TextRun({ text: String(line), font: FONT, size: 20, bold })],
        })
    ),
  });

function table(headers, rows, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        tableHeader: true,
        children: headers.map((h, i) => cell(h, { widthDxa: widths[i], bold: true, shade: "D9D9D9" })),
      }),
      ...rows.map(
        (r) => new TableRow({ children: r.map((c, i) => cell(c, { widthDxa: widths[i] })) })
      ),
    ],
  });
}

const figure = (file, w, h, caption) => [
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 160, after: 60 },
    children: [new ImageRun({ type: "png", data: img(file), transformation: { width: w, height: h } })],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
    children: [new TextRun({ text: caption, font: FONT, size: 20, italics: true })],
  }),
];

const spacer = () => new Paragraph({ spacing: { after: 120 }, children: [] });

// ---------------------------------------------------------------- contenu
const children = [];

// ===== page de garde
children.push(
  new Paragraph({ spacing: { before: 2400 }, children: [] }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "SPÉCIFICATION FONCTIONNELLE DÉTAILLÉE (FDS)", font: FONT, size: 52, bold: true })],
  }),
  new Paragraph({ spacing: { before: 300 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Poste de mirage de seringues sur link à pucks", font: FONT, size: 36 })] }),
  new Paragraph({ spacing: { before: 200 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Tourelle de transfert 2 pinces – mireuse externe – tri des non-conformes", font: FONT, size: 26, italics: true })] }),
  new Paragraph({ spacing: { before: 2000 }, alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Document : FDS-MIRAGE-001", font: FONT, size: 24 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Indice : A – 23/07/2026", font: FONT, size: 24 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER,
    children: [new TextRun({ text: "Statut : projet – à valider", font: FONT, size: 24 })] }),
  new Paragraph({ children: [new PageBreak()] })
);

// ===== sommaire
children.push(
  h1("Sommaire"),
  new TableOfContents("Sommaire", { hyperlink: true, headingStyleRange: "1-2" }),
  p("(Sous Word : clic droit sur le sommaire → « Mettre à jour les champs » pour générer la pagination.)", { run: { italics: true, size: 18 } }),
  new Paragraph({ children: [new PageBreak()] })
);

// ===== 1. objet
children.push(
  h1("1. Objet et périmètre"),
  p("Le présent document constitue la spécification fonctionnelle détaillée (FDS) du poste de mirage de seringues. Il décrit l'architecture retenue, les constituants de la partie opérative, les échanges avec la mireuse, le cycle de production, les modes de marche et d'arrêt, les sécurités, ainsi que les GRAFCET de commande (production, conduite, sécurité) conformes à la norme CEI 60848."),
  p("Périmètre : le poste comprend l'échappement amont (individualisation des pucks), le poste d'arrêt sur le link, la tourelle de transfert à deux pinces, l'interface avec la mireuse (équipement tiers à cycle autonome) et la goulotte d'éjection des seringues non conformes. Le link lui-même (motorisation, circulation générale des pucks) et le procédé optique de mirage sont hors périmètre : le link est supposé en marche permanente et la mireuse est vue comme une boîte noire échangeant des signaux tout-ou-rien."),
  p("Ce document est destiné à servir de base à la réalisation du programme automate, à la conception électrique/pneumatique et à la recette fonctionnelle du poste.")
);

// ===== 2. références
children.push(
  h1("2. Documents et normes de référence"),
  bullet("CEI 60848 – Langage de spécification GRAFCET pour diagrammes fonctionnels en séquence."),
  bullet("NF EN 13849-1 / ISO 13849-1 – Sécurité des machines, parties des systèmes de commande relatives à la sécurité."),
  bullet("ISO 12100 – Sécurité des machines, appréciation et réduction du risque."),
  bullet("NF EN 60204-1 – Équipement électrique des machines (arrêt d'urgence, catégories d'arrêt)."),
  bullet("GEMMA (ADEPA) – Guide d'étude des modes de marche et d'arrêt (utilisé comme guide, non déroulé exhaustivement, conformément au niveau de conduite retenu)."),
  p("Note : ce poste manipulant des seringues (produit pharmaceutique), la conception détaillée devra également être confrontée aux exigences BPF/GMP applicables (matériaux au contact, traçabilité, qualification). Ces aspects qualité sont signalés mais non développés ici.")
);

// ===== 3. description générale
children.push(
  h1("3. Description générale du système"),
  h2("3.1 Architecture"),
  p("Des pucks (porte-seringues individuels) circulent sur un convoyeur à accumulation (« link »). Le poste est implanté le long du link et se compose des éléments suivants :"),
  bullet("un échappement amont à deux stoppeurs : le stoppeur de sas ST2 individualise les pucks de la file d'accumulation et les libère un par un vers le poste ;"),
  bullet("un stoppeur de poste ST1 qui arrête le puck en position de travail, face à la tourelle ;"),
  bullet("une tourelle de transfert motorisée par un axe servo (positions 0°, 90° et 180°), portant deux pinces pneumatiques diamétralement opposées : la pince P1 (côté link à 0°) assure le transfert puck → mireuse, la pince P2 (côté mireuse à 0°) assure le transfert mireuse → puck ;"),
  bullet("une mireuse externe à cycle autonome : elle reçoit une seringue, la met en rotation devant le système d'inspection, puis signale la fin de son cycle et le verdict (conforme / non conforme) ;"),
  bullet("une goulotte de rebut placée sous la trajectoire de la pince P2 à la position intermédiaire 90° de la tourelle, pour l'éjection des seringues non conformes ;"),
  bullet("des capteurs de poste : présence puck au sas (dpa), présence puck au poste (dp), présence seringue dans le puck (ds, fibre optique)."),
  ...figure("fig1_synoptique.png", 600, 383, "Figure 1 – Synoptique du poste de mirage (vue schématique)"),
  h2("3.2 Principe de fonctionnement"),
  p("La rotation de la tourelle est alternée (0° → 180° en charge, puis 180° → 0° à vide). Les rôles des pinces sont donc fixes : P1 part toujours du côté link (prise de la seringue à mirer) et P2 part toujours du côté mireuse (reprise de la seringue mirée). Le croisement des deux pinces lors du basculement à 180° réalise l'échange simultané : la seringue neuve est présentée à la mireuse pendant que la seringue mirée est ramenée au-dessus du puck."),
  p("En régime établi, chaque cycle traite une seringue : le puck plein arrivant au poste est vidé par P1, attend sur place, puis reçoit la seringue mirée précédente déposée par P2 (si elle est conforme) avant d'être libéré. Le cycle de mirage se déroule pendant l'échange de pucks, ce qui masque son temps dans la cadence globale."),
  h2("3.3 Hypothèses et choix validés"),
  p("Les choix suivants ont été validés lors de l'analyse (voir annexe A pour le détail) :"),
  bullet("tourelle à 2 pinces opposées à 180°, rotation servo alternée avec position intermédiaire 90° ;"),
  bullet("mireuse externe restituant un contact « fin de cycle » (fcm) et le verdict m_ok / m_nok ;"),
  bullet("tri des non-conformes : éjection par ouverture de P2 à la position 90°, au-dessus de la goulotte de rebut ;"),
  bullet("actionneurs pneumatiques (pinces, stoppeurs) et axe de rotation servo ;"),
  bullet("poste d'arrêt unique : le même puck est vidé puis re-rempli au même emplacement ;"),
  bullet("détection plein/vide par capteur fibre optique au poste ;"),
  bullet("pas d'axe vertical : prise latérale, l'extraction et l'insertion de la seringue sont réalisées par le mouvement de bascule lui-même ;"),
  bullet("échappement amont à deux stoppeurs pour l'appel de puck ;"),
  bullet("conduite : grafcet de conduite (init / auto / arrêt fin de cycle) + grafcet de sécurité, hiérarchisés par forçage ; GEMMA non déroulé exhaustivement ;"),
  bullet("état initial de référence : tourelle à 0° (P1 côté link), pinces ouvertes et vides, stoppeurs sortis, mireuse vide.")
);

// ===== 4. analyse fonctionnelle
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("4. Analyse fonctionnelle"),
  h2("4.1 Fonction globale"),
  p("FG : « Contrôler visuellement (mirer) 100 % des seringues circulant sur le link et trier les non-conformes, sans rupture du flux de pucks. » La valeur ajoutée du poste est le contrôle qualité unitaire ; la matière d'œuvre est la seringue (état entrant : non contrôlée ; état sortant : contrôlée conforme dans son puck, ou éjectée au rebut)."),
  h2("4.2 Fonctions principales et contraintes"),
  table(
    ["Repère", "Fonction", "Critères / niveaux"],
    [
      ["FP1", "Individualiser et positionner les pucks au poste", "1 puck à la fois ; arrêt sans choc ; position répétable pour la prise pince"],
      ["FP2", "Discriminer puck plein / puck vide", "Détection fiable de la seringue (fibre optique) ; puck vide relâché sans action"],
      ["FP3", "Transférer la seringue du puck vers la mireuse", "Pince P1 ; prise latérale sans marquage du corps de seringue ; aucune chute"],
      ["FP4", "Mirer la seringue", "Délégué à la mireuse (cycle autonome) ; verdict OK/NOK restitué au poste"],
      ["FP5", "Restituer la seringue conforme dans un puck", "Pince P2 ; dépose dans le puck présent au poste avant libération"],
      ["FP6", "Éjecter la seringue non conforme", "Ouverture P2 à 90° au-dessus de la goulotte ; comptage des rebuts"],
      ["FC1", "Assurer la sécurité des personnes", "AU catégorie 0/1 selon analyse de risque ; maintien des pièces saisies ; carters"],
      ["FC2", "Préserver le produit", "Pas de chute libre de seringue hors goulotte ; efforts de serrage limités"],
      ["FC3", "S'interfacer avec le link et la mireuse", "Link en marche permanente ; échanges TOR avec la mireuse (§ 6)"],
      ["FC4", "Être conduit par un opérateur", "Pupitre : dcy, acy, init, réarmement, AU ; voyants d'état ; mode MANU de dégagement"],
      ["FC5", "Assurer la traçabilité de production", "Compteurs totaux / rebuts ; alarmes horodatées (supervision, option)"],
    ],
    [900, 3500, 4626]
  )
);

// ===== 5. partie opérative
children.push(
  h1("5. Constituants de la partie opérative"),
  h2("5.1 Actionneurs et préactionneurs"),
  table(
    ["Repère", "Actionneur", "Technologie", "Préactionneur", "Capteurs associés"],
    [
      ["P1", "Pince de transfert puck → mireuse", "Pince pneumatique 2 doigts", "Distributeur 5/2 bistable (YV_P1F / YV_P1O)", "ILS p1_o (ouverte), p1_f (fermée)"],
      ["P2", "Pince de transfert mireuse → puck / rebut", "Pince pneumatique 2 doigts", "Distributeur 5/2 bistable (YV_P2F / YV_P2O)", "ILS p2_o, p2_f"],
      ["R", "Rotation tourelle 0° / 90° / 180°", "Axe servo (variateur + moteur brushless)", "Variateur (consignes C_R0 / C_R90 / C_R180, validation SRV_EN)", "Retours variateur r0, r90, r180 (en position), servo_rdy, servo_flt"],
      ["ST1", "Stoppeur de poste", "Vérin simple effet, sorti au repos (ressort)", "Distributeur 3/2 monostable (YV_ST1 = rentrer)", "ILS st1_s (sorti), st1_r (rentré)"],
      ["ST2", "Stoppeur de sas (échappement amont)", "Vérin simple effet, sorti au repos (ressort)", "Distributeur 3/2 monostable (YV_ST2 = rentrer)", "ILS st2_s, st2_r"],
    ],
    [700, 2300, 2200, 2200, 1626]
  ),
  p("Choix de sûreté : les distributeurs des pinces sont bistables afin que la perte d'énergie électrique (AU) n'ouvre pas les pinces et ne fasse pas chuter une seringue. Les stoppeurs sont monostables « sortis au repos » : sur coupure, tout puck en approche est arrêté. La rotation servo est mise hors couple (STO) sur arrêt d'urgence.", { run: { italics: true } }),
  h2("5.2 Capteurs de poste"),
  table(
    ["Mnémonique", "Désignation", "Technologie", "Implantation"],
    [
      ["dpa", "Présence puck au sas amont", "Inductif (masse métallique du puck)", "Devant ST2"],
      ["dp", "Présence puck au poste", "Inductif", "Devant ST1"],
      ["ds", "Présence seringue dans le puck au poste", "Fibre optique (barrage/reflex)", "Au droit du col de la seringue, puck arrêté sur ST1"],
      ["ps_air", "Pression réseau air OK", "Pressostat", "Arrivée d'air, en aval du sectionneur"],
      ["br_plein", "Bac de rebut plein (option)", "Optique / niveau", "Goulotte de rebut"],
    ],
    [1400, 3300, 2500, 1826]
  )
);

// ===== 6. interface mireuse
children.push(
  h1("6. Interface avec la mireuse"),
  p("La mireuse est un équipement tiers à cycle autonome. L'échange se fait par signaux tout-ou-rien câblés (contacts secs) ou par bus de terrain selon la définition électrique ; la présente FDS retient la sémantique suivante :"),
  table(
    ["Sens", "Signal", "Signification"],
    [
      ["Poste → mireuse", "SER_M", "Ordre de serrage de la seringue présentée par P1 (prise en broche)"],
      ["Poste → mireuse", "LIB_M", "Ordre de libération de la seringue mirée (pour reprise par P2)"],
      ["Poste → mireuse", "DCM", "Départ cycle mirage (impulsion)"],
      ["Mireuse → poste", "m_prete", "Mireuse prête (initialisée, sans défaut)"],
      ["Mireuse → poste", "m_ser", "Seringue serrée en broche (dépose P1 possible → ouverture P1)"],
      ["Mireuse → poste", "m_lib", "Seringue libérée par la broche (extraction P2 possible)"],
      ["Mireuse → poste", "m_enc", "Cycle mirage en cours"],
      ["Mireuse → poste", "fcm", "Fin de cycle mirage (impulsion ou état, mémorisée par l'automate)"],
      ["Mireuse → poste", "m_ok / m_nok", "Verdict du mirage, valide à fcm et maintenu jusqu'au cycle suivant"],
    ],
    [1900, 1500, 5626]
  ),
  p("Hypothèse de synchronisation : le couple (fcm ; m_ok/m_nok) reste stable jusqu'au démarrage du cycle suivant (DCM). L'automate mémorise le verdict dans la variable interne MNOK dès la reprise de la seringue par P2 (étape 12 du GP).")
);

// ===== 7. E/S automate
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("7. Table des entrées / sorties automate"),
  h2("7.1 Entrées TOR"),
  table(
    ["Mnémonique", "Désignation", "Origine"],
    [
      ["au", "Arrêt d'urgence (retour relais de sécurité, 2 canaux)", "Pupitre / relais de sécurité"],
      ["bp_dcy", "BP départ cycle", "Pupitre"],
      ["bp_acy", "BP arrêt en fin de cycle", "Pupitre"],
      ["bp_init", "BP initialisation / prise de référence", "Pupitre"],
      ["bp_rearm", "BP réarmement défaut", "Pupitre"],
      ["bp_valid", "BP validation remise en état (après défaut grave)", "Pupitre"],
      ["cs_manu", "Commutateur AUTO / MANU", "Pupitre"],
      ["dpa", "Présence puck au sas amont", "Capteur inductif"],
      ["dp", "Présence puck au poste", "Capteur inductif"],
      ["ds", "Présence seringue dans le puck", "Fibre optique"],
      ["p1_o / p1_f", "Pince P1 ouverte / fermée", "ILS pince"],
      ["p2_o / p2_f", "Pince P2 ouverte / fermée", "ILS pince"],
      ["st1_s / st1_r", "Stoppeur poste sorti / rentré", "ILS vérin"],
      ["st2_s / st2_r", "Stoppeur sas sorti / rentré", "ILS vérin"],
      ["r0 / r90 / r180", "Tourelle en position 0° / 90° / 180°", "Variateur servo"],
      ["servo_rdy", "Variateur prêt", "Variateur servo"],
      ["servo_flt", "Défaut variateur", "Variateur servo"],
      ["m_prete, m_ser, m_lib, m_enc, fcm, m_ok, m_nok", "Signaux mireuse (voir § 6)", "Mireuse"],
      ["ps_air", "Pression air OK", "Pressostat"],
      ["br_plein", "Bac rebut plein (option)", "Capteur niveau"],
    ],
    [2300, 4600, 2126]
  ),
  h2("7.2 Sorties TOR"),
  table(
    ["Mnémonique", "Désignation", "Destination"],
    [
      ["YV_P1F / YV_P1O", "Fermeture / ouverture pince P1", "Distributeur 5/2 bistable"],
      ["YV_P2F / YV_P2O", "Fermeture / ouverture pince P2", "Distributeur 5/2 bistable"],
      ["YV_ST1", "Rentrer stoppeur poste (libération puck)", "Distributeur 3/2 monostable"],
      ["YV_ST2", "Rentrer stoppeur sas (appel puck)", "Distributeur 3/2 monostable"],
      ["SRV_EN", "Validation variateur servo", "Variateur"],
      ["C_R0 / C_R90 / C_R180", "Consignes de position tourelle (ou consigne + top départ via bus)", "Variateur"],
      ["SER_M / LIB_M", "Serrage / libération broche mireuse", "Mireuse"],
      ["DCM", "Départ cycle mirage (impulsion)", "Mireuse"],
      ["V_HS, V_INIT, V_PRET, V_AUTO, V_DEF", "Voyants d'état pupitre (hors service, init, prêt, auto, défaut)", "Pupitre / colonne lumineuse"],
    ],
    [2500, 4400, 2126]
  ),
  p("Correspondance actions GRAFCET → sorties : FP1 ≡ YV_P1F, OP1 ≡ YV_P1O, FP2 ≡ YV_P2F, OP2 ≡ YV_P2O, R0/R90/R180 ≡ C_R0/C_R90/C_R180 (avec SRV_EN maintenu en marche). Les électrovannes bistables sont pilotées par impulsion maintenue pendant l'étape.", { run: { italics: true } }),
  h2("7.3 Variables internes, temporisations et compteurs"),
  table(
    ["Repère", "Type", "Rôle"],
    [
      ["SM", "Bit mémorisé", "« Mireuse chargée » : mis à 1 à la première dépose en mireuse (étape 18), remis à 0 par l'initialisation. Conditionne la reprise par P2 (amorçage)"],
      ["MNOK", "Bit mémorisé", "Verdict mémorisé de la seringue portée par P2 (1 = non conforme). Chargé à l'étape 12 (MNOK := m_nok), remis à 0 à l'étape 18"],
      ["AUTO", "Bit", "Autorisation de production, émis par le grafcet de conduite (étapes 103/104)"],
      ["T3", "Tempo 0,3 s", "Stabilisation du puck sur le stoppeur avant lecture de ds"],
      ["T15", "Tempo 0,5 s", "Temps de chute de la seringue rebutée avant reprise de rotation"],
      ["TS", "Tempo 3 s (param.)", "Surveillance de chaque mouvement (pince, stoppeur, rotation, échanges mireuse) → défaut def_tempo"],
      ["CT", "Compteur", "Nombre de seringues mirées (incrémenté à chaque DCM)"],
      ["CR", "Compteur", "Nombre de seringues rebutées (incrémenté à l'étape 15)"],
    ],
    [1300, 1700, 6026]
  )
);

// ===== 8. cycle détaillé
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("8. Description détaillée du cycle de production"),
  h2("8.1 Conditions initiales (CI)"),
  p("CI = tourelle en position 0° (r0) · pinces P1 et P2 ouvertes (p1_o · p2_o) · stoppeurs sortis (st1_s · st2_s). À la première initialisation la mireuse est vide (SM = 0) ; après un arrêt en fin de cycle, une seringue peut légitimement rester en mireuse (SM = 1) : le cycle reprend alors sans amorçage."),
  h2("8.2 Cycle nominal (régime établi, SM = 1)"),
  bullet("Appel de puck : ST2 se rétracte, le puck du sas est libéré (front descendant de dpa), ST2 ressort et retient la file."),
  bullet("Le puck arrive au poste et s'arrête sur ST1 (dp) ; après stabilisation (T3), lecture du capteur seringue ds."),
  bullet("Puck plein : P1 se ferme sur la seringue du puck (FP1 → p1_f)."),
  bullet("Attente de la fin du cycle de mirage en cours (fcm) si celui-ci n'est pas terminé."),
  bullet("Reprise de la seringue mirée : P2 se ferme (FP2), la mireuse libère la broche (LIB_M → m_lib) ; le verdict est mémorisé (MNOK := m_nok)."),
  bullet("Bascule 0° → 180° : si MNOK, arrêt intermédiaire à 90°, ouverture de P2 au-dessus de la goulotte (éjection, CR := CR+1, tempo T15), puis poursuite vers 180° ; sinon rotation directe vers 180°."),
  bullet("À 180° : double dépose simultanée — P1 s'ouvre après serrage broche (SER_M → m_ser) : la seringue neuve est en mireuse ; P2 s'ouvre au-dessus du puck : la seringue conforme est restituée (si elle a été rebutée, P2 est déjà vide et le puck repartira vide)."),
  bullet("Départ du cycle de mirage (DCM, CT := CT+1)."),
  bullet("En parallèle : libération du puck (ST1 rentre, départ du puck, ST1 ressort) et retour à vide de la tourelle 180° → 0°."),
  bullet("Reprise en début de cycle : appel du puck suivant. Le mirage se déroule pendant tout l'échange de pucks."),
  h2("8.3 Cas particuliers"),
  h3("a) Puck vide"),
  p("Si, après T3, ds est absent, le puck est vide : ST1 se rétracte, le puck est laissé partir sans action (front descendant de dp), ST1 ressort, et un nouveau puck est appelé. Aucune interaction avec la tourelle ni la mireuse."),
  h3("b) Amorçage (mireuse vide, SM = 0)"),
  p("Au premier cycle après initialisation, il n'y a pas de seringue à reprendre en mireuse : après la prise par P1, le grafcet saute directement à la bascule (P2 reste ouverte et vide). À 180°, seule la dépose en mireuse a lieu ; le puck, vidé de sa seringue, est libéré vide. Le régime établi est atteint dès ce premier cycle (SM := 1)."),
  h3("c) Seringue non conforme"),
  p("Le verdict m_nok mémorisé (MNOK) provoque l'arrêt de la rotation à 90° : P2 s'ouvre au-dessus de la goulotte de rebut, la seringue tombe (T15), le compteur CR est incrémenté, puis la rotation s'achève à 180°. Le puck en attente repart donc vide ; les pucks vides étant relâchés sans action au poste (cas a), ils poursuivent leur circulation sur le link."),
  h3("d) File amont vide"),
  p("Si aucun puck ne se présente au sas (dpa = 0), l'étape d'appel reste active : le poste attend sans défaut. Une alarme de « famine amont » temporisée (option supervision) peut être ajoutée."),
  h2("8.4 Cadence prévisionnelle"),
  p("Ordres de grandeur retenus pour le dimensionnement (à confirmer aux essais) : prise/dépose pince 0,3 s ; bascule 180° ≈ 1,2 s (1,8 s avec arrêt rebut à 90°) ; retour à vide ≈ 1,2 s ; échange de puck (libération + appel + stabilisation) ≈ 2 s, masqué par le retour tourelle. Le temps de cycle du poste hors mirage est d'environ 4 s ; la cadence réelle est imposée par la durée du cycle de mirage dès que celui-ci excède l'échange (cadence = max(≈ 4 s ; durée mirage))."),
);

// ===== 9. modes de marche
children.push(
  h1("9. Modes de marche et d'arrêt"),
  h2("9.1 Modes retenus"),
  bullet("Initialisation / prise de référence (GC étape 101) : ouverture des pinces, référencement servo et retour à 0°, vérification des CI. Précondition : machine vide de seringues (sinon passage préalable en MANU pour dégager)."),
  bullet("Marche automatique (GC étape 103) : production en boucle, autorisée par le bit AUTO."),
  bullet("Arrêt en fin de cycle (GC étape 104) : sur bp_acy, le cycle en cours s'achève (GP revient à l'étape 0, seringue en mireuse conservée), puis la machine s'arrête prête à redémarrer."),
  bullet("Mode manuel (cs_manu, hors GRAFCET de production) : commandes unitaires sous conditions de non-collision — ouvrir/fermer chaque pince, rentrer chaque stoppeur, rotation pas à pas 0/90/180°, serrage/libération broche mireuse. Utilisé pour la remise en état (dégagement des seringues) après défaut grave."),
  bullet("Arrêt d'urgence / défaut grave (GS étapes 201-202) : voir § 10."),
  h2("9.2 Conduite opérateur"),
  p("Pupitre : BP dcy (départ), BP acy (arrêt fin de cycle), BP init, BP réarmement, BP validation, commutateur AUTO/MANU, coup de poing AU. Voyants : V_HS (hors service), V_INIT (initialisation en cours, clignotant), V_PRET (prêt), V_AUTO (production ; clignotant = arrêt fin de cycle demandé), V_DEF (défaut ; fixe = à réarmer, clignotant = remise en état requise).")
);

// ===== 10. sécurité
children.push(
  h1("10. Sécurités, défauts et alarmes"),
  h2("10.1 Fonctions de sécurité"),
  bullet("Arrêt d'urgence (coup de poing, 2 canaux sur relais/PLC de sécurité) : mise hors couple du servo (STO), inhibition des ordres de mouvement. Les distributeurs bistables des pinces conservent leur position : les seringues saisies ne tombent pas. Les stoppeurs monostables ressortent : le flux de pucks est arrêté. Catégorie d'arrêt 0 ou 1 et niveau PL requis à confirmer par l'analyse de risque ISO 13849."),
  bullet("Protection périmétrique : carters fixes + porte(s) avec interverrouillage traité comme l'AU (même réaction), à définir à la conception mécanique."),
  bullet("Sur retour d'énergie ou après AU : aucune reprise automatique ; réarmement, remise en état manuelle si nécessaire, puis réinitialisation complète (forçage GP → étape 0, GC → étape 100)."),
  h2("10.2 Défauts surveillés"),
  table(
    ["Défaut", "Détection", "Réaction", "Réarmement"],
    [
      ["Arrêt d'urgence", "au", "GS 201 : figeage GP, STO servo", "Déverrouiller AU, bp_rearm, remise en état, bp_valid, réinit"],
      ["Chute pression air", "/ps_air (pressostat)", "Idem AU (défaut grave)", "Idem"],
      ["Défaut variateur", "servo_flt", "Idem AU (défaut grave)", "Idem + acquit variateur"],
      ["Timeout mouvement", "TS (3 s) sur chaque transition de mouvement", "Idem AU (défaut grave) : pince/stoppeur/rotation non conforme au modèle", "Idem"],
      ["Incohérence capteur", "p1_o·p1_f (etc.) simultanés", "Défaut grave", "Idem + contrôle capteur"],
      ["Mireuse non prête", "/m_prete en production", "Fin du mouvement en cours puis arrêt (équivalent arrêt fin de cycle) + alarme", "Retour m_prete, dcy"],
      ["Bac rebut plein (option)", "br_plein", "Alarme non bloquante puis blocage au prochain rebut", "Vidange bac, acquit"],
    ],
    [2100, 2400, 2700, 1826]
  ),
  p("Toute perte de la seringue en cours de transfert (pince fermée sans pièce — détectable en option par contrôle de course de doigts ou capteur dans les mors) doit être traitée comme défaut grave : arrêt immédiat, la zone devant être inspectée avant redémarrage (bris de verre potentiel).", { run: { italics: true } })
);

// ===== 11. grafcets
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("11. GRAFCET (CEI 60848)"),
  h2("11.1 Structure hiérarchique"),
  p("La commande est structurée en trois grafcets hiérarchisés par forçage :"),
  bullet("GS – grafcet de sécurité (étapes 200-202) : niveau le plus prioritaire ; il fige puis réinitialise les autres grafcets sur défaut grave ;"),
  bullet("GC – grafcet de conduite (étapes 100-104) : gère l'initialisation, la mise en/hors production (bit AUTO) et l'arrêt en fin de cycle ;"),
  bullet("GP – grafcet de production (étapes 0-23) : cycle décrit au § 8 ; il n'évolue que si AUTO = 1 (réceptivité de sa transition initiale, l'étape 0 n'étant réactivée qu'en fin de cycle)."),
  p("Notations : « · » = ET logique, « + » = OU logique, « /x » = complément (NON x), « [v := e] » = affectation exécutée à l'activation de l'étape, « F/GP:{0} » = forçage du grafcet GP dans la situation {étape 0}, « F/GP:(*) » = figeage dans la situation courante, « X0(GP) » = variable d'état de l'étape 0 de GP."),
  h2("11.2 GP – Grafcet de production"),
  ...figure("fig2_gp.png", 430, 884, "Figure 2 – GRAFCET de production GP (point de vue partie commande)"),
  h3("Table des étapes du GP"),
  table(
    ["Étape", "Rôle", "Actions / affectations", "Transition aval (réceptivité)"],
    [
      ["0 (init)", "Attente autorisation de production", "—", "AUTO · CI"],
      ["1", "Appel d'un puck (sas)", "YV_ST2 (rentrer stoppeur sas)", "/dpa (puck libéré du sas)"],
      ["2", "Attente arrivée au poste (ST2 ressorti)", "—", "dp"],
      ["3", "Stabilisation puck", "T3 (0,3 s)", "t3·ds → 10  |  t3·/ds → 4"],
      ["4", "Puck vide : libération", "YV_ST1", "/dp"],
      ["5", "Attente ST1 ressorti", "—", "st1_s → reprise en 1"],
      ["10", "Prise de la seringue du puck", "FP1", "p1_f·SM → 11  |  p1_f·/SM → 13 (amorçage)"],
      ["11", "Attente fin de mirage", "—", "fcm"],
      ["12", "Reprise seringue mirée", "FP2 · LIB_M ; [MNOK := m_nok]", "p2_f · m_lib"],
      ["13", "Prêt à basculer", "—", "MNOK → 14  |  /MNOK → 17"],
      ["14", "Rotation vers 90° (rebut)", "R90", "r90"],
      ["15", "Éjection rebut", "OP2 ; T15 (0,5 s) ; [CR := CR+1]", "p2_o · t15"],
      ["16", "Fin de rotation", "R180", "r180"],
      ["17", "Rotation directe (seringue OK)", "R180", "r180"],
      ["18", "Double dépose (mireuse + puck)", "OP1 · OP2 · SER_M ; [SM := 1 ; MNOK := 0]", "p1_o · p2_o · m_ser"],
      ["19", "Départ mirage", "DCM ; [CT := CT+1]", "m_enc — puis divergence ET"],
      ["20 / 21", "Branche a : libération du puck", "YV_ST1 puis attente", "/dp puis convergence"],
      ["22 / 23", "Branche b : retour tourelle", "R0 puis attente", "r0 puis convergence"],
      ["conv. ET", "Synchronisation", "—", "st1_s → reprise en 1"],
    ],
    [1000, 2600, 2900, 2526]
  ),
  h2("11.3 GC – Grafcet de conduite"),
  ...figure("fig3_gc.png", 450, 611, "Figure 3 – GRAFCET de conduite GC"),
  p("L'arrêt en fin de cycle (étape 104) maintient AUTO jusqu'au retour du GP en étape 0 : le poste termine proprement (seringue en mireuse conservée, puck libéré), puis revient « prêt » (étape 102). L'initialisation (étape 101) n'est autorisée que si la sécurité est en surveillance (GS en 200)."),
  h2("11.4 GS – Grafcet de sécurité"),
  ...figure("fig4_gs.png", 600, 400, "Figure 4 – GRAFCET de sécurité GS"),
  p("Sur défaut grave (AU, pression, variateur, timeout), l'étape 201 fige le GP dans sa situation (les pinces bistables maintiennent les seringues) et coupe le couple servo. Après disparition du défaut et réarmement, l'étape 202 force GP en {0} et GC en {100} : l'opérateur remet la machine en état en mode MANU (dégagement des seringues des pinces, de la mireuse et vérification de la goulotte), puis valide (bp_valid) ; une réinitialisation complète est alors exigée avant toute reprise.")
);

// ===== 12. recette
children.push(
  h1("12. Points de recette fonctionnelle"),
  bullet("Séquence nominale complète sur 20 cycles consécutifs sans défaut, verdicts OK simulés puis réels."),
  bullet("Cas puck vide : relâché sans action ; enchaînement immédiat sur le puck suivant."),
  bullet("Amorçage : premier cycle après init (mireuse vide) puis régime établi."),
  bullet("Rebut : verdict NOK simulé → arrêt à 90°, éjection en goulotte, comptage CR, puck relâché vide."),
  bullet("Arrêt fin de cycle en tout point du cycle : achèvement propre, redémarrage sans amorçage."),
  bullet("AU dans chaque phase (prise, rotation chargée, dépose) : aucune chute de seringue, remise en état MANU, réinit et reprise."),
  bullet("Timeouts : simulation capteur masqué (p1_f, r180, m_ser…) → défaut grave en moins de TS."),
  bullet("Famine amont et mireuse non prête : comportements d'attente/alarme conformes au § 8.3 et § 10.2.")
);

// ===== annexe A
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("Annexe A – Choix de conception validés (questions / réponses)"),
  table(
    ["#", "Question", "Réponse retenue"],
    [
      ["1", "Architecture des pinces", "Tourelle à 2 pinces opposées à 180° sur le même axe rotatif"],
      ["2", "Fin du cycle de mirage / verdict", "Signal externe « fin de cycle » (fcm) restitué par la mireuse, avec verdict m_ok / m_nok"],
      ["3", "Devenir des seringues après mirage", "Tri : seringue NOK éjectée, seringue OK restituée au puck"],
      ["4", "Technologie des actionneurs", "Mixte : pinces et stoppeurs pneumatiques, rotation par axe servo"],
      ["5", "Flux des pucks au poste", "Poste d'arrêt unique : le puck est vidé (P1) puis re-rempli (P2) au même emplacement"],
      ["6", "Détection plein / vide", "Capteur fibre optique au poste (ds)"],
      ["7", "Axe vertical", "Aucun : prise latérale, extraction/insertion par le mouvement de bascule"],
      ["8", "Éjection des NOK", "Position servo intermédiaire dédiée (90°) au-dessus de la goulotte de rebut"],
      ["9", "Appel de puck", "Échappement amont à 2 stoppeurs (sas) individualisant les pucks"],
      ["10", "Niveau de conduite", "GRAFCET de conduite + production + sécurité hiérarchisés (GEMMA non déroulé)"],
      ["11", "État initial de référence", "Tourelle à 0° (P1 côté link), pinces ouvertes, stoppeurs sortis, mireuse vide"],
    ],
    [500, 3400, 5126]
  ),
  spacer(),
  p("Fin du document.", { run: { italics: true }, para: { alignment: AlignmentType.CENTER } })
);

// ---------------------------------------------------------------- document
const doc = new Document({
  creator: "Bureau d'études automatisme",
  title: "FDS – Poste de mirage de seringues",
  description: "Spécification fonctionnelle détaillée et GRAFCET",
  styles: {
    default: {
      document: { run: { font: FONT, size: 22 } },
      heading1: { run: { font: FONT, size: 30, bold: true, color: "1F3864" }, paragraph: { spacing: { before: 320, after: 160 } } },
      heading2: { run: { font: FONT, size: 26, bold: true, color: "2E5395" }, paragraph: { spacing: { before: 240, after: 120 } } },
      heading3: { run: { font: FONT, size: 23, bold: true, color: "404040" }, paragraph: { spacing: { before: 200, after: 100 } } },
    },
  },
  numbering: {
    config: [
      {
        reference: "puces",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "–", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 480, hanging: 240 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 960, hanging: 240 } } } },
        ],
      },
    ],
  },
  features: { updateFields: true },
  sections: [
    {
      properties: {
        page: { margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } },
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: "FDS-MIRAGE-001 – ind. A    |    page ", font: FONT, size: 18 }),
                new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18 }),
                new TextRun({ text: " / ", font: FONT, size: 18 }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 18 }),
              ],
            }),
          ],
        }),
      },
      children,
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(path.join(DIR, "FDS_mirage_seringues.docx"), buf);
  console.log("OK FDS_mirage_seringues.docx", buf.length, "octets");
});
