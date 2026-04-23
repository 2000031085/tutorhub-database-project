"""
Available Slots — browse all currently bookable availability windows.
"""
import streamlit as st
import pandas as pd

from db import run_select
from theme import apply_theme, hero, kpi_grid, section_header, pill

st.set_page_config(page_title="Available Slots", page_icon="📅", layout="wide")
apply_theme()

hero(
    eyebrow="Discover",
    title="📅 Available Slots",
    subtitle="All currently bookable availability windows, filterable by mode and course.",
)

# Filters
fcol1, fcol2, fcol3 = st.columns([1, 1, 2])
with fcol1:
    mode_filter = st.selectbox("Mode", ["All", "In-Person", "Online"])
with fcol2:
    courses = run_select("SELECT DISTINCT course_code FROM Course ORDER BY course_code")
    options = ["All"] + courses["course_code"].tolist() if not courses.empty else ["All"]
    course_filter = st.selectbox("Course", options)
with fcol3:
    st.markdown("&nbsp;", unsafe_allow_html=True)

query = """
SELECT
    a.slot_id,
    CONCAT(u.first_name, ' ', u.last_name) AS provider_name,
    c.course_code,
    c.course_title,
    a.slot_date,
    a.start_time,
    a.end_time,
    a.mode,
    COALESCE(a.location, '—') AS location,
    COALESCE(a.meeting_link, '—') AS meeting_link
FROM Availability_Slot a
JOIN User u   ON a.provider_user_id = u.user_id
JOIN Course c ON a.course_id = c.course_id
WHERE a.slot_status = 'Available'
"""
params = []
if mode_filter != "All":
    query += " AND a.mode = %s"
    params.append(mode_filter)
if course_filter != "All":
    query += " AND c.course_code = %s"
    params.append(course_filter)

query += " ORDER BY a.slot_date, a.start_time"

df = run_select(query, tuple(params))

# Summary KPIs
if df.empty:
    st.info("No open slots match these filters.")
else:
    try:
        dates = pd.to_datetime(df["slot_date"], errors="coerce")
        days = dates.dt.date.nunique() if not dates.isna().all() else 0
    except Exception:
        days = 0
    kpi_grid([
        {"label": "Open slots", "value": len(df), "color": ""},
        {"label": "In-person",  "value": int((df["mode"] == "In-Person").sum()), "color": "cyan"},
        {"label": "Online",     "value": int((df["mode"] == "Online").sum()),    "color": "violet"},
        {"label": "Unique days","value": days, "color": "amber"},
    ])

    section_header("Listing", f"{len(df)} slot(s) found", "Sorted by date then start time.")
    st.dataframe(
        df.drop(columns=["slot_id"]),
        use_container_width=True,
        hide_index=True,
        column_config={
            "provider_name": st.column_config.TextColumn("Provider"),
            "course_code":   st.column_config.TextColumn("Course"),
            "course_title":  st.column_config.TextColumn("Title"),
            "slot_date":     st.column_config.TextColumn("Date"),
            "start_time":    st.column_config.TextColumn("Start"),
            "end_time":      st.column_config.TextColumn("End"),
            "mode":          st.column_config.TextColumn("Mode"),
            "location":      st.column_config.TextColumn("Location"),
            "meeting_link":  st.column_config.LinkColumn("Meeting link", display_text="Open"),
        },
    )
