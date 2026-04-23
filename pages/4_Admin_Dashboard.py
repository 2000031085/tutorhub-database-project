"""
Admin Dashboard — operational KPIs + charts.
"""
import streamlit as st
import plotly.express as px

from db import run_select
from theme import (apply_theme, hero, kpi_grid, section_header,
                   plotly_layout, PLOTLY_PALETTE, BRAND)

st.set_page_config(page_title="Admin Dashboard", page_icon="📊", layout="wide")
apply_theme()

hero(
    eyebrow="Operations",
    title="📊 Admin Dashboard",
    subtitle="Live KPIs, demand distribution, session outcomes, and repeat-student signals.",
)

# ---- KPI strip ----
try:
    k = run_select("""
        SELECT
            (SELECT COUNT(*) FROM Booking)                                      AS bookings,
            (SELECT COUNT(*) FROM Session_Record WHERE session_status='Completed') AS completed,
            (SELECT COUNT(*) FROM Session_Record WHERE session_status='No-Show') AS noshow,
            (SELECT COALESCE(ROUND(AVG(rating),2),0) FROM Feedback)              AS avg_rating,
            (SELECT COUNT(*) FROM Availability_Slot WHERE slot_status='Available') AS open_slots,
            (SELECT COUNT(*) FROM User WHERE role_id=(SELECT role_id FROM Role WHERE role_name='Tutor')) AS tutors
    """).iloc[0]
    kpi_grid([
        {"label": "Bookings",   "value": int(k["bookings"]),   "color": ""},
        {"label": "Completed",  "value": int(k["completed"]),  "color": "cyan"},
        {"label": "No-shows",   "value": int(k["noshow"]),     "color": "red"},
        {"label": "Avg rating", "value": f'{float(k["avg_rating"]):.2f} ★', "color": "amber"},
        {"label": "Open slots", "value": int(k["open_slots"]), "color": "violet"},
        {"label": "Tutors",     "value": int(k["tutors"]),     "color": "pink"},
    ])
except Exception as e:
    st.error(f"KPI fetch failed: {e}")

st.markdown("<br>", unsafe_allow_html=True)

# ---- Charts row 1: course demand + session status ----
c1, c2 = st.columns([1.3, 1])

with c1:
    section_header("Demand", "Bookings by Course", "")
    df = run_select("""
        SELECT c.course_code, COUNT(b.booking_id) AS total_bookings
        FROM Course c
        LEFT JOIN Booking b ON c.course_id = b.course_id
        GROUP BY c.course_id, c.course_code
        ORDER BY total_bookings DESC
    """)
    if df.empty or df["total_bookings"].sum() == 0:
        st.info("No bookings yet.")
    else:
        fig = px.bar(df, x="course_code", y="total_bookings",
                     color="total_bookings",
                     color_continuous_scale=["#FECACA", BRAND, "#7F1D1D"],
                     text="total_bookings")
        fig.update_traces(textposition="outside", textfont=dict(size=11))
        fig.update_coloraxes(showscale=False)
        fig.update_layout(**plotly_layout(height=320))
        fig.update_xaxes(title=None)
        fig.update_yaxes(title=None)
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

with c2:
    section_header("Outcomes", "Sessions by Status", "")
    df = run_select("""
        SELECT session_status, COUNT(session_id) AS total_sessions
        FROM Session_Record
        GROUP BY session_status
    """)
    if df.empty:
        st.info("No session records yet.")
    else:
        color_map = {"Completed": "#10B981", "No-Show": "#EF4444",
                     "In-Progress": "#F59E0B", "Cancelled": "#94A3B8"}
        fig = px.pie(df, values="total_sessions", names="session_status",
                     hole=0.55,
                     color="session_status",
                     color_discrete_map=color_map)
        fig.update_traces(textinfo="value+percent",
                          textfont=dict(size=12, color="white"))
        fig.update_layout(**plotly_layout(height=320, showlegend=True))
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

# ---- Charts row 2: rating distribution + repeat students ----
c3, c4 = st.columns([1, 1.3])

with c3:
    section_header("Quality", "Rating Distribution", "")
    df = run_select("""
        SELECT rating, COUNT(*) AS n
        FROM Feedback
        GROUP BY rating
        ORDER BY rating
    """)
    if df.empty:
        st.info("No feedback yet.")
    else:
        fig = px.bar(df, x="rating", y="n", text="n",
                     color="rating", color_continuous_scale=["#FEE2E2", "#10B981"])
        fig.update_traces(textposition="outside", textfont=dict(size=11))
        fig.update_coloraxes(showscale=False)
        fig.update_layout(**plotly_layout(height=300))
        fig.update_xaxes(title="Stars", dtick=1)
        fig.update_yaxes(title="Feedback count")
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

with c4:
    section_header("Engagement", "Students with more than one booking", "")
    repeat_students = run_select("""
        SELECT
            CONCAT(u.first_name, ' ', u.last_name) AS student,
            COUNT(b.booking_id) AS bookings
        FROM User u
        JOIN Booking b ON u.user_id = b.student_user_id
        GROUP BY u.user_id, u.first_name, u.last_name
        HAVING COUNT(b.booking_id) > 1
        ORDER BY bookings DESC
        LIMIT 15
    """)
    if repeat_students.empty:
        st.info("No repeat students yet.")
    else:
        st.dataframe(repeat_students, use_container_width=True, hide_index=True)
