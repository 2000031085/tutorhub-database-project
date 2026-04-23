"""
Book a Session : booking form with live slot preview.
"""
import streamlit as st

from db import run_select, run_transaction
from theme import apply_theme, hero, section_header, pill

st.set_page_config(page_title="Book Session", page_icon="📝", layout="wide")
apply_theme()

hero(
    eyebrow="Workflow",
    title="📝 Book a Tutoring Session",
    subtitle="Submit a booking request against an available slot. The slot is "
             "marked Booked atomically in the same transaction.",
)

students_df = run_select("""
SELECT user_id, CONCAT(first_name, ' ', last_name) AS student_name
FROM User
WHERE role_id = (SELECT role_id FROM Role WHERE role_name = 'Student')
  AND is_active = TRUE
ORDER BY first_name, last_name
""")

courses_df = run_select("""
SELECT course_id, course_code, course_title,
       CONCAT(course_code, ' : ', course_title) AS course_label
FROM Course
ORDER BY course_code
""")

if students_df.empty or courses_df.empty:
    st.warning("Students or courses are not available in the database.")
    st.stop()

left, right = st.columns([1, 1])

with left:
    st.markdown('<div class="section-card">', unsafe_allow_html=True)
    st.markdown("#### Booking details")
    student_name = st.selectbox("Student", students_df["student_name"])
    course_label = st.selectbox("Course", courses_df["course_label"])

    student_user_id = int(
        students_df.loc[students_df["student_name"] == student_name, "user_id"].iloc[0]
    )
    selected_course_id = int(
        courses_df.loc[courses_df["course_label"] == course_label, "course_id"].iloc[0]
    )

    topics_df = run_select("""
        SELECT topic_id, topic_name
        FROM Topic
        WHERE course_id = %s
        ORDER BY topic_name
    """, (selected_course_id,))

    course_slots_df = run_select("""
        SELECT
            a.slot_id,
            a.slot_date,
            a.start_time,
            a.end_time,
            a.mode,
            CONCAT(a.slot_date, ' · ', a.start_time, '–', a.end_time, ' · ', a.mode) AS slot_label
        FROM Availability_Slot a
        WHERE a.slot_status = 'Available' AND a.course_id = %s
        ORDER BY a.slot_date, a.start_time
    """, (selected_course_id,))

    if course_slots_df.empty:
        st.warning("No available slots for this course right now.")
        st.markdown('</div>', unsafe_allow_html=True)
        st.stop()

    slot_label = st.selectbox("Available Slot", course_slots_df["slot_label"])
    slot_id = int(
        course_slots_df.loc[course_slots_df["slot_label"] == slot_label, "slot_id"].iloc[0]
    )

    topic_options = ["— none —"] + topics_df["topic_name"].tolist()
    topic_name = st.selectbox("Topic (optional)", topic_options)
    booking_status = st.selectbox("Booking Status", ["Pending", "Confirmed"])

    submit = st.button("Submit Booking Request", type="primary", use_container_width=True)
    st.markdown('</div>', unsafe_allow_html=True)

with right:
    st.markdown('<div class="section-card">', unsafe_allow_html=True)
    st.markdown("#### Booking preview")
    selected_slot = course_slots_df[course_slots_df["slot_label"] == slot_label].iloc[0]
    st.markdown(
        f"""
        <table style="width:100%; border-collapse:collapse; font-size:14px;">
          <tr><td style="padding:6px 0; color:#64748B;">Student</td>
              <td style="padding:6px 0; font-weight:600;">{student_name}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Course</td>
              <td style="padding:6px 0; font-weight:600;">{course_label}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Topic</td>
              <td style="padding:6px 0;">{topic_name if topic_name != '— none —' else '<span style="color:#94A3B8;">not set</span>'}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Date</td>
              <td style="padding:6px 0; font-weight:600;">{selected_slot['slot_date']}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Time</td>
              <td style="padding:6px 0; font-weight:600;">{selected_slot['start_time']} – {selected_slot['end_time']}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Mode</td>
              <td style="padding:6px 0;">{pill(selected_slot['mode'], 'info')}</td></tr>
          <tr><td style="padding:6px 0; color:#64748B;">Status</td>
              <td style="padding:6px 0;">{pill(booking_status, 'warn' if booking_status=='Pending' else 'info')}</td></tr>
        </table>
        """,
        unsafe_allow_html=True,
    )
    st.markdown('</div>', unsafe_allow_html=True)

if submit:
    topic_id = None
    if topic_name != "— none —":
        topic_id = int(
            topics_df.loc[topics_df["topic_name"] == topic_name, "topic_id"].iloc[0]
        )
    try:
        run_transaction([
            (
                """
                INSERT INTO Booking (slot_id, student_user_id, course_id, topic_id, booking_status)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (slot_id, student_user_id, selected_course_id, topic_id, booking_status),
            ),
            (
                "UPDATE Availability_Slot SET slot_status = 'Booked' WHERE slot_id = %s",
                (slot_id,),
            ),
        ])
        st.success("✅ Booking request submitted successfully.")
        st.balloons()
        st.rerun()
    except Exception as e:
        st.error(f"Booking failed: {e}")
