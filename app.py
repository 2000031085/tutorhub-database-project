"""
Tutor Hub  Home
"""
import streamlit as st
import plotly.express as px

from db import run_select
from theme import (
    apply_theme, hero, kpi_grid, section_header,
    plotly_layout, PLOTLY_PALETTE, BRAND, BRAND_DEEP,
)

st.set_page_config(page_title="Tutor Hub", page_icon="🎓", layout="wide")
apply_theme()

# -----------------------------------------------------------------------------
# Hero
# -----------------------------------------------------------------------------
hero(
    eyebrow="EDS 6343 · Team 11 · Spring 2026",
    title="Tutor Hub : Campus Tutoring & Office-Hours Platform",
    subtitle=(
        "A production-grade relational system of record for academic support. "
        "Book sessions, track outcomes, monitor demand, and run advanced "
        "analytics  all from one normalised MySQL schema."
    ),
)

# -----------------------------------------------------------------------------
# KPI row (safe against empty / missing tables)
# -----------------------------------------------------------------------------
try:
    metrics_df = run_select("""
        SELECT
            (SELECT COUNT(*) FROM User)              AS total_users,
            (SELECT COUNT(*) FROM Course)            AS total_courses,
            (SELECT COUNT(*) FROM Availability_Slot) AS total_slots,
            (SELECT COUNT(*) FROM Booking)           AS total_bookings,
            (SELECT COUNT(*) FROM Session_Record)    AS total_sessions,
            (SELECT COALESCE(ROUND(AVG(rating),2),0) FROM Feedback) AS avg_rating
    """)
    m = metrics_df.iloc[0]
    kpi_grid([
        {"label": "Users",      "value": int(m["total_users"]),    "color": "",       "sub": "across all roles"},
        {"label": "Courses",    "value": int(m["total_courses"]),  "color": "cyan",   "sub": "offered campus-wide"},
        {"label": "Slots",      "value": int(m["total_slots"]),    "color": "violet", "sub": "tutor availability windows"},
        {"label": "Bookings",   "value": int(m["total_bookings"]), "color": "amber",  "sub": "lifetime"},
        {"label": "Sessions",   "value": int(m["total_sessions"]), "color": "pink",   "sub": "captured"},
        {"label": "Avg Rating", "value": f'{float(m["avg_rating"]):.2f} ★', "color": "red", "sub": "1–5 scale"},
    ])
except Exception as e:
    st.error(f"Could not load metrics: {e}")

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Two-column: overview + what's new
# -----------------------------------------------------------------------------
left, right = st.columns([1.4, 1])

with left:
    st.markdown(
        """
        <div class="section-card">
            <h3 style="margin-top:0;">Platform Overview</h3>
            <p class="small-caption">
            Tutor Hub unifies tutoring and office-hours scheduling into a single
            normalised MySQL database. Students discover available slots, book
            them transactionally, leave feedback; tutors publish availability;
            administrators monitor demand and at-risk students through
            window-function-powered analytics.
            </p>
            <ul>
                <li>Atomic booking via <code>sp_book_slot</code> (SELECT&nbsp;…&nbsp;FOR UPDATE)</li>
                <li>Automatic audit trail via AFTER-UPDATE triggers</li>
                <li>Denormalised views for fast dashboards</li>
                <li>NTILE-based at-risk scoring and RANK leaderboards</li>
                <li>Streamlit frontend for end-to-end demo</li>
            </ul>
        </div>
        """,
        unsafe_allow_html=True,
    )

with right:
    st.markdown(
        """
        <div class="section-card">
            <h3 style="margin-top:0;">Navigate</h3>
            <p class="small-caption">Use the sidebar to explore each module.</p>
            <ul>
                <li><b>Book Session</b> : submit a booking request</li>
                <li><b>Available Slots</b> : browse open availability</li>
                <li><b>My Bookings</b> : per-student history</li>
                <li><b>Admin Dashboard</b> : operational KPIs</li>
                <li><b>Feedback</b> : rate completed sessions</li>
                <li><b>Advanced Analytics</b> : master-level SQL layer</li>
            </ul>
        </div>
        """,
        unsafe_allow_html=True,
    )

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Chart row: course demand (Plotly) + available slots list
# -----------------------------------------------------------------------------
col_a, col_b = st.columns([1.3, 1])

with col_a:
    section_header("Analytics", "Course Demand",
                   "Total bookings per course across the platform.")
    try:
        course_demand = run_select("""
            SELECT c.course_code,
                   COUNT(b.booking_id) AS total_bookings
            FROM Course c
            LEFT JOIN Booking b ON c.course_id = b.course_id
            GROUP BY c.course_id, c.course_code
            ORDER BY total_bookings DESC
        """)
        if not course_demand.empty and course_demand["total_bookings"].sum() > 0:
            fig = px.bar(
                course_demand,
                x="course_code",
                y="total_bookings",
                color="total_bookings",
                color_continuous_scale=["#FECACA", BRAND, BRAND_DEEP],
                text="total_bookings",
            )
            fig.update_traces(textposition="outside",
                              textfont=dict(size=11, color="#0F172A"),
                              marker_line_width=0,
                              hovertemplate="<b>%{x}</b><br>Bookings: %{y}<extra></extra>")
            fig.update_coloraxes(showscale=False)
            fig.update_layout(**plotly_layout(height=340))
            fig.update_xaxes(title=None, tickfont=dict(size=11))
            fig.update_yaxes(title="Bookings", tickfont=dict(size=11))
            st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
        else:
            st.info("No bookings yet — insert some Booking rows to see demand.")
    except Exception as e:
        st.error(f"Course demand unavailable: {e}")

with col_b:
    section_header("Live", "Upcoming Open Slots",
                   "Currently bookable availability windows.")
    try:
        available_slots = run_select("""
            SELECT c.course_code,
                   a.slot_date,
                   a.start_time,
                   a.end_time,
                   a.mode
            FROM Availability_Slot a
            JOIN Course c ON a.course_id = c.course_id
            WHERE a.slot_status = 'Available'
            ORDER BY a.slot_date, a.start_time
            LIMIT 12
        """)
        if available_slots.empty:
            st.info("No open slots right now.")
        else:
            st.dataframe(
                available_slots,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "course_code": st.column_config.TextColumn("Course"),
                    "slot_date":   st.column_config.TextColumn("Date"),
                    "start_time":  st.column_config.TextColumn("Start"),
                    "end_time":    st.column_config.TextColumn("End"),
                    "mode":        st.column_config.TextColumn("Mode"),
                },
            )
    except Exception as e:
        st.error(f"Slots unavailable: {e}")
