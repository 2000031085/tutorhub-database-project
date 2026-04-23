"""
Feedback Center : submit + browse session feedback.
"""
import streamlit as st

from db import run_select, run_action
from theme import apply_theme, hero, kpi_grid, section_header, pill

st.set_page_config(page_title="Feedback Center", page_icon="⭐", layout="wide")
apply_theme()

hero(
    eyebrow="Quality",
    title="⭐ Feedback Center",
    subtitle="Students rate completed tutoring sessions on a 1–5 scale. "
             "Ratings feed the average-rating KPI and every tutor scorecard.",
)

eligible_sessions = run_select("""
SELECT
    s.session_id,
    b.student_user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS student_name,
    c.course_code,
    CONCAT(c.course_code, ' · Session #', s.session_id, ' · ', u.first_name) AS session_label
FROM Session_Record s
JOIN Booking b ON s.booking_id = b.booking_id
JOIN User u ON b.student_user_id = u.user_id
JOIN Course c ON b.course_id = c.course_id
LEFT JOIN Feedback f ON s.session_id = f.session_id
WHERE s.session_status = 'Completed' AND f.feedback_id IS NULL
ORDER BY s.session_id
""")

existing_feedback = run_select("""
SELECT
    f.feedback_id,
    CONCAT(u.first_name, ' ', u.last_name) AS student_name,
    c.course_code,
    f.rating,
    f.comments,
    f.submitted_at
FROM Feedback f
JOIN User u ON f.student_user_id = u.user_id
JOIN Session_Record s ON f.session_id = s.session_id
JOIN Booking b ON s.booking_id = b.booking_id
JOIN Course c ON b.course_id = c.course_id
ORDER BY f.submitted_at DESC
""")

# KPI strip
try:
    total_fb = len(existing_feedback)
    avg_rating = float(existing_feedback["rating"].mean()) if total_fb else 0.0
    pending = len(eligible_sessions)
    five_star = int((existing_feedback["rating"] == 5).sum()) if total_fb else 0
    kpi_grid([
        {"label": "Feedback collected", "value": total_fb,                "color": ""},
        {"label": "Avg rating",         "value": f"{avg_rating:.2f} ★",   "color": "amber"},
        {"label": "Pending feedback",   "value": pending,                  "color": "red"},
        {"label": "5-star entries",     "value": five_star,               "color": "cyan"},
    ])
except Exception:
    pass

tab1, tab2 = st.tabs(["Submit Feedback", "Previous Feedback"])

with tab1:
    if eligible_sessions.empty:
        st.markdown(
            """
            <div class="section-card">
              <h4 style="margin-top:0;">✨ All caught up</h4>
              <p class="small-caption">
              Every completed session already has feedback recorded — no pending
              reviews right now.
              </p>
            </div>
            """,
            unsafe_allow_html=True,
        )
    else:
        st.markdown('<div class="section-card">', unsafe_allow_html=True)
        st.markdown("#### Submit a rating")
        session_label = st.selectbox("Completed session", eligible_sessions["session_label"])
        rating = st.slider("Rating (stars)", 1, 5, 5)
        comments = st.text_area("Comments", placeholder="Optional : what went well, what could improve?")

        preview = "⭐" * rating + "·" * (5 - rating)
        st.markdown(f"<div style='font-size:22px; color:#F59E0B; letter-spacing:6px;'>{preview}</div>",
                    unsafe_allow_html=True)

        selected_row = eligible_sessions[eligible_sessions["session_label"] == session_label].iloc[0]
        session_id = int(selected_row["session_id"])
        student_user_id = int(selected_row["student_user_id"])

        if st.button("Submit Feedback", type="primary"):
            try:
                run_action(
                    "INSERT INTO Feedback (session_id, student_user_id, rating, comments) "
                    "VALUES (%s, %s, %s, %s)",
                    (session_id, student_user_id, rating, comments),
                )
                st.success("✅ Feedback submitted.")
                st.balloons()
                st.rerun()
            except Exception as e:
                st.error(f"Feedback submission failed: {e}")
        st.markdown('</div>', unsafe_allow_html=True)

with tab2:
    section_header("Archive", "Previously submitted feedback", "")
    if existing_feedback.empty:
        st.info("No feedback records yet.")
    else:
        display = existing_feedback.copy()
        display["stars"] = display["rating"].apply(lambda r: "⭐" * int(r))
        display = display[["student_name", "course_code", "stars", "rating",
                           "comments", "submitted_at"]]
        display = display.rename(columns={
            "student_name": "Student",
            "course_code":  "Course",
            "stars":        "",
            "rating":       "Rating",
            "comments":     "Comments",
            "submitted_at": "Submitted",
        })
        st.dataframe(display, use_container_width=True, hide_index=True)
