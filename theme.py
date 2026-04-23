"""
Tutor Hub : shared design system.

Every page should call `apply_theme()` once, right after `st.set_page_config`.
The module also provides Plotly template helpers and small UI widgets
(hero bar, KPI tile, section card) so pages stay consistent.
"""

import streamlit as st


# -----------------------------------------------------------------------------
# Palette — "Red"
#   Primary      : #C8102E  
#   Deep         : #8A0A1E
#   Secondary    : #E4002B  (brighter red for gradients)
#   Accents      : warm amber + charcoal navy
# -----------------------------------------------------------------------------
BRAND        = "#C8102E"
BRAND_DEEP   = "#8A0A1E"
BRAND_2      = "#E4002B"
ACCENT_AMBER = "#F59E0B"
ACCENT_RED   = "#B91C1C"
ACCENT_PINK  = "#DB2777"
ACCENT_VIOLET= "#7C3AED"
DARK         = "#0F172A"
SLATE        = "#475569"
MUTED        = "#94A3B8"
BORDER       = "#E2E8F0"
SURFACE      = "#FFFFFF"
CANVAS       = "#F8FAFC"

PLOTLY_PALETTE = [BRAND, BRAND_DEEP, ACCENT_AMBER, "#1F2937",
                  ACCENT_PINK, ACCENT_VIOLET, "#DC2626", "#6B7280"]


# -----------------------------------------------------------------------------
# CSS — injected once per page
# -----------------------------------------------------------------------------
_CSS = f"""
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap');

html, body, [class*="css"]  {{
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
    color: {DARK};
}}

/* Shrink the default top padding so the hero sits close to the top */
.block-container {{
    padding-top: 1.2rem !important;
    padding-bottom: 3rem !important;
    max-width: 1300px;
}}

/* Hide the default "Made with Streamlit" footer and menu */
#MainMenu {{ visibility: hidden; }}
footer    {{ visibility: hidden; }}
header    {{ visibility: hidden; }}

/* ---------- Sidebar ---------- */
section[data-testid="stSidebar"] {{
    background: linear-gradient(180deg, {DARK} 0%, #1E293B 100%);
    border-right: 1px solid {BORDER};
}}
section[data-testid="stSidebar"] * {{
    color: #E2E8F0 !important;
}}
section[data-testid="stSidebar"] a {{
    color: #CBD5E1 !important;
    border-radius: 8px;
    padding: 6px 10px;
    margin: 2px 0;
}}
section[data-testid="stSidebar"] a:hover {{
    background: rgba(200,16,46,0.25) !important;
    color: #FFFFFF !important;
}}
section[data-testid="stSidebar"] [aria-current="page"] {{
    background: {BRAND} !important;
    color: #FFFFFF !important;
    font-weight: 600;
}}

/* Sidebar brand block */
.sidebar-brand {{
    padding: 18px 14px 22px 14px;
    margin: -14px -14px 8px -14px;
    border-bottom: 1px solid rgba(255,255,255,0.1);
    text-align: left;
}}
.sidebar-brand .logo-row {{
    display: flex; align-items: center; gap: 10px;
}}
.sidebar-brand .logo-dot {{
    width: 34px; height: 34px; border-radius: 10px;
    background: linear-gradient(135deg, {BRAND} 0%, {BRAND_DEEP} 100%);
    display: flex; align-items: center; justify-content: center;
    font-size: 18px; font-weight: 800; color: white;
    box-shadow: 0 4px 12px rgba(200,16,46,0.5);
}}
.sidebar-brand .brand-name {{
    font-size: 18px; font-weight: 700; color: white !important;
    letter-spacing: -0.02em;
}}
.sidebar-brand .brand-sub {{
    font-size: 11px; color: #94A3B8 !important;
    letter-spacing: 0.12em; text-transform: uppercase;
    margin-top: 2px;
}}

/* ---------- Hero ---------- */
.hero-box {{
    background: linear-gradient(120deg, {BRAND_DEEP} 0%, {BRAND} 55%, #F05161 100%);
    color: white;
    padding: 28px 32px;
    border-radius: 18px;
    margin-bottom: 20px;
    box-shadow: 0 10px 30px -10px rgba(200,16,46,0.35);
    position: relative;
    overflow: hidden;
}}
.hero-box::after {{
    content: "";
    position: absolute;
    right: -60px; top: -60px;
    width: 220px; height: 220px;
    border-radius: 50%;
    background: rgba(255,255,255,0.08);
}}
.hero-box::before {{
    content: "";
    position: absolute;
    right: 40px; bottom: -80px;
    width: 160px; height: 160px;
    border-radius: 50%;
    background: rgba(255,255,255,0.06);
}}
.hero-box .page-title {{
    font-size: 30px; font-weight: 800; letter-spacing: -0.02em;
    color: white !important;
    position: relative; z-index: 2;
}}
.hero-box .page-subtitle {{
    font-size: 15px; opacity: 0.92; margin-top: 6px;
    color: white !important; max-width: 780px;
    position: relative; z-index: 2;
}}
.hero-box .page-eyebrow {{
    font-size: 11px; letter-spacing: 0.2em; text-transform: uppercase;
    opacity: 0.8; margin-bottom: 6px;
    color: white !important;
    position: relative; z-index: 2;
}}

/* ---------- Cards ---------- */
.section-card {{
    background: {SURFACE};
    border: 1px solid {BORDER};
    border-radius: 14px;
    padding: 20px 22px;
    box-shadow: 0 1px 3px rgba(15,23,42,0.04);
    margin-bottom: 16px;
}}
.section-card h3, .section-card h4 {{
    color: {DARK}; letter-spacing: -0.01em;
}}
.section-card ul {{ padding-left: 20px; }}
.section-card li {{ margin-bottom: 4px; color: {SLATE}; }}
.small-caption {{ color: {SLATE}; font-size: 13px; line-height: 1.55; }}

/* ---------- KPI tiles ---------- */
.kpi-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 14px;
    margin-bottom: 18px;
}}
.kpi-card {{
    background: {SURFACE};
    border: 1px solid {BORDER};
    border-left: 4px solid {BRAND};
    border-radius: 12px;
    padding: 16px 18px;
    box-shadow: 0 1px 2px rgba(15,23,42,0.04);
    transition: transform 0.15s ease, box-shadow 0.15s ease;
}}
.kpi-card:hover {{
    transform: translateY(-2px);
    box-shadow: 0 8px 20px -8px rgba(200,16,46,0.25);
}}
.kpi-card.amber  {{ border-left-color: {ACCENT_AMBER}; }}
.kpi-card.violet {{ border-left-color: {ACCENT_VIOLET}; }}
.kpi-card.pink   {{ border-left-color: {ACCENT_PINK}; }}
.kpi-card.red    {{ border-left-color: {ACCENT_RED}; }}
.kpi-card.cyan   {{ border-left-color: {BRAND_2}; }}

.kpi-label {{
    font-size: 11px; letter-spacing: 0.12em;
    text-transform: uppercase; color: {MUTED};
    font-weight: 600; margin-bottom: 6px;
}}
.kpi-value {{
    font-size: 28px; font-weight: 800; color: {DARK};
    letter-spacing: -0.02em; line-height: 1.1;
}}
.kpi-sub {{
    font-size: 12px; color: {SLATE}; margin-top: 4px;
}}

/* Legacy metric-card alias */
.metric-card {{
    background: {SURFACE};
    border: 1px solid {BORDER};
    border-left: 4px solid {BRAND};
    border-radius: 12px;
    padding: 16px 18px;
    box-shadow: 0 1px 2px rgba(15,23,42,0.04);
}}
.metric-label {{
    font-size: 11px; letter-spacing: 0.12em;
    text-transform: uppercase; color: {MUTED};
    font-weight: 600; margin-bottom: 6px;
}}
.metric-value {{
    font-size: 28px; font-weight: 800; color: {DARK};
    letter-spacing: -0.02em; line-height: 1.1;
}}

/* ---------- Pills / badges ---------- */
.pill {{
    display: inline-block; padding: 3px 10px; border-radius: 999px;
    font-size: 11px; font-weight: 600; letter-spacing: 0.04em;
}}
.pill-success {{ background: #D1FAE5; color: #065F46; }}
.pill-warn    {{ background: #FEF3C7; color: #92400E; }}
.pill-danger  {{ background: #FEE2E2; color: #991B1B; }}
.pill-info    {{ background: #CFFAFE; color: #155E75; }}
.pill-neutral {{ background: #E2E8F0; color: #334155; }}

/* ---------- Forms ---------- */
.stButton > button[kind="primary"] {{
    background: linear-gradient(135deg, {BRAND} 0%, {BRAND_DEEP} 100%) !important;
    color: white !important;
    border: none !important;
    border-radius: 10px !important;
    padding: 10px 22px !important;
    font-weight: 600 !important;
    letter-spacing: 0.01em;
    box-shadow: 0 4px 12px -2px rgba(200,16,46,0.4) !important;
    transition: transform 0.15s ease, box-shadow 0.15s ease;
}}
.stButton > button[kind="primary"]:hover {{
    transform: translateY(-1px);
    box-shadow: 0 8px 20px -4px rgba(200,16,46,0.55) !important;
}}
.stButton > button {{
    border-radius: 10px !important;
    font-weight: 500;
}}
.stSelectbox, .stTextInput, .stTextArea, .stDateInput, .stNumberInput {{
    font-family: 'Inter', sans-serif;
}}
div[data-baseweb="select"] > div {{
    border-radius: 10px !important;
    border-color: {BORDER} !important;
}}
div[data-baseweb="input"] input, textarea {{
    border-radius: 10px !important;
}}

/* ---------- Tabs ---------- */
button[data-baseweb="tab"] {{
    font-weight: 600 !important;
    color: {SLATE} !important;
}}
button[data-baseweb="tab"][aria-selected="true"] {{
    color: {BRAND} !important;
}}
div[data-baseweb="tab-highlight"] {{
    background-color: {BRAND} !important;
    height: 3px !important;
}}

/* ---------- Dataframes ---------- */
div[data-testid="stDataFrame"] {{
    border: 1px solid {BORDER};
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 1px 2px rgba(15,23,42,0.04);
}}

/* ---------- Expanders ---------- */
div[data-testid="stExpander"] {{
    border: 1px solid {BORDER};
    border-radius: 12px;
    overflow: hidden;
    background: {SURFACE};
}}
div[data-testid="stExpander"] summary {{
    font-weight: 600; color: {DARK};
}}

/* ---------- Alerts ---------- */
div[data-baseweb="notification"] {{
    border-radius: 12px !important;
}}

/* ---------- Section label ---------- */
.section-label {{
    font-size: 11px; letter-spacing: 0.2em; text-transform: uppercase;
    color: {BRAND}; font-weight: 700; margin-bottom: 4px;
}}
.section-title {{
    font-size: 22px; font-weight: 700; color: {DARK};
    letter-spacing: -0.01em; margin-bottom: 4px;
}}
.section-desc {{
    font-size: 13px; color: {SLATE}; margin-bottom: 14px;
}}

/* Divider */
hr {{ border-color: {BORDER} !important; margin: 1.5rem 0 !important; }}
</style>
"""


def apply_theme():
    """Inject CSS and render the branded sidebar header. Call once per page."""
    st.markdown(_CSS, unsafe_allow_html=True)
    with st.sidebar:
        st.markdown(
            """
            <div class="sidebar-brand">
                <div class="logo-row">
                    <div class="logo-dot">TH</div>
                    <div>
                        <div class="brand-name">Tutor Hub</div>
                        <div class="brand-sub">Team 11 · EDS 6343</div>
                    </div>
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )


# -----------------------------------------------------------------------------
# Reusable widgets
# -----------------------------------------------------------------------------
def hero(title: str, subtitle: str = "", eyebrow: str = ""):
    eyebrow_html = f'<div class="page-eyebrow">{eyebrow}</div>' if eyebrow else ""
    st.markdown(
        f"""
        <div class="hero-box">
            {eyebrow_html}
            <div class="page-title">{title}</div>
            <div class="page-subtitle">{subtitle}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def section_header(eyebrow: str, title: str, desc: str = ""):
    st.markdown(
        f"""
        <div>
            <div class="section-label">{eyebrow}</div>
            <div class="section-title">{title}</div>
            <div class="section-desc">{desc}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def kpi_grid(items):
    """items: list of dicts with keys label, value, sub (optional), color (optional)."""
    cards = []
    for it in items:
        color_cls = it.get("color", "")
        sub = f'<div class="kpi-sub">{it.get("sub","")}</div>' if it.get("sub") else ""
        cards.append(
            f'<div class="kpi-card {color_cls}">'
            f'  <div class="kpi-label">{it["label"]}</div>'
            f'  <div class="kpi-value">{it["value"]}</div>'
            f'  {sub}'
            f'</div>'
        )
    st.markdown(f'<div class="kpi-grid">{"".join(cards)}</div>',
                unsafe_allow_html=True)


def pill(text: str, kind: str = "neutral") -> str:
    """Return HTML for a colored pill. kind: success|warn|danger|info|neutral."""
    return f'<span class="pill pill-{kind}">{text}</span>'


# -----------------------------------------------------------------------------
# Plotly helpers
# -----------------------------------------------------------------------------
def plotly_layout(title: str = "", height: int = 320, showlegend: bool = False):
    """Returns a dict of layout kwargs to pass to fig.update_layout(**...)."""
    return dict(
        title=dict(text=title, x=0.0, xanchor="left",
                   font=dict(size=15, color=DARK, family="Inter")),
        height=height,
        margin=dict(l=40, r=20, t=40 if title else 10, b=40),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        font=dict(family="Inter", color=DARK, size=12),
        xaxis=dict(gridcolor=BORDER, zerolinecolor=BORDER, linecolor=BORDER),
        yaxis=dict(gridcolor=BORDER, zerolinecolor=BORDER, linecolor=BORDER),
        showlegend=showlegend,
        legend=dict(orientation="h", yanchor="bottom", y=1.02,
                    xanchor="right", x=1),
    )


def status_pill_html(status: str) -> str:
    s = (status or "").lower()
    mapping = {
        "available":  ("success",  "Available"),
        "booked":     ("info",     "Booked"),
        "cancelled":  ("danger",   "Cancelled"),
        "pending":    ("warn",     "Pending"),
        "confirmed":  ("info",     "Confirmed"),
        "completed":  ("success",  "Completed"),
        "no-show":    ("danger",   "No-Show"),
        "noshow":     ("danger",   "No-Show"),
    }
    kind, label = mapping.get(s, ("neutral", status or "—"))
    return pill(label, kind)
