"""
Advanced Analytics : showcase page for the master-level SQL layer.

Requires the views, stored procedures and triggers created by
`TutorHub_MasterLevel.sql`. If those objects are missing, the page degrades
gracefully with a friendly "run the master SQL file first" banner.
"""
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

from db import run_select
from theme import (apply_theme, hero, kpi_grid, section_header,
                   plotly_layout, PLOTLY_PALETTE, BRAND, BRAND_DEEP,
                   ACCENT_AMBER, ACCENT_RED)

st.set_page_config(page_title="Advanced Analytics", page_icon="📊", layout="wide")
apply_theme()

hero(
    eyebrow="Advanced-Level Layer",
    title="📊 Advanced Analytics",
    subtitle="Window functions, ranking, risk scoring, CTEs, and a SQL-based "
             "tutor recommender : all backed by views, stored procedures, "
             "and triggers in TutorHub_MasterLevel.sql.",
)


def safe_select(sql, fallback_label):
    """Run a SELECT but don't crash the page if the object doesn't exist yet."""
    try:
        return run_select(sql), None
    except Exception as e:
        return None, f"{fallback_label}: {e}"


# -----------------------------------------------------------------------------
# Pre-flight: check whether the master-level layer exists
# -----------------------------------------------------------------------------
preflight, preflight_err = safe_select(
    "SELECT 1 FROM vw_tutor_utilisation LIMIT 1",
    "pre-flight",
)
if preflight_err is not None:
    st.error(
        "⚠️ The Advanced-level SQL layer hasn't been loaded into this database yet. "
        "Open MySQL Workbench, connect to **tutorhub**, and execute "
        "`TutorHub_MasterLevel.sql` once. Then refresh this page."
    )
    with st.expander("What does the master-level layer add?"):
        st.markdown("""
        - **Views** — `vw_tutor_utilisation`, `vw_course_demand`, `vw_student_profile`, `vw_booking_details`
        - **Stored procedures** — `sp_book_slot`, `sp_cancel_booking`, `sp_complete_session`
        - **Triggers** — `trg_booking_status_audit`, `trg_slot_status_audit`, `trg_feedback_rating_guard`
        - **Audit tables** — `Booking_Audit`, `Slot_Audit`
        - **Indexes** — 11 covering indexes on hot paths
        """)
    st.stop()

# -----------------------------------------------------------------------------
# KPI strip
# -----------------------------------------------------------------------------
kpi_df, _ = safe_select("""
    SELECT
      (SELECT COUNT(*) FROM vw_tutor_utilisation) AS tutors,
      (SELECT COALESCE(SUM(bookings_taken),0) FROM vw_tutor_utilisation) AS bookings,
      (SELECT COALESCE(SUM(sessions_completed),0) FROM vw_tutor_utilisation) AS completed,
      (SELECT COALESCE(SUM(sessions_noshow),0) FROM vw_tutor_utilisation) AS noshow,
      (SELECT COALESCE(ROUND(AVG(avg_rating),2),0) FROM vw_tutor_utilisation WHERE avg_rating > 0) AS avg_rating
""", "kpi")
if kpi_df is not None and not kpi_df.empty:
    k = kpi_df.iloc[0]
    total = int(k["completed"]) + int(k["noshow"])
    noshow_pct = (int(k["noshow"]) / total * 100) if total else 0
    kpi_grid([
        {"label": "Tutors tracked", "value": int(k["tutors"]),            "color": ""},
        {"label": "Bookings",        "value": int(k["bookings"]),          "color": "cyan"},
        {"label": "Completed",       "value": int(k["completed"]),         "color": "amber"},
        {"label": "No-shows",        "value": int(k["noshow"]),            "color": "red"},
        {"label": "No-show rate",    "value": f"{noshow_pct:.1f}%",        "color": "pink"},
        {"label": "Avg rating",      "value": f'{float(k["avg_rating"]):.2f} ★', "color": "violet"},
    ])

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 1 : Tutor scorecard
# -----------------------------------------------------------------------------
section_header("View · vw_tutor_utilisation",
               "Tutor Scorecard",
               "Denormalised utilisation view built in the Advanced-level layer.")
scorecard = run_select("""
    SELECT tutor_name, role, department,
           slots_offered, bookings_taken,
           sessions_completed, sessions_noshow,
           avg_rating, tutoring_hours
    FROM vw_tutor_utilisation
    ORDER BY avg_rating DESC, bookings_taken DESC
""")
st.dataframe(scorecard, use_container_width=True, hide_index=True,
             column_config={
                 "tutor_name":         st.column_config.TextColumn("Tutor"),
                 "role":               st.column_config.TextColumn("Role"),
                 "department":         st.column_config.TextColumn("Dept"),
                 "slots_offered":      st.column_config.NumberColumn("Slots", format="%d"),
                 "bookings_taken":     st.column_config.NumberColumn("Booked", format="%d"),
                 "sessions_completed": st.column_config.NumberColumn("Completed", format="%d"),
                 "sessions_noshow":    st.column_config.NumberColumn("No-shows", format="%d"),
                 "avg_rating":         st.column_config.ProgressColumn("Rating", min_value=0, max_value=5, format="%.2f"),
                 "tutoring_hours":     st.column_config.NumberColumn("Hours", format="%.1f"),
             })

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 2 : RANK per department
# -----------------------------------------------------------------------------
section_header("Window function · RANK()",
               "Top Tutor per Department",
               "PARTITION BY department ORDER BY avg_rating DESC, bookings_taken DESC.")
ranked = run_select("""
    SELECT department, tutor_name, bookings_taken, avg_rating,
           RANK() OVER (PARTITION BY department
                        ORDER BY avg_rating DESC, bookings_taken DESC) AS dept_rank
    FROM vw_tutor_utilisation
    WHERE bookings_taken > 0
    ORDER BY department, dept_rank
""")
st.dataframe(ranked, use_container_width=True, hide_index=True)

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 3 : Course demand + 7-day moving average
# -----------------------------------------------------------------------------
left, right = st.columns([1, 1.2])

with left:
    section_header("View · vw_course_demand",
                   "Course Demand & No-Show Rate", "")
    demand = run_select("""
        SELECT course_code, total_bookings, no_show_rate_pct, avg_rating
        FROM vw_course_demand
        ORDER BY total_bookings DESC
    """)
    if demand.empty or demand["total_bookings"].sum() == 0:
        st.info("No booking data yet.")
    else:
        fig = px.bar(demand, x="course_code", y="total_bookings",
                     color="no_show_rate_pct",
                     color_continuous_scale=["#FECACA", BRAND, "#7F1D1D"],
                     text="total_bookings",
                     hover_data={"avg_rating": ":.2f", "no_show_rate_pct": ":.1f"})
        fig.update_traces(textposition="outside", textfont=dict(size=11))
        fig.update_layout(**plotly_layout(height=340))
        fig.update_coloraxes(colorbar=dict(title="No-show %"))
        fig.update_xaxes(title=None)
        fig.update_yaxes(title=None)
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
        st.dataframe(demand, use_container_width=True, hide_index=True)

with right:
    section_header("Window function · ROWS BETWEEN 6 PRECEDING",
                   "7-Day Moving Average of Bookings", "")
    moving = run_select("""
        SELECT booking_day, bookings_today,
               ROUND(AVG(bookings_today) OVER (
                   ORDER BY booking_day
                   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
               ), 2) AS moving_avg_7d
        FROM (
            SELECT DATE(booking_timestamp) AS booking_day,
                   COUNT(*)                AS bookings_today
            FROM Booking
            GROUP BY DATE(booking_timestamp)
        ) daily
        ORDER BY booking_day
    """)
    if moving.empty:
        st.info("No bookings yet.")
    else:
        fig = go.Figure()
        fig.add_trace(go.Bar(
            x=moving["booking_day"], y=moving["bookings_today"],
            name="Bookings", marker_color="#FECACA",
        ))
        fig.add_trace(go.Scatter(
            x=moving["booking_day"], y=moving["moving_avg_7d"],
            name="7-day avg", mode="lines+markers",
            line=dict(color=BRAND, width=3),
            marker=dict(size=7),
        ))
        fig.update_layout(**plotly_layout(height=340, showlegend=True))
        fig.update_xaxes(title=None)
        fig.update_yaxes(title="Bookings")
        st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 4 : At-risk students (NTILE)
# -----------------------------------------------------------------------------
section_header("Window function · NTILE(4)",
               "At-Risk Students",
               "Top-quartile by no-show risk from vw_student_profile.")
at_risk = run_select("""
    WITH risk AS (
        SELECT student_id, student_name, bookings_made, no_show_risk,
               NTILE(4) OVER (ORDER BY no_show_risk DESC) AS risk_quartile
        FROM vw_student_profile
        WHERE bookings_made > 0
    )
    SELECT student_name, bookings_made, no_show_risk, risk_quartile
    FROM risk
    ORDER BY no_show_risk DESC
""")
st.dataframe(at_risk, use_container_width=True, hide_index=True,
             column_config={
                 "student_name":   st.column_config.TextColumn("Student"),
                 "bookings_made":  st.column_config.NumberColumn("Bookings"),
                 "no_show_risk":   st.column_config.ProgressColumn("No-show risk",
                                       min_value=0.0, max_value=1.0, format="%.2f"),
                 "risk_quartile":  st.column_config.NumberColumn("Quartile",
                                       help="1 = highest risk, 4 = lowest"),
             })

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 5 : Tutor recommender (ROW_NUMBER)
# -----------------------------------------------------------------------------
section_header("CTE + ROW_NUMBER()",
               "Tutor Recommender : Best Tutor per Course",
               "SQL baseline: highest rating, ties broken by session volume. "
               "Phase-4 ML replaces this with collaborative filtering.")
recommender = run_select("""
    WITH tutor_course_stats AS (
        SELECT
            c.course_id, c.course_code,
            u.user_id                                 AS tutor_id,
            CONCAT(u.first_name,' ',u.last_name)      AS tutor_name,
            COUNT(s.session_id)                       AS sessions_delivered,
            COALESCE(AVG(f.rating),0)                 AS avg_rating
        FROM Course c
        JOIN Tutor_Course tc ON tc.course_id = c.course_id AND tc.is_active = TRUE
        JOIN User u          ON u.user_id = tc.tutor_user_id
        LEFT JOIN Availability_Slot a ON a.provider_user_id = u.user_id AND a.course_id = c.course_id
        LEFT JOIN Booking b        ON b.slot_id = a.slot_id
        LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
        LEFT JOIN Feedback f       ON f.session_id = s.session_id
        GROUP BY c.course_id, c.course_code, u.user_id, tutor_name
    ),
    ranked AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY course_id
                                  ORDER BY avg_rating DESC, sessions_delivered DESC) AS rn
        FROM tutor_course_stats
    )
    SELECT course_code, tutor_name, sessions_delivered,
           ROUND(avg_rating,2) AS avg_rating
    FROM ranked
    WHERE rn = 1
    ORDER BY course_code
""")
st.dataframe(recommender, use_container_width=True, hide_index=True,
             column_config={
                 "course_code":        st.column_config.TextColumn("Course"),
                 "tutor_name":         st.column_config.TextColumn("Recommended tutor"),
                 "sessions_delivered": st.column_config.NumberColumn("Sessions"),
                 "avg_rating":         st.column_config.ProgressColumn(
                                           "Rating", min_value=0, max_value=5, format="%.2f"),
             })

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 6 : Peak-hour heat-map (Plotly)
# -----------------------------------------------------------------------------
section_header("Aggregation · pivot",
               "Peak-Hour Heat-Map (Weekday × Hour)",
               "Where is the campus booking demand concentrated?")
peak = run_select("""
    SELECT DAYNAME(a.slot_date) AS weekday,
           HOUR(a.start_time)   AS slot_hour,
           COUNT(*)             AS bookings_count
    FROM Booking b
    JOIN Availability_Slot a ON b.slot_id = a.slot_id
    GROUP BY weekday, slot_hour
""")
if peak.empty:
    st.info("No booking data yet — insert some bookings first.")
else:
    weekday_order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    pivot = (peak.pivot(index="weekday", columns="slot_hour", values="bookings_count")
                 .reindex(weekday_order).fillna(0))
    fig = px.imshow(
        pivot.values,
        x=[f"{h:02d}:00" for h in pivot.columns],
        y=pivot.index,
        color_continuous_scale=["#FFF5F5", "#FECACA", BRAND, "#7F1D1D"],
        aspect="auto",
        text_auto=True,
    )
    fig.update_layout(**plotly_layout(height=360))
    fig.update_xaxes(title="Hour of day")
    fig.update_yaxes(title=None)
    fig.update_coloraxes(colorbar=dict(title="Bookings"))
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})

st.markdown("<br>", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# Section 7 : Audit trail
# -----------------------------------------------------------------------------
section_header("Triggers", "Audit Trail",
               "Every status change on Booking or Availability_Slot is written "
               "here automatically by AFTER-UPDATE triggers.")
with st.expander("Open audit tables", expanded=False):
    tabs = st.tabs(["Booking audit", "Slot audit"])
    with tabs[0]:
        ba, err = safe_select(
            "SELECT * FROM Booking_Audit ORDER BY audit_id DESC LIMIT 50",
            "Booking_Audit",
        )
        if err:
            st.info("Booking_Audit table isn't present yet.")
        elif ba.empty:
            st.caption("No booking status changes recorded yet.")
        else:
            st.dataframe(ba, use_container_width=True, hide_index=True)
    with tabs[1]:
        sa, err = safe_select(
            "SELECT * FROM Slot_Audit ORDER BY audit_id DESC LIMIT 50",
            "Slot_Audit",
        )
        if err:
            st.info("Slot_Audit table isn't present yet.")
        elif sa.empty:
            st.caption("No slot status changes recorded yet.")
        else:
            st.dataframe(sa, use_container_width=True, hide_index=True)
