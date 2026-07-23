# -*- coding: utf-8 -*-
"""Dessin des figures FDS mirage seringues : synoptique + GRAFCET GP/GC/GS."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyArrow, Circle, Polygon
import os

OUT = os.path.dirname(os.path.abspath(__file__))
S = 0.9          # côté du carré d'étape
DY = 2.0         # pas vertical entre étapes
LW = 1.4
FS = 9           # taille police de base

# ---------------------------------------------------------------- primitives
def step(ax, x, y, num, actions=None, initial=False, act_dx=None, act_w=None):
    """Étape GRAFCET : carré (double si initiale), n° centré, rectangle d'actions à droite."""
    ax.add_patch(Rectangle((x - S/2, y - S/2), S, S, fill=True, fc="white", ec="black", lw=LW, zorder=3))
    if initial:
        m = 0.10
        ax.add_patch(Rectangle((x - S/2 + m, y - S/2 + m), S - 2*m, S - 2*m,
                               fill=False, ec="black", lw=LW, zorder=3))
    ax.text(x, y, str(num), ha="center", va="center", fontsize=FS+1, zorder=4)
    if actions:
        lines = actions if isinstance(actions, list) else [actions]
        w = act_w if act_w else max(1.6, 0.168 * max(len(l) for l in lines) + 0.45)
        h = 0.42 * len(lines) + 0.18
        dx = act_dx if act_dx else 0.55
        ax.plot([x + S/2, x + S/2 + dx], [y, y], color="black", lw=LW, zorder=2)
        ax.add_patch(Rectangle((x + S/2 + dx, y - h/2), w, h, fill=True, fc="white",
                               ec="black", lw=LW, zorder=3))
        for i, l in enumerate(lines):
            yy = y + h/2 - 0.30 - 0.42 * i
            ax.text(x + S/2 + dx + 0.12, yy, l, ha="left", va="center", fontsize=FS-0.5, zorder=4)

def trans(ax, x, y, recept, side="right"):
    """Transition : barre horizontale + réceptivité."""
    ax.plot([x - 0.22, x + 0.22], [y, y], color="black", lw=2.6, zorder=3)
    if side == "right":
        ax.text(x + 0.34, y, recept, ha="left", va="center", fontsize=FS-0.5, zorder=4)
    else:
        ax.text(x - 0.34, y, recept, ha="right", va="center", fontsize=FS-0.5, zorder=4)

def vline(ax, x, y1, y2):
    ax.plot([x, x], [y1, y2], color="black", lw=LW, zorder=1)

def hline(ax, x1, x2, y, double=False):
    ax.plot([x1, x2], [y, y], color="black", lw=LW, zorder=1)
    if double:
        ax.plot([x1, x2], [y - 0.10, y - 0.10], color="black", lw=LW, zorder=1)

def arrow_into(ax, x, y_from, y_to):
    """Flèche verticale descendante arrivant sur une étape (saut/reprise)."""
    ax.annotate("", xy=(x, y_to), xytext=(x, y_from),
                arrowprops=dict(arrowstyle="-|>", color="black", lw=LW))

def fig_new(w, h):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.set_aspect("equal")
    ax.axis("off")
    return fig, ax

def save(fig, ax, name, pad=0.55):
    ax.relim(); ax.autoscale_view()
    fig.savefig(os.path.join(OUT, name), dpi=200, bbox_inches="tight", pad_inches=pad/2.54)
    plt.close(fig)
    print("OK", name)

# ================================================================ FIG 1 : synoptique
def fig_synoptique():
    fig, ax = fig_new(11, 7.5)
    # --- link (convoyeur) horizontal
    ax.add_patch(Rectangle((0, 0), 16, 1.4, fill=True, fc="#eeeeee", ec="black", lw=1.2))
    ax.annotate("", xy=(15.6, 0.7), xytext=(13.9, 0.7),
                arrowprops=dict(arrowstyle="-|>", color="black", lw=1.6))
    ax.text(15.0, -0.55, "sens link", ha="center", fontsize=FS)
    # pucks en attente (file amont)
    for i, cx in enumerate([1.2, 2.4, 3.6]):
        ax.add_patch(Circle((cx, 0.7), 0.52, fill=True, fc="white", ec="black", lw=1.2))
        ax.add_patch(Circle((cx, 0.7), 0.16, fill=True, fc="#888888", ec="black", lw=0.8))
    ax.text(2.4, 1.75, "file de pucks", ha="center", fontsize=FS)
    # puck au sas
    ax.add_patch(Circle((5.6, 0.7), 0.52, fill=True, fc="white", ec="black", lw=1.2))
    ax.add_patch(Circle((5.6, 0.7), 0.16, fill=True, fc="#888888", ec="black", lw=0.8))
    # puck au poste
    ax.add_patch(Circle((9.6, 0.7), 0.52, fill=True, fc="white", ec="black", lw=1.2))
    ax.add_patch(Circle((9.6, 0.7), 0.16, fill=True, fc="#888888", ec="black", lw=0.8))
    # stoppeurs (triangles sous le link)
    for xs, name in [(4.45, "ST2\n(sas amont)"), (6.55, "ST2b"), (10.45, "ST1\n(poste)")]:
        pass
    # échappement amont : stoppeur sas ST2
    ax.add_patch(Polygon([(6.35, 0.0), (6.75, 0.0), (6.55, -0.65)], closed=True,
                         fc="#bbbbbb", ec="black", lw=1.2))
    ax.text(6.55, -1.15, "ST2 – stoppeur sas\n(échappement amont)", ha="center", va="top", fontsize=FS-0.5)
    ax.text(5.6, 1.75, "dpa", ha="center", fontsize=FS-0.5, style="italic")
    ax.plot([5.6, 5.6], [1.25, 1.6], color="black", lw=0.9)
    # stoppeur poste ST1
    ax.add_patch(Polygon([(10.25, 0.0), (10.65, 0.0), (10.45, -0.65)], closed=True,
                         fc="#bbbbbb", ec="black", lw=1.2))
    ax.text(10.45, -1.15, "ST1 – stoppeur poste", ha="center", va="top", fontsize=FS-0.5)
    # capteurs poste
    ax.text(8.55, 1.75, "dp / ds", ha="center", fontsize=FS-0.5, style="italic")
    ax.plot([9.15, 8.75], [1.05, 1.6], color="black", lw=0.9)
    # --- tourelle
    tx, ty = 9.6, 4.2
    ax.add_patch(Circle((tx, ty), 1.05, fill=True, fc="#dddddd", ec="black", lw=1.4))
    ax.text(tx, ty, "Tourelle\nservo R\n0°/90°/180°", ha="center", va="center", fontsize=FS-1)
    # pince 1 (vers link, en bas)
    ax.plot([tx, tx], [ty - 1.05, ty - 2.0], color="black", lw=2.4)
    ax.add_patch(Rectangle((tx - 0.38, ty - 2.55), 0.76, 0.55, fill=True, fc="white", ec="black", lw=1.2))
    ax.text(tx + 0.62, ty - 2.28, "P1", fontsize=FS+1)
    ax.text(tx + 0.62, ty - 2.75, "(prise puck)", fontsize=FS-1.5)
    # pince 2 (vers mireuse, en haut)
    ax.plot([tx, tx], [ty + 1.05, ty + 2.0], color="black", lw=2.4)
    ax.add_patch(Rectangle((tx - 0.38, ty + 2.0), 0.76, 0.55, fill=True, fc="white", ec="black", lw=1.2))
    ax.text(tx + 0.62, ty + 2.28, "P2", fontsize=FS+1)
    ax.text(tx + 0.62, ty + 1.82, "(prise mireuse)", fontsize=FS-1.5)
    # rotation
    ax.annotate("", xy=(tx - 1.45, ty + 0.75), xytext=(tx - 1.45, ty - 0.75),
                arrowprops=dict(arrowstyle="<|-|>", color="black", lw=1.3,
                                connectionstyle="arc3,rad=0.45"))
    ax.text(tx - 2.25, ty, "rotation\n0° ↔ 180°", ha="center", va="center", fontsize=FS-1)
    # --- mireuse
    ax.add_patch(Rectangle((8.0, 7.0), 3.2, 1.7, fill=True, fc="#eeeeee", ec="black", lw=1.4))
    ax.text(9.6, 7.85, "MIREUSE\n(cycle autonome)", ha="center", va="center", fontsize=FS)
    ax.text(11.45, 7.85, "fcm, m_ok/m_nok", ha="left", va="center", fontsize=FS-1, style="italic")
    # --- goulotte rebut (position 90°)
    gx = 13.1
    ax.add_patch(Polygon([(gx - 0.55, 4.9), (gx + 0.55, 4.9), (gx + 0.3, 3.6), (gx - 0.3, 3.6)],
                         closed=True, fc="#eeeeee", ec="black", lw=1.2))
    ax.text(gx, 3.15, "goulotte rebut\n(position 90°)", ha="center", va="top", fontsize=FS-0.5)
    ax.annotate("", xy=(gx - 0.15, 5.15), xytext=(tx + 1.1, ty + 0.55),
                arrowprops=dict(arrowstyle="-|>", color="#555555", lw=1.1, linestyle="--"))
    save(fig, ax, "fig1_synoptique.png")

# ================================================================ FIG 2 : GP production
def fig_gp():
    fig, ax = fig_new(12.5, 17)
    X0 = 0.0            # colonne tronc
    XV = -4.4           # branche puck vide
    XS = 4.8            # saut /SM
    XN = -3.0           # branche NOK
    XK = 2.4            # branche OK (/MNOK)
    XA = -1.9           # branche ET a (libération puck)
    XB = 1.9            # branche ET b (retour 0°)
    XJ = 7.4            # colonne de reprise (retour vers 1)

    y = 0.0
    # X0
    step(ax, X0, y, 0, initial=True)
    ax.text(X0 - 0.75, y, "attente\nautorisation", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, X0, y - S/2, y - DY/2)
    trans(ax, X0, y - DY/2, "AUTO · CI")
    vline(ax, X0, y - DY/2, y - DY + S/2)
    y1 = y - DY
    # point de reprise au-dessus de X1
    yjoin = y1 + S/2 + 0.45
    # X1
    step(ax, X0, y1, 1, actions=["YV_ST2  (rentrer stoppeur sas)"])
    vline(ax, X0, y1 - S/2, y1 - DY/2)
    trans(ax, X0, y1 - DY/2, "/dpa   (puck sorti du sas)")
    vline(ax, X0, y1 - DY/2, y1 - DY + S/2)
    y2 = y1 - DY
    step(ax, X0, y2, 2)
    ax.text(X0 - 0.75, y2, "attente arrivée\n(ST2 ressorti)", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, X0, y2 - S/2, y2 - DY/2)
    trans(ax, X0, y2 - DY/2, "dp   (puck présent au poste)")
    vline(ax, X0, y2 - DY/2, y2 - DY + S/2)
    y3 = y2 - DY
    step(ax, X0, y3, 3, actions=["T3 : tempo 0,3 s"])
    # ---- divergence OU : vide / plein
    ydiv = y3 - S/2 - 0.4
    vline(ax, X0, y3 - S/2, ydiv)
    hline(ax, XV, X0, ydiv)
    # branche vide
    vline(ax, XV, ydiv, ydiv - 0.35)
    trans(ax, XV, ydiv - 0.35, "t3 · /ds  (puck vide)", side="left")
    y4 = ydiv - 0.35 - 0.9 - S/2
    vline(ax, XV, ydiv - 0.35, y4 + S/2)
    step(ax, XV, y4, 4, actions=["YV_ST1", "(libérer puck)"], act_dx=0.35)
    vline(ax, XV, y4 - S/2, y4 - DY/2)
    trans(ax, XV, y4 - DY/2, "/dp", side="left")
    y5 = y4 - DY
    vline(ax, XV, y4 - DY/2, y5 + S/2)
    step(ax, XV, y5, 5)
    ax.text(XV - 0.75, y5, "attente ST1\nressorti", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, XV, y5 - S/2, y5 - DY/2)
    trans(ax, XV, y5 - DY/2, "st1_s", side="left")
    # saut retour vers 1 (par la gauche)
    XVJ = XV - 3.6
    yb = y5 - DY/2 - 0.4
    vline(ax, XV, y5 - DY/2, yb)
    hline(ax, XVJ, XV, yb)
    vline(ax, XVJ, yb, yjoin)
    hline(ax, XVJ, X0, yjoin)
    arrow_into(ax, X0, yjoin + 0.001, y1 + S/2)
    ax.text(XVJ - 0.15, (yb + yjoin)/2, "reprise → 1", rotation=90, ha="right",
            va="center", fontsize=FS-1, style="italic")
    # branche pleine (tronc)
    vline(ax, X0, ydiv, ydiv - 0.35)
    trans(ax, X0, ydiv - 0.35, "t3 · ds  (puck plein)")
    y10 = ydiv - 0.35 - 0.9 - S/2
    vline(ax, X0, ydiv - 0.35, y10 + S/2)
    step(ax, X0, y10, 10, actions=["FP1", "(prise seringue puck)"])
    # ---- divergence OU : SM / /SM (saut amorçage)
    ydiv2 = y10 - S/2 - 0.4
    vline(ax, X0, y10 - S/2, ydiv2)
    hline(ax, X0, XS, ydiv2)
    # branche SM
    vline(ax, X0, ydiv2, ydiv2 - 0.35)
    trans(ax, X0, ydiv2 - 0.35, "p1_f · SM", side="left")
    y11 = ydiv2 - 0.35 - 0.9 - S/2
    vline(ax, X0, ydiv2 - 0.35, y11 + S/2)
    step(ax, X0, y11, 11)
    ax.text(X0 - 0.75, y11, "attente fin\nde mirage", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, X0, y11 - S/2, y11 - DY/2)
    trans(ax, X0, y11 - DY/2, "fcm   (fin cycle mireuse)", side="left")
    y12 = y11 - DY
    vline(ax, X0, y11 - DY/2, y12 + S/2)
    step(ax, X0, y12, 12, actions=["FP2 · LIB_M", "[MNOK := m_nok]"])
    vline(ax, X0, y12 - S/2, y12 - DY/2)
    trans(ax, X0, y12 - DY/2, "p2_f · m_lib", side="left")
    # branche /SM : saut
    vline(ax, XS, ydiv2, ydiv2 - 0.35)
    trans(ax, XS, ydiv2 - 0.35, "p1_f · /SM\n(amorçage)")
    yconv2 = y12 - DY/2 - 0.4
    vline(ax, XS, ydiv2 - 0.35, yconv2)
    # convergence OU
    vline(ax, X0, y12 - DY/2, yconv2)
    hline(ax, X0, XS, yconv2)
    y13 = yconv2 - 0.35 - S/2
    vline(ax, X0, yconv2, y13 + S/2)
    step(ax, X0, y13, 13)
    ax.text(X0 - 0.75, y13, "prêt à\nbasculer", ha="right", va="center", fontsize=FS-1, style="italic")
    # ---- divergence OU : MNOK / /MNOK
    ydiv3 = y13 - S/2 - 0.4
    vline(ax, X0, y13 - S/2, ydiv3)
    hline(ax, XN, XK, ydiv3)
    # branche NOK
    vline(ax, XN, ydiv3, ydiv3 - 0.35)
    trans(ax, XN, ydiv3 - 0.35, "MNOK", side="left")
    y14 = ydiv3 - 0.35 - 0.9 - S/2
    vline(ax, XN, ydiv3 - 0.35, y14 + S/2)
    step(ax, XN, y14, 14, actions=["R90  (→ 90°)"], act_dx=0.35)
    vline(ax, XN, y14 - S/2, y14 - DY/2)
    trans(ax, XN, y14 - DY/2, "r90", side="left")
    y15 = y14 - DY
    vline(ax, XN, y14 - DY/2, y15 + S/2)
    step(ax, XN, y15, 15, actions=["OP2 (éjection rebut)", "T15 : 0,5 s ; [CR := CR+1]"], act_dx=0.35)
    vline(ax, XN, y15 - S/2, y15 - DY/2)
    trans(ax, XN, y15 - DY/2, "p2_o · t15", side="left")
    y16 = y15 - DY
    vline(ax, XN, y15 - DY/2, y16 + S/2)
    step(ax, XN, y16, 16, actions=["R180  (→ 180°)"], act_dx=0.35)
    vline(ax, XN, y16 - S/2, y16 - DY/2)
    trans(ax, XN, y16 - DY/2, "r180", side="left")
    # branche OK
    vline(ax, XK, ydiv3, ydiv3 - 0.35)
    trans(ax, XK, ydiv3 - 0.35, "/MNOK")
    y17 = ydiv3 - 0.35 - 0.9 - S/2
    vline(ax, XK, ydiv3 - 0.35, y17 + S/2)
    step(ax, XK, y17, 17, actions=["R180  (→ 180°)"])
    vline(ax, XK, y17 - S/2, y17 - DY/2)
    trans(ax, XK, y17 - DY/2, "r180")
    # convergence OU
    yconv3 = y16 - DY/2 - 0.4
    vline(ax, XN, y16 - DY/2, yconv3)
    vline(ax, XK, y17 - DY/2, yconv3)
    hline(ax, XN, XK, yconv3)
    vline(ax, X0, yconv3, yconv3 - 0.35 - S/2 + S/2)
    y18 = yconv3 - 0.35 - S/2
    step(ax, X0, y18, 18, actions=["OP1 · OP2 · SER_M  (déposes)",
                                   "[SM := 1 ; MNOK := 0]"])
    vline(ax, X0, y18 - S/2, y18 - DY/2)
    trans(ax, X0, y18 - DY/2, "p1_o · p2_o · m_ser")
    y19 = y18 - DY
    vline(ax, X0, y18 - DY/2, y19 + S/2)
    step(ax, X0, y19, 19, actions=["DCM  (départ cycle mireuse)", "[CT := CT+1]"])
    vline(ax, X0, y19 - S/2, y19 - DY/2)
    trans(ax, X0, y19 - DY/2, "m_enc   (mirage en cours)")
    # ---- divergence ET
    ydiv4 = y19 - DY/2 - 0.4
    vline(ax, X0, y19 - DY/2, ydiv4)
    hline(ax, XA, XB, ydiv4, double=True)
    y20 = ydiv4 - 0.55 - S/2
    vline(ax, XA, ydiv4 - 0.10, y20 + S/2)
    step(ax, XA, y20, 20, actions=["YV_ST1", "(libérer puck)"], act_dx=0.35, act_w=2.45)
    vline(ax, XA, y20 - S/2, y20 - DY/2)
    trans(ax, XA, y20 - DY/2, "/dp", side="left")
    y21 = y20 - DY
    vline(ax, XA, y20 - DY/2, y21 + S/2)
    step(ax, XA, y21, 21)
    ax.text(XA - 0.75, y21, "puck parti", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, XB, ydiv4 - 0.10, y20 + S/2)
    step(ax, XB, y20, 22, actions=["R0 (retour 0°)"], act_dx=0.35)
    vline(ax, XB, y20 - S/2, y20 - DY/2)
    trans(ax, XB, y20 - DY/2, "r0")
    vline(ax, XB, y20 - DY/2, y21 + S/2)
    step(ax, XB, y21, 23)
    ax.text(XB + 1.7, y21, "tourelle à 0°", ha="left", va="center", fontsize=FS-1, style="italic")
    # convergence ET
    yconv4 = y21 - S/2 - 0.45
    vline(ax, XA, y21 - S/2, yconv4 + 0.10)
    vline(ax, XB, y21 - S/2, yconv4 + 0.10)
    hline(ax, XA, XB, yconv4 + 0.10, double=True)
    vline(ax, X0, yconv4, yconv4 - 0.35)
    trans(ax, X0, yconv4 - 0.35, "st1_s   (stoppeur poste ressorti)")
    # saut retour vers 1 (par la droite)
    yb2 = yconv4 - 0.35 - 0.4
    vline(ax, X0, yconv4 - 0.35, yb2)
    hline(ax, X0, XJ, yb2)
    vline(ax, XJ, yb2, yjoin)
    hline(ax, X0, XJ, yjoin)
    ax.text(XJ + 0.15, (yb2 + yjoin)/2, "reprise → 1  (cycle suivant)", rotation=90,
            ha="left", va="center", fontsize=FS-1, style="italic")
    ax.text(XVJ, yb2 - 1.1,
            "CI (conditions initiales) = r0 · p1_o · p2_o · st1_s · st2_s\n"
            "Notation : /x = complément logique (NON x) ;  [v := e] = affectation à l'activation de l'étape",
            ha="left", va="top", fontsize=FS-0.5)
    save(fig, ax, "fig2_gp.png")

# ================================================================ FIG 3 : GC conduite
def fig_gc():
    fig, ax = fig_new(9.5, 10)
    X = 0.0
    y = 0.0
    step(ax, X, y, 100, initial=True, actions=["V_HS  (voyant hors service)"])
    vline(ax, X, y - S/2, y - DY/2)
    trans(ax, X, y - DY/2, "bp_init · /AU · GS en 200   (sécurité OK)")
    y1 = y - DY
    vline(ax, X, y - DY/2, y1 + S/2)
    step(ax, X, y1, 101, actions=["OP1 · OP2 · R0  (référencement)", "V_INIT clignotant"])
    vline(ax, X, y1 - S/2, y1 - DY/2)
    trans(ax, X, y1 - DY/2, "r0 · p1_o · p2_o · st1_s · st2_s   (CI atteintes)")
    y2 = y1 - DY
    vline(ax, X, y1 - DY/2, y2 + S/2)
    step(ax, X, y2, 102, actions=["V_PRET  (prêt à démarrer)"])
    vline(ax, X, y2 - S/2, y2 - DY/2)
    trans(ax, X, y2 - DY/2, "bp_dcy · m_prete · ps_air · servo_rdy")
    y3 = y2 - DY
    vline(ax, X, y2 - DY/2, y3 + S/2)
    step(ax, X, y3, 103, actions=["AUTO := 1  (autorise GP)", "V_AUTO  (voyant marche auto)"])
    vline(ax, X, y3 - S/2, y3 - DY/2)
    trans(ax, X, y3 - DY/2, "bp_acy   (demande arrêt fin de cycle)")
    y4 = y3 - DY
    vline(ax, X, y3 - DY/2, y4 + S/2)
    step(ax, X, y4, 104, actions=["AUTO := 1  (GP finit son cycle)", "V_AUTO clignotant"])
    vline(ax, X, y4 - S/2, y4 - DY/2)
    trans(ax, X, y4 - DY/2, "X0(GP)   (GP revenu en étape initiale)")
    # reprise vers 102
    XJ = 6.6
    yb = y4 - DY/2 - 0.4
    yjoin = y2 + S/2 + 0.45
    vline(ax, X, y4 - DY/2, yb)
    hline(ax, X, XJ, yb)
    vline(ax, XJ, yb, yjoin)
    hline(ax, X, XJ, yjoin)
    arrow_into(ax, X, yjoin + 0.001, y2 + S/2)
    ax.text(XJ + 0.15, (yb + yjoin)/2, "reprise → 102", rotation=90, ha="left",
            va="center", fontsize=FS-1, style="italic")
    save(fig, ax, "fig3_gc.png")

# ================================================================ FIG 4 : GS sécurité
def fig_gs():
    fig, ax = fig_new(11, 8)
    X = 0.0
    y = 0.0
    step(ax, X, y, 200, initial=True)
    ax.text(X - 0.75, y, "surveillance", ha="right", va="center", fontsize=FS-1, style="italic")
    vline(ax, X, y - S/2, y - DY/2)
    trans(ax, X, y - DY/2, "AU + /ps_air + servo_flt + def_tempo   (défaut grave)")
    y1 = y - DY
    vline(ax, X, y - DY/2, y1 + S/2)
    step(ax, X, y1, 201, actions=["F/GP:(*)  (figeage GP en l'état)", "STO servo · V_DEF  (défaut fixe)",
                                  "(pinces bistables : maintien des seringues)"])
    vline(ax, X, y1 - S/2, y1 - DY/2)
    trans(ax, X, y1 - DY/2, "/AU · ps_air · /servo_flt · bp_rearm   (réarmement)")
    y2 = y1 - DY
    vline(ax, X, y1 - DY/2, y2 + S/2)
    step(ax, X, y2, 202, actions=["F/GP:{0} · F/GC:{100}", "V_DEF clignotant",
                                  "(remise en état manuelle en mode MANU)"])
    vline(ax, X, y2 - S/2, y2 - DY/2)
    trans(ax, X, y2 - DY/2, "bp_valid   (validation opérateur, machine vide)")
    # reprise vers 200
    XJ = 8.6
    yb = y2 - DY/2 - 0.4
    yjoin = y + S/2 + 0.45
    vline(ax, X, y2 - DY/2, yb)
    hline(ax, X, XJ, yb)
    vline(ax, XJ, yb, yjoin)
    hline(ax, X, XJ, yjoin)
    arrow_into(ax, X, yjoin + 0.001, y + S/2)
    ax.text(XJ + 0.15, (yb + yjoin)/2, "reprise → 200", rotation=90, ha="left",
            va="center", fontsize=FS-1, style="italic")
    save(fig, ax, "fig4_gs.png")

fig_synoptique()
fig_gp()
fig_gc()
fig_gs()
