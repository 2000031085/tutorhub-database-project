"""
My Bookings : per-student booking history with status breakdown.
"""
import streamlit as st
import plotly.express as px

from db import run_select
from theme import (apply_theme, hero, kpi_grid, section_header,
                   plotly_layout, PLOTLY_PALETTE)

st.set_page_config(page_title="My Bookings", page_icon="📘", layout="wide")
apply_theme()

hero(
    eyebrow="History",
    title="📘 My Bookings",
    subtitle="Personal booking history : every request, its status, and the session outcome.",
)

students_df = run_select("""
SELECT user_id, CONCAT(first_name, ' ', last_name) AS student_name
FROM User
WHERE role_id = (SELECT role_id FROM Role WHERE role_name = 'Student')
ORDER BY first_name, last_name
""")

if students_df.empty:
    st.warning("No students found.")
    st.stop()

student_name = st.selectbox("Select Student", students_df["student_name"])
student_user_id = int(students_df[students_df["student_name"] == student_name]["user_id"].iloc[0])

df = run_select("""
SELECT
    b.booking_id,
    c.course_code,
    c.course_title,
    t.topic_name,
    b.booking_status,
    b.booking_timestamp,
    a.slot_date,
    a.start_time,
    a.end_time,
    a.mode,
    s.session_status
FROM Booking b
JOIN Course c ON b.course_id = c.course_id
JOIN Availability_Slot a ON b.slot_id = a.slot_id
LEFT JOIN Topic t ON b.topic_id = t.topic_id
LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
WHERE b.student_user_id = %s
ORDER BY b.booking_timestamp DESC
""", (student_user_id,))

if df.empty:
    st.info(f"{student_name} has no bookings yet.")
    st.stop()

# KPI strip
kpi_grid([
    {"label": "Total bookings", "value": len(df),                                          "color": ""},
    {"label": "Confirmed",      "value": int((df["booking_status"] == "Confirmed").sum()), "color": "cyan"},
    {"label": "Completed",      "value": int((df["session_status"] == "Completed").sum()), "color": "amber"},
    {"label": "Cancelled",      "value": int((df["booking_status"] == "Cancelled").sum()), "color": "red"},
])

left, right = st.columns([1.5, 1])

with left:
    section_header("Timeline", "Booking history",
                   "Most recent first. Hover for course + topic.")
    display = df.rename(columns={
        "course_code":      "Course",
        "course_title":     "Title",
        "topic_name":       "Topic",
        "booking_status":   "Booking",
        "booking_timestamp":"Requested",
        "slot_date":        "Date",
        "start_time":       "Start",
        "end_time":         "End",
        "mode":             "Mode",
        "session_status":   "Session",
    }).drop(columns=["booking_id"])
    st.dataframe(display, use_container_width=True, hide_index=True)

with right:
    section_header("Breakdown", "By booking status", "")
    status_counts = df["booking_status"].value_counts().reset_index()
    status_counts.columns = ["booking_status", "count"]
    fig = px.pie(
        status_counts, values="count", names="booking_status",
        hole=0.55, color_discrete_sequence=PLOTLY_PALETTE,
    )
    fig.update_traces(textinfo="value+label",
                      textfont=dict(size=12, color="#0F172A"))
    fig.update_layout(**plotly_layout(height=320, showlegend=True))
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
