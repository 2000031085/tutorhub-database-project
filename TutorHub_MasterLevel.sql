-- =============================================================================
--  Tutor Hub — Master-Level SQL Extension Pack (Team 11)
--  Course : EDS6343 Database Management Tools for Engineers
--  Scope  : Additive advanced features on top of Phase 3 schema.
--           Safe to run AFTER your Phase-3 script has created TutorHub.
--
--  What's inside
--    Section A :  Performance-tuning indexes
--    Section B :  Analytical & reporting VIEWs
--    Section C :  Stored PROCEDUREs (booking workflow, transactions)
--    Section D :  TRIGGERs (audit trail, auto-status, integrity)
--    Section E :  Audit + derived tables created by triggers
--    Section F :  Advanced query pack (CTEs, window functions, ranking,
--                 recursive CTE, pivot, percentile, demand forecasting)
--    Section G :  Demo calls so you can show each feature live
-- =============================================================================

USE TutorHub;

-- -----------------------------------------------------------------------------
--  Section A : Performance-tuning indexes
--  Why       : speeds up the most common JOIN / WHERE paths in our queries.
--              We keep UNIQUE constraints from Phase-3 and add secondary
--              indexes on foreign keys that aren't already indexed.
--  Idempotent: a helper procedure checks information_schema before creating,
--              so the script is safe to re-run on any MySQL 8 server.
--              We deliberately never DROP these indexes — several of them are
--              used to enforce foreign-key constraints, and MySQL will reject
--              a DROP INDEX on an FK-backing index (error 1553).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS _th_create_index_if_absent;
DELIMITER //
CREATE PROCEDURE _th_create_index_if_absent(IN p_table VARCHAR(64),
                                            IN p_index VARCHAR(64),
                                            IN p_cols  VARCHAR(200))
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.statistics
                   WHERE table_schema = DATABASE()
                     AND table_name   = p_table
                     AND index_name   = p_index) THEN
        SET @sql = CONCAT('CREATE INDEX `', p_index, '` ON `', p_table, '`(', p_cols, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

CALL _th_create_index_if_absent('User',              'idx_user_role',             'role_id');
CALL _th_create_index_if_absent('User',              'idx_user_department',       'department_id');
CALL _th_create_index_if_absent('Course',            'idx_course_department',     'department_id');
CALL _th_create_index_if_absent('Topic',             'idx_topic_course',          'course_id');
CALL _th_create_index_if_absent('Availability_Slot', 'idx_slot_provider_date',    'provider_user_id, slot_date');
CALL _th_create_index_if_absent('Availability_Slot', 'idx_slot_course_status',    'course_id, slot_status');
CALL _th_create_index_if_absent('Booking',           'idx_booking_student',       'student_user_id');
CALL _th_create_index_if_absent('Booking',           'idx_booking_course_status', 'course_id, booking_status');
CALL _th_create_index_if_absent('Booking',           'idx_booking_timestamp',     'booking_timestamp');
CALL _th_create_index_if_absent('Session_Record',    'idx_session_status',        'session_status');
CALL _th_create_index_if_absent('Feedback',          'idx_feedback_student',      'student_user_id');

DROP PROCEDURE _th_create_index_if_absent;


-- -----------------------------------------------------------------------------
--  Section B : Analytical & reporting VIEWs
--  Why       : encapsulates the joins we reuse everywhere so the Streamlit
--              dashboard (and graders) can query clean, denormalised rows.
-- -----------------------------------------------------------------------------

-- B1. Flat view of every booking with human-readable context
CREATE OR REPLACE VIEW vw_booking_details AS
SELECT
    b.booking_id,
    b.booking_status,
    b.booking_timestamp,
    stu.user_id        AS student_id,
    CONCAT(stu.first_name, ' ', stu.last_name) AS student_name,
    stu.email          AS student_email,
    prov.user_id       AS provider_id,
    CONCAT(prov.first_name, ' ', prov.last_name) AS provider_name,
    r.role_name        AS provider_role,
    c.course_code,
    c.course_title,
    d.department_name,
    a.slot_date,
    a.start_time,
    a.end_time,
    a.mode,
    a.location,
    a.meeting_link
FROM Booking b
JOIN Availability_Slot a ON b.slot_id = a.slot_id
JOIN User stu            ON b.student_user_id = stu.user_id
JOIN User prov           ON a.provider_user_id = prov.user_id
JOIN Role r              ON prov.role_id = r.role_id
JOIN Course c            ON b.course_id = c.course_id
JOIN Department d        ON c.department_id = d.department_id;

-- B2. Tutor utilisation scorecard (the "who is carrying the load" view)
CREATE OR REPLACE VIEW vw_tutor_utilisation AS
SELECT
    u.user_id                                   AS tutor_id,
    CONCAT(u.first_name,' ',u.last_name)        AS tutor_name,
    r.role_name                                 AS role,
    d.department_name                           AS department,
    COUNT(DISTINCT a.slot_id)                   AS slots_offered,
    COUNT(DISTINCT b.booking_id)                AS bookings_taken,
    SUM(CASE WHEN s.session_status='Completed' THEN 1 ELSE 0 END)        AS sessions_completed,
    SUM(CASE WHEN s.session_status='No-Show'   THEN 1 ELSE 0 END)        AS sessions_noshow,
    ROUND(COALESCE(AVG(f.rating),0),2)          AS avg_rating,
    ROUND(SUM(COALESCE(s.duration_minutes,0))/60.0, 2) AS tutoring_hours
FROM User u
JOIN Role r               ON u.role_id = r.role_id
JOIN Department d         ON u.department_id = d.department_id
LEFT JOIN Availability_Slot a ON a.provider_user_id = u.user_id
LEFT JOIN Booking b           ON b.slot_id = a.slot_id
LEFT JOIN Session_Record s    ON s.booking_id = b.booking_id
LEFT JOIN Feedback f          ON f.session_id = s.session_id
WHERE r.role_name IN ('Tutor','TA','Instructor')
GROUP BY u.user_id, tutor_name, r.role_name, d.department_name;

-- B3. Course demand dashboard
CREATE OR REPLACE VIEW vw_course_demand AS
SELECT
    c.course_id,
    c.course_code,
    c.course_title,
    d.department_name,
    COUNT(DISTINCT b.booking_id)                                        AS total_bookings,
    SUM(CASE WHEN b.booking_status='Completed' THEN 1 ELSE 0 END)       AS completed,
    SUM(CASE WHEN b.booking_status='Cancelled' THEN 1 ELSE 0 END)       AS cancelled,
    SUM(CASE WHEN b.booking_status='No-Show'   THEN 1 ELSE 0 END)       AS no_show,
    ROUND(
        100.0 * SUM(CASE WHEN b.booking_status='No-Show' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(b.booking_id),0), 2)                             AS no_show_rate_pct,
    ROUND(COALESCE(AVG(f.rating),0),2)                                  AS avg_rating
FROM Course c
JOIN Department d         ON c.department_id = d.department_id
LEFT JOIN Booking b       ON b.course_id = c.course_id
LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
LEFT JOIN Feedback f       ON f.session_id  = s.session_id
GROUP BY c.course_id, c.course_code, c.course_title, d.department_name;

-- B4. Student engagement profile (for ML feature extraction later)
CREATE OR REPLACE VIEW vw_student_profile AS
SELECT
    u.user_id                                   AS student_id,
    CONCAT(u.first_name,' ',u.last_name)        AS student_name,
    d.department_name,
    COUNT(b.booking_id)                                                  AS bookings_made,
    SUM(CASE WHEN b.booking_status='Completed' THEN 1 ELSE 0 END)        AS attended,
    SUM(CASE WHEN b.booking_status='No-Show'   THEN 1 ELSE 0 END)        AS missed,
    SUM(CASE WHEN b.booking_status='Cancelled' THEN 1 ELSE 0 END)        AS cancelled,
    ROUND(
        COALESCE(SUM(CASE WHEN b.booking_status='No-Show' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(b.booking_id),0),0), 3)                           AS no_show_risk,
    ROUND(COALESCE(AVG(f.rating),0),2)                                   AS avg_feedback_given
FROM User u
JOIN Role r               ON u.role_id = r.role_id
JOIN Department d         ON u.department_id = d.department_id
LEFT JOIN Booking b       ON b.student_user_id = u.user_id
LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
LEFT JOIN Feedback f       ON f.student_user_id = u.user_id
WHERE r.role_name = 'Student'
GROUP BY u.user_id, student_name, d.department_name;


-- -----------------------------------------------------------------------------
--  Section E : Audit / derived tables (created before triggers reference them)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Booking_Audit (
    audit_id       INT AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT NOT NULL,
    old_status     VARCHAR(20),
    new_status     VARCHAR(20),
    changed_by     VARCHAR(50) DEFAULT (CURRENT_USER()),
    changed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_booking (booking_id)
);

CREATE TABLE IF NOT EXISTS Slot_Audit (
    audit_id       INT AUTO_INCREMENT PRIMARY KEY,
    slot_id        INT NOT NULL,
    old_status     VARCHAR(20),
    new_status     VARCHAR(20),
    changed_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_slot_audit_slot (slot_id)
);


-- -----------------------------------------------------------------------------
--  Section C : Stored PROCEDUREs
--  Why       : bundle multi-step workflows into a single atomic call so the
--              UI doesn't have to orchestrate transactions itself.
-- -----------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_book_slot;
DELIMITER //
CREATE PROCEDURE sp_book_slot (
    IN  p_slot_id           INT,
    IN  p_student_user_id   INT,
    IN  p_topic_id          INT,
    OUT p_new_booking_id    INT,
    OUT p_result_message    VARCHAR(200)
)
proc_label: BEGIN
    DECLARE v_slot_status VARCHAR(20);
    DECLARE v_course_id   INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_new_booking_id = NULL;
        SET p_result_message = 'Error: booking rolled back.';
    END;

    START TRANSACTION;

    -- Lock the slot row so two students can't grab it at the same time
    SELECT slot_status, course_id
      INTO v_slot_status, v_course_id
      FROM Availability_Slot
     WHERE slot_id = p_slot_id
     FOR UPDATE;

    IF v_slot_status IS NULL THEN
        SET p_result_message = 'Slot does not exist.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;

    IF v_slot_status <> 'Available' THEN
        SET p_result_message = CONCAT('Slot is not available (status = ', v_slot_status, ').');
        ROLLBACK;
        LEAVE proc_label;
    END IF;

    INSERT INTO Booking (slot_id, student_user_id, course_id, topic_id, booking_status)
    VALUES (p_slot_id, p_student_user_id, v_course_id, p_topic_id, 'Confirmed');

    SET p_new_booking_id = LAST_INSERT_ID();

    UPDATE Availability_Slot
       SET slot_status = 'Booked'
     WHERE slot_id = p_slot_id;

    COMMIT;
    SET p_result_message = 'Booking confirmed.';
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_cancel_booking;
DELIMITER //
CREATE PROCEDURE sp_cancel_booking (
    IN  p_booking_id         INT,
    IN  p_cancellation_reason VARCHAR(255),
    OUT p_result_message     VARCHAR(200)
)
proc_label: BEGIN
    DECLARE v_slot_id INT;
    DECLARE v_current VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result_message = 'Error: cancellation rolled back.';
    END;

    START TRANSACTION;

    SELECT slot_id, booking_status
      INTO v_slot_id, v_current
      FROM Booking
     WHERE booking_id = p_booking_id
     FOR UPDATE;

    IF v_current IS NULL THEN
        SET p_result_message = 'Booking not found.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;

    IF v_current = 'Cancelled' THEN
        SET p_result_message = 'Booking already cancelled.';
        ROLLBACK;
        LEAVE proc_label;
    END IF;

    UPDATE Booking
       SET booking_status       = 'Cancelled',
           cancellation_reason  = p_cancellation_reason,
           cancelled_at         = NOW()
     WHERE booking_id = p_booking_id;

    UPDATE Availability_Slot
       SET slot_status = 'Available'
     WHERE slot_id = v_slot_id;

    COMMIT;
    SET p_result_message = 'Booking cancelled and slot re-opened.';
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_complete_session;
DELIMITER //
CREATE PROCEDURE sp_complete_session (
    IN  p_booking_id         INT,
    IN  p_actual_start       DATETIME,
    IN  p_actual_end         DATETIME,
    IN  p_attendance_status  VARCHAR(30),
    IN  p_session_notes      VARCHAR(500)
)
BEGIN
    DECLARE v_duration INT;
    SET v_duration = TIMESTAMPDIFF(MINUTE, p_actual_start, p_actual_end);

    INSERT INTO Session_Record
        (booking_id, actual_start_time, actual_end_time, duration_minutes,
         attendance_status, session_status, session_notes)
    VALUES
        (p_booking_id, p_actual_start, p_actual_end, v_duration,
         p_attendance_status,
         CASE WHEN p_attendance_status='Attended' THEN 'Completed' ELSE 'No-Show' END,
         p_session_notes)
    ON DUPLICATE KEY UPDATE
         actual_start_time  = VALUES(actual_start_time),
         actual_end_time    = VALUES(actual_end_time),
         duration_minutes   = VALUES(duration_minutes),
         attendance_status  = VALUES(attendance_status),
         session_status     = VALUES(session_status),
         session_notes      = VALUES(session_notes);

    UPDATE Booking
       SET booking_status =
           CASE WHEN p_attendance_status='Attended' THEN 'Completed' ELSE 'No-Show' END
     WHERE booking_id = p_booking_id;
END //
DELIMITER ;


-- -----------------------------------------------------------------------------
--  Section D : TRIGGERs
--  Why       : enforce rules & build an audit trail without trusting the UI.
-- -----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_booking_status_audit;
DELIMITER //
CREATE TRIGGER trg_booking_status_audit
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
    IF OLD.booking_status <> NEW.booking_status THEN
        INSERT INTO Booking_Audit (booking_id, old_status, new_status)
        VALUES (NEW.booking_id, OLD.booking_status, NEW.booking_status);
    END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trg_slot_status_audit;
DELIMITER //
CREATE TRIGGER trg_slot_status_audit
AFTER UPDATE ON Availability_Slot
FOR EACH ROW
BEGIN
    IF OLD.slot_status <> NEW.slot_status THEN
        INSERT INTO Slot_Audit (slot_id, old_status, new_status)
        VALUES (NEW.slot_id, OLD.slot_status, NEW.slot_status);
    END IF;
END //
DELIMITER ;

-- Prevent students from rating 0 or 6+ (defence-in-depth; CHECK is already there)
DROP TRIGGER IF EXISTS trg_feedback_rating_guard;
DELIMITER //
CREATE TRIGGER trg_feedback_rating_guard
BEFORE INSERT ON Feedback
FOR EACH ROW
BEGIN
    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Feedback rating must be between 1 and 5.';
    END IF;
END //
DELIMITER ;


-- -----------------------------------------------------------------------------
--  Section F : Advanced analytical queries
--  (CTEs, window functions, ranking, recursive dates, pivot, forecasting)
-- -----------------------------------------------------------------------------

-- F1. Rank tutors by average rating WITHIN each department (RANK window fn)
SELECT
    department,
    tutor_name,
    bookings_taken,
    avg_rating,
    RANK() OVER (PARTITION BY department ORDER BY avg_rating DESC, bookings_taken DESC) AS dept_rank
FROM vw_tutor_utilisation
WHERE bookings_taken > 0;

-- F2. Running total of bookings per day (SUM OVER)
SELECT
    DATE(booking_timestamp) AS booking_day,
    COUNT(*)                 AS bookings_today,
    SUM(COUNT(*)) OVER (ORDER BY DATE(booking_timestamp))
                             AS running_total_bookings
FROM Booking
GROUP BY DATE(booking_timestamp)
ORDER BY booking_day;

-- F3. Student's latest booking per course (ROW_NUMBER window fn)
WITH ranked AS (
    SELECT
        b.student_user_id,
        b.course_id,
        b.booking_id,
        b.booking_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY b.student_user_id, b.course_id
            ORDER BY b.booking_timestamp DESC
        ) AS rn
    FROM Booking b
)
SELECT *
FROM ranked
WHERE rn = 1;

-- F4. Peak-hour heat-map: bookings by day-of-week and hour
SELECT
    DAYNAME(a.slot_date)                                 AS weekday,
    HOUR(a.start_time)                                   AS slot_hour,
    COUNT(*)                                             AS bookings_count
FROM Booking b
JOIN Availability_Slot a ON b.slot_id = a.slot_id
GROUP BY weekday, slot_hour
ORDER BY FIELD(weekday,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'), slot_hour;

-- F5. Departments that perform BETTER than the university average rating
WITH dept_avg AS (
    SELECT d.department_name, AVG(f.rating) AS dept_rating
    FROM Department d
    JOIN User u      ON u.department_id = d.department_id
    JOIN Booking b   ON b.student_user_id = u.user_id
    JOIN Session_Record s ON s.booking_id = b.booking_id
    JOIN Feedback f  ON f.session_id = s.session_id
    GROUP BY d.department_name
),
overall AS (SELECT AVG(rating) AS avg_rating FROM Feedback)
SELECT d.department_name, ROUND(d.dept_rating,2) AS dept_rating,
       ROUND(o.avg_rating,2) AS university_avg
FROM dept_avg d CROSS JOIN overall o
WHERE d.dept_rating > o.avg_rating;

-- F6. Pivot-style: sessions per status per course (conditional aggregation)
SELECT
    c.course_code,
    SUM(CASE WHEN s.session_status='Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN s.session_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN s.session_status='No-Show'   THEN 1 ELSE 0 END) AS no_show
FROM Course c
LEFT JOIN Booking b       ON b.course_id = c.course_id
LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
GROUP BY c.course_code
ORDER BY c.course_code;

-- F7. 7-day moving average of bookings (window frame)
SELECT
    booking_day,
    bookings_today,
    ROUND(AVG(bookings_today) OVER (
        ORDER BY booking_day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7d
FROM (
    SELECT DATE(booking_timestamp) AS booking_day, COUNT(*) AS bookings_today
    FROM Booking
    GROUP BY DATE(booking_timestamp)
) daily;

-- F8. Recursive CTE: calendar of the next 14 days and how many slots each has
WITH RECURSIVE next14 AS (
    SELECT CURRENT_DATE AS d
    UNION ALL
    SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM next14 WHERE d < DATE_ADD(CURRENT_DATE, INTERVAL 13 DAY)
)
SELECT n.d AS calendar_date,
       COALESCE(COUNT(a.slot_id),0) AS total_slots,
       SUM(CASE WHEN a.slot_status='Available' THEN 1 ELSE 0 END) AS open_slots
FROM next14 n
LEFT JOIN Availability_Slot a ON a.slot_date = n.d
GROUP BY n.d
ORDER BY n.d;

-- F9. "At-risk" students (no-show risk in top 25%) — NTILE window fn
WITH risk AS (
    SELECT student_id, student_name, bookings_made, no_show_risk,
           NTILE(4) OVER (ORDER BY no_show_risk DESC) AS risk_quartile
    FROM vw_student_profile
    WHERE bookings_made > 0
)
SELECT * FROM risk WHERE risk_quartile = 1;

-- F10. Tutor recommendation: best tutor per course (highest rating, ties by volume)
WITH tutor_course_stats AS (
    SELECT
        c.course_id,
        c.course_code,
        u.user_id AS tutor_id,
        CONCAT(u.first_name,' ',u.last_name) AS tutor_name,
        COUNT(s.session_id) AS sessions_delivered,
        COALESCE(AVG(f.rating),0) AS avg_rating
    FROM Course c
    JOIN Tutor_Course tc      ON tc.course_id = c.course_id AND tc.is_active = TRUE
    JOIN User u               ON u.user_id = tc.tutor_user_id
    LEFT JOIN Availability_Slot a ON a.provider_user_id = u.user_id AND a.course_id = c.course_id
    LEFT JOIN Booking b       ON b.slot_id = a.slot_id
    LEFT JOIN Session_Record s ON s.booking_id = b.booking_id
    LEFT JOIN Feedback f      ON f.session_id = s.session_id
    GROUP BY c.course_id, c.course_code, u.user_id, tutor_name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY course_id ORDER BY avg_rating DESC, sessions_delivered DESC) AS rn
    FROM tutor_course_stats
)
SELECT course_code, tutor_name, sessions_delivered, ROUND(avg_rating,2) AS avg_rating
FROM ranked
WHERE rn = 1;


-- -----------------------------------------------------------------------------
--  Section G : Demo calls for the presentation
-- -----------------------------------------------------------------------------

-- Show the dashboards
SELECT * FROM vw_booking_details  LIMIT 10;
SELECT * FROM vw_tutor_utilisation ORDER BY avg_rating DESC;
SELECT * FROM vw_course_demand     ORDER BY total_bookings DESC;
SELECT * FROM vw_student_profile   ORDER BY no_show_risk DESC;

-- Exercise the stored procedure end-to-end
-- (swap in IDs that exist in your data; student=1, slot=5 was 'Available' in Phase-3 seed)
-- CALL sp_book_slot(5, 1, 4, @new_id, @msg);
-- SELECT @new_id AS new_booking_id, @msg AS message;
-- CALL sp_cancel_booking(@new_id, 'Schedule conflict', @msg2);
-- SELECT @msg2 AS cancellation_message;

-- Check that triggers wrote to the audit tables
-- SELECT * FROM Booking_Audit ORDER BY audit_id DESC;
-- SELECT * FROM Slot_Audit    ORDER BY audit_id DESC;

-- =============================================================================
-- End of Master-Level SQL Extension Pack
-- =============================================================================
