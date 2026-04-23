-- =============================================================================
-- TutorHub_DemoSeed.sql  —  Team 11, EDS 6343
--
-- Additive demo data for the Final-Project presentation.
-- Run AFTER:
--   1. TEAM_11_SQL_Implementation_Phase_3.sql  (creates schema + base seed)
--   2. TutorHub_MasterLevel.sql                 (advanced SQL layer)
--
-- After Phase-3 the database has user_ids 1..10:
--   1..4  : Students (Aarav, Maya, Rohan, Anika)
--   5..6  : Tutors   (David, Sophia)
--   7, 9  : TAs      (Ethan, Priya)
--   8, 10 : Instructors (Drake, Laura)
-- This file appends:
--   •  18 students  → user_ids 11..28
--   •   6 tutors    → user_ids 29..34
--   •   4 TAs       → user_ids 35..38
--   •   3 instructors → user_ids 39..41
--   •   3 courses   → course_ids  6..8
--   •  10 topics    → topic_ids  11..20
--   •  ~60 availability slots  → slot_ids 9..67
--   •  ~26 bookings, 22 session records, 10 feedback rows
--
-- Idempotency: re-running will hit UNIQUE-constraint errors. To re-seed,
-- drop and recreate TutorHub, or TRUNCATE the dependent tables first.
-- =============================================================================

USE TutorHub;
SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 1. Extra users
-- -----------------------------------------------------------------------------
-- Students (role_id = 1) → user_ids 11..28
INSERT INTO User (first_name, last_name, email, phone, role_id, department_id, university_id, is_active) VALUES
('Jordan',  'Martinez', 'jordan.martinez@uh.edu',   '7135551005', 1, 1, 'UH1005', TRUE),
('Sofia',   'Kim',      'sofia.kim@uh.edu',         '7135551006', 1, 2, 'UH1006', TRUE),
('Liam',    'Johnson',  'liam.johnson@uh.edu',      '7135551007', 1, 3, 'UH1007', TRUE),
('Ava',     'Williams', 'ava.williams@uh.edu',      '7135551008', 1, 4, 'UH1008', TRUE),
('Noah',    'Gonzalez', 'noah.gonzalez@uh.edu',     '7135551009', 1, 1, 'UH1009', TRUE),
('Isabella','Rodriguez','isabella.rodriguez@uh.edu','7135551010', 1, 2, 'UH1010', TRUE),
('Ethan',   'Hernandez','ethan.hernandez@uh.edu',   '7135551011', 1, 3, 'UH1011', TRUE),
('Mia',     'Lopez',    'mia.lopez@uh.edu',         '7135551012', 1, 4, 'UH1012', TRUE),
('Lucas',   'Smith',    'lucas.smith@uh.edu',       '7135551013', 1, 1, 'UH1013', TRUE),
('Charlotte','Davis',   'charlotte.davis@uh.edu',   '7135551014', 1, 2, 'UH1014', TRUE),
('Mason',   'Miller',   'mason.miller@uh.edu',      '7135551015', 1, 3, 'UH1015', TRUE),
('Amelia',  'Wilson',   'amelia.wilson@uh.edu',     '7135551016', 1, 4, 'UH1016', TRUE),
('Logan',   'Anderson', 'logan.anderson@uh.edu',    '7135551017', 1, 1, 'UH1017', TRUE),
('Harper',  'Thomas',   'harper.thomas@uh.edu',     '7135551018', 1, 2, 'UH1018', TRUE),
('Elijah',  'Taylor',   'elijah.taylor@uh.edu',     '7135551019', 1, 3, 'UH1019', TRUE),
('Evelyn',  'Moore',    'evelyn.moore@uh.edu',      '7135551020', 1, 4, 'UH1020', TRUE),
('James',   'Jackson',  'james.jackson@uh.edu',     '7135551021', 1, 1, 'UH1021', TRUE),
('Abigail', 'White',    'abigail.white@uh.edu',     '7135551022', 1, 2, 'UH1022', TRUE);

-- Tutors (role_id = 2) → user_ids 29..34
INSERT INTO User (first_name, last_name, email, phone, role_id, department_id, university_id, is_active) VALUES
('Michael', 'Chen',     'michael.chen@uh.edu',      '7135552003', 2, 1, 'UH2003', TRUE),  -- 29
('Olivia',  'Singh',    'olivia.singh@uh.edu',      '7135552004', 2, 2, 'UH2004', TRUE),  -- 30
('Daniel',  'Park',     'daniel.park@uh.edu',       '7135552005', 2, 3, 'UH2005', TRUE),  -- 31
('Emma',    'Torres',   'emma.torres@uh.edu',       '7135552006', 2, 4, 'UH2006', TRUE),  -- 32
('William', 'Rivera',   'william.rivera@uh.edu',    '7135552007', 2, 1, 'UH2007', TRUE),  -- 33
('Ava',     'Campbell', 'ava.campbell@uh.edu',      '7135552008', 2, 2, 'UH2008', TRUE);  -- 34

-- Teaching Assistants (role_id = 3) → user_ids 35..38
INSERT INTO User (first_name, last_name, email, phone, role_id, department_id, university_id, is_active) VALUES
('Benjamin','Adams',    'benjamin.adams@uh.edu',    '7135553003', 3, 1, 'UH3003', TRUE),  -- 35
('Grace',   'Baker',    'grace.baker@uh.edu',       '7135553004', 3, 2, 'UH3004', TRUE),  -- 36
('Henry',   'Nelson',   'henry.nelson@uh.edu',      '7135553005', 3, 3, 'UH3005', TRUE),  -- 37
('Chloe',   'Carter',   'chloe.carter@uh.edu',      '7135553006', 3, 4, 'UH3006', TRUE);  -- 38

-- Instructors (role_id = 4) → user_ids 39..41
INSERT INTO User (first_name, last_name, email, phone, role_id, department_id, university_id, is_active) VALUES
('Robert',  'Perez',    'robert.perez@uh.edu',      '7135554003', 4, 1, 'UH4003', TRUE),  -- 39
('Karen',   'Roberts',  'karen.roberts@uh.edu',     '7135554004', 4, 2, 'UH4004', TRUE),  -- 40
('Thomas',  'Turner',   'thomas.turner@uh.edu',     '7135554005', 4, 3, 'UH4005', TRUE);  -- 41

-- -----------------------------------------------------------------------------
-- 2. Extra courses → course_ids 6..8
-- -----------------------------------------------------------------------------
INSERT INTO Course (department_id, course_code, course_title, course_description, credits) VALUES
(1, 'COSC 3380', 'Database Systems',       'Relational modelling, SQL, transactions, and indexing', 3),  -- 6
(2, 'MATH 3321', 'Engineering Mathematics','Linear algebra, ODEs, and Laplace transforms',          3),  -- 7
(3, 'ECE 3331',  'Programming Applications','Programming for engineering problem-solving',          3);  -- 8

-- -----------------------------------------------------------------------------
-- 3. Extra topics → topic_ids 11..20
-- -----------------------------------------------------------------------------
INSERT INTO Topic (course_id, topic_name, topic_description) VALUES
(6, 'ER Modelling',            'Entity-relationship design and normalisation'),       -- 11
(6, 'SQL Joins & Subqueries',  'INNER/OUTER joins and correlated subqueries'),        -- 12
(6, 'Window Functions',        'RANK, ROW_NUMBER, OVER clauses'),                     -- 13
(6, 'Transactions & Isolation','ACID, locking, and isolation levels'),                -- 14
(7, 'Matrix Operations',       'Addition, multiplication, inverses'),                 -- 15
(7, 'Eigenvalues',             'Characteristic polynomials and eigenvectors'),        -- 16
(8, 'Control Flow',            'Loops, conditionals, early returns'),                 -- 17
(8, 'Arrays & Vectors',        'Dynamic arrays and common operations'),               -- 18
(1, 'Functions & Recursion',   'Function design and recursive thinking'),             -- 19
(3, 'Integrals',               'Antiderivatives and definite integrals');             -- 20

-- -----------------------------------------------------------------------------
-- 4. Extra tutor-course assignments
--    INSERT IGNORE so duplicate (tutor_user_id, course_id) pairs are skipped.
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO Tutor_Course (tutor_user_id, course_id, assigned_since, is_active) VALUES
( 5, 6, '2026-02-01', TRUE),   -- David Lee     -> Database Systems
( 6, 7, '2026-02-05', TRUE),   -- Sophia Nguyen -> Eng Math
(29, 1, '2026-02-10', TRUE),   -- Michael Chen  -> Intro Programming
(29, 2, '2026-02-10', TRUE),   -- Michael Chen  -> Data Structures
(29, 6, '2026-02-10', TRUE),   -- Michael Chen  -> Database Systems
(30, 3, '2026-02-12', TRUE),   -- Olivia Singh  -> Calculus I
(30, 7, '2026-02-12', TRUE),   -- Olivia Singh  -> Eng Math
(31, 4, '2026-02-15', TRUE),   -- Daniel Park   -> Circuit Analysis
(31, 8, '2026-02-15', TRUE),   -- Daniel Park   -> ECE Programming
(32, 5, '2026-02-18', TRUE),   -- Emma Torres   -> University Physics
(33, 2, '2026-02-20', TRUE),   -- William Rivera-> Data Structures
(33, 6, '2026-02-20', TRUE),   -- William Rivera-> Database Systems
(34, 3, '2026-02-22', TRUE),   -- Ava Campbell  -> Calculus I
(34, 7, '2026-02-22', TRUE),   -- Ava Campbell  -> Eng Math
(35, 1, '2026-02-25', TRUE),   -- Benjamin (TA) -> Intro Programming
(35, 6, '2026-02-25', TRUE),   -- Benjamin (TA) -> Database Systems
(36, 3, '2026-02-26', TRUE),   -- Grace (TA)    -> Calculus I
(37, 4, '2026-02-27', TRUE),   -- Henry (TA)    -> Circuit Analysis
(38, 5, '2026-02-28', TRUE),   -- Chloe (TA)    -> University Physics
(39, 1, '2026-03-01', TRUE),   -- Robert (Inst.) -> Intro Programming
(40, 3, '2026-03-02', TRUE),   -- Karen  (Inst.) -> Calculus I
(41, 4, '2026-03-03', TRUE);   -- Thomas (Inst.) -> Circuit Analysis

-- -----------------------------------------------------------------------------
-- 5. Extra availability slots
--    Phase-3 seed used slot_ids 1..8.  New inserts fill 9..67.
-- -----------------------------------------------------------------------------

-- 5a. Historical slots already booked  (slot_ids 9..30 — 22 rows)
INSERT INTO Availability_Slot (provider_user_id, course_id, slot_date, start_time, end_time, mode, location, meeting_link, slot_status) VALUES
(29, 1, '2026-04-15','09:00:00','10:00:00','In-Person','PGH 232', NULL,                               'Booked'),   -- 9
(29, 2, '2026-04-15','11:00:00','12:00:00','Online',   NULL,     'https://meet.google.com/cosc2-a',   'Booked'),   -- 10
(30, 3, '2026-04-15','13:00:00','14:00:00','In-Person','PGH 302', NULL,                               'Booked'),   -- 11
(31, 4, '2026-04-15','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/ece-b',     'Booked'),   -- 12
(32, 5, '2026-04-16','10:00:00','11:00:00','In-Person','SR1 110', NULL,                               'Booked'),   -- 13
(33, 6, '2026-04-16','12:00:00','13:00:00','Online',   NULL,     'https://meet.google.com/db-c',      'Booked'),   -- 14
(34, 7, '2026-04-16','15:00:00','16:00:00','In-Person','PGH 120', NULL,                               'Booked'),   -- 15
(29, 1, '2026-04-17','09:00:00','10:00:00','Online',   NULL,     'https://meet.google.com/cosc1-d',   'Booked'),   -- 16
(30, 3, '2026-04-17','11:00:00','12:00:00','In-Person','PGH 302', NULL,                               'Booked'),   -- 17
(35, 1, '2026-04-17','13:00:00','14:00:00','Online',   NULL,     'https://meet.google.com/cosc1-e',   'Booked'),   -- 18
(36, 3, '2026-04-18','10:00:00','11:00:00','In-Person','PGH 302', NULL,                               'Booked'),   -- 19
(37, 4, '2026-04-18','14:00:00','15:00:00','In-Person','CBB 206', NULL,                               'Booked'),   -- 20
(38, 5, '2026-04-18','16:00:00','17:00:00','Online',   NULL,     'https://meet.google.com/phys-f',    'Booked'),   -- 21
(31, 8, '2026-04-19','10:00:00','11:00:00','Online',   NULL,     'https://meet.google.com/ece-g',     'Booked'),   -- 22
(32, 5, '2026-04-19','13:00:00','14:00:00','In-Person','SR1 110', NULL,                               'Booked'),   -- 23
(33, 2, '2026-04-20','09:00:00','10:00:00','Online',   NULL,     'https://meet.google.com/ds-h',      'Booked'),   -- 24
(34, 3, '2026-04-20','11:00:00','12:00:00','In-Person','PGH 302', NULL,                               'Booked'),   -- 25
(29, 6, '2026-04-20','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/db-i',      'Booked'),   -- 26
(30, 7, '2026-04-21','09:00:00','10:00:00','In-Person','PGH 120', NULL,                               'Booked'),   -- 27
(31, 4, '2026-04-21','11:00:00','12:00:00','Online',   NULL,     'https://meet.google.com/ece-j',     'Booked'),   -- 28
(35, 6, '2026-04-21','13:00:00','14:00:00','In-Person','PGH 232', NULL,                               'Booked'),   -- 29
(36, 3, '2026-04-21','15:00:00','16:00:00','Online',   NULL,     'https://meet.google.com/calc-k',    'Booked');   -- 30

-- 5b. Historical cancelled slots  (slot_ids 31..32)
INSERT INTO Availability_Slot (provider_user_id, course_id, slot_date, start_time, end_time, mode, location, meeting_link, slot_status) VALUES
(29, 1, '2026-04-14','16:00:00','17:00:00','Online',   NULL,     'https://meet.google.com/cancel-1',  'Cancelled'),-- 31
(32, 5, '2026-04-15','08:00:00','09:00:00','In-Person','SR1 110', NULL,                               'Cancelled');-- 32

-- 5c. Future Available slots  (slot_ids 33..67 — all still bookable)
INSERT INTO Availability_Slot (provider_user_id, course_id, slot_date, start_time, end_time, mode, location, meeting_link, slot_status) VALUES
(29, 1, '2026-04-22','09:00:00','10:00:00','In-Person','PGH 232', NULL,                               'Available'),-- 33
(29, 1, '2026-04-22','10:00:00','11:00:00','In-Person','PGH 232', NULL,                               'Available'),-- 34
(29, 2, '2026-04-22','13:00:00','14:00:00','Online',   NULL,     'https://meet.google.com/cosc2-22',  'Available'),-- 35
(29, 6, '2026-04-22','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/db-22',     'Available'),-- 36
(30, 3, '2026-04-22','11:00:00','12:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 37
(30, 7, '2026-04-22','15:00:00','16:00:00','Online',   NULL,     'https://meet.google.com/math-22',   'Available'),-- 38
(31, 4, '2026-04-23','09:00:00','10:00:00','In-Person','CBB 206', NULL,                               'Available'),-- 39
(31, 8, '2026-04-23','11:00:00','12:00:00','Online',   NULL,     'https://meet.google.com/ece-23',    'Available'),-- 40
(32, 5, '2026-04-23','13:00:00','14:00:00','In-Person','SR1 110', NULL,                               'Available'),-- 41
(33, 2, '2026-04-23','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/ds-23',     'Available'),-- 42
(33, 6, '2026-04-23','16:00:00','17:00:00','Online',   NULL,     'https://meet.google.com/db-23',     'Available'),-- 43
(34, 3, '2026-04-24','09:00:00','10:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 44
(34, 7, '2026-04-24','10:00:00','11:00:00','In-Person','PGH 120', NULL,                               'Available'),-- 45
(35, 1, '2026-04-24','13:00:00','14:00:00','Online',   NULL,     'https://meet.google.com/cosc1-24',  'Available'),-- 46
(35, 6, '2026-04-24','15:00:00','16:00:00','In-Person','PGH 232', NULL,                               'Available'),-- 47
(36, 3, '2026-04-25','10:00:00','11:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 48
(37, 4, '2026-04-25','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/ece-25',    'Available'),-- 49
(38, 5, '2026-04-25','16:00:00','17:00:00','In-Person','SR1 110', NULL,                               'Available'),-- 50
(29, 1, '2026-04-27','09:00:00','10:00:00','In-Person','PGH 232', NULL,                               'Available'),-- 51
(29, 6, '2026-04-27','11:00:00','12:00:00','Online',   NULL,     'https://meet.google.com/db-27',     'Available'),-- 52
(30, 3, '2026-04-27','13:00:00','14:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 53
(31, 4, '2026-04-27','15:00:00','16:00:00','Online',   NULL,     'https://meet.google.com/ece-27',    'Available'),-- 54
(32, 5, '2026-04-28','10:00:00','11:00:00','In-Person','SR1 110', NULL,                               'Available'),-- 55
(33, 6, '2026-04-28','13:00:00','14:00:00','Online',   NULL,     'https://meet.google.com/db-28',     'Available'),-- 56
(34, 7, '2026-04-28','15:00:00','16:00:00','In-Person','PGH 120', NULL,                               'Available'),-- 57
(35, 1, '2026-04-29','09:00:00','10:00:00','Online',   NULL,     'https://meet.google.com/cosc1-29',  'Available'),-- 58
(36, 3, '2026-04-29','11:00:00','12:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 59
(37, 4, '2026-04-29','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/ece-29',    'Available'),-- 60
(38, 5, '2026-04-30','10:00:00','11:00:00','In-Person','SR1 110', NULL,                               'Available'),-- 61
(29, 2, '2026-04-30','13:00:00','14:00:00','Online',   NULL,     'https://meet.google.com/ds-30',     'Available'),-- 62
(30, 3, '2026-04-30','15:00:00','16:00:00','In-Person','PGH 302', NULL,                               'Available'),-- 63
(31, 8, '2026-05-01','09:00:00','10:00:00','Online',   NULL,     'https://meet.google.com/ece-mon',   'Available'),-- 64
(33, 6, '2026-05-04','11:00:00','12:00:00','In-Person','PGH 232', NULL,                               'Available'),-- 65
(34, 3, '2026-05-05','14:00:00','15:00:00','Online',   NULL,     'https://meet.google.com/calc-05',   'Available'),-- 66
(35, 1, '2026-05-06','10:00:00','11:00:00','In-Person','PGH 232', NULL,                               'Available');-- 67

-- -----------------------------------------------------------------------------
-- 6. Bookings for the 22 'Booked' historical slots (9..30)
-- -----------------------------------------------------------------------------
INSERT INTO Booking (slot_id, student_user_id, course_id, topic_id, booking_status, booking_timestamp) VALUES
( 9,  1, 1,  1,  'Completed', '2026-04-14 08:30:00'),
(10, 11, 2,  3,  'Completed', '2026-04-14 09:15:00'),
(11, 12, 3,  5,  'Completed', '2026-04-14 10:00:00'),
(12, 13, 4,  7,  'No-Show',   '2026-04-14 11:20:00'),
(13, 14, 5,  9,  'Completed', '2026-04-15 08:00:00'),
(14, 15, 6, 11,  'Completed', '2026-04-15 09:10:00'),
(15, 16, 7, 15,  'Completed', '2026-04-15 10:30:00'),
(16, 17, 1,  2,  'Completed', '2026-04-16 09:00:00'),
(17, 18, 3,  6,  'Completed', '2026-04-16 10:00:00'),
(18, 19, 1, 19,  'Completed', '2026-04-16 12:00:00'),
(19, 20, 3,  5,  'Completed', '2026-04-17 09:45:00'),
(20, 21, 4,  7,  'No-Show',   '2026-04-17 13:00:00'),
(21, 22, 5, 10,  'Completed', '2026-04-17 14:00:00'),
(22, 23, 8, 17,  'Completed', '2026-04-18 09:30:00'),
(23,  1, 5,  9,  'Completed', '2026-04-18 10:15:00'),
(24,  2, 2,  4,  'Completed', '2026-04-19 08:50:00'),
(25,  4, 3,  6,  'Completed', '2026-04-19 10:10:00'),
(26, 11, 6, 12,  'Completed', '2026-04-19 13:30:00'),
(27, 12, 7, 15,  'No-Show',   '2026-04-20 08:10:00'),
(28, 13, 4,  7,  'Completed', '2026-04-20 10:30:00'),
(29, 14, 6, 13,  'Completed', '2026-04-20 12:45:00'),
(30, 15, 3,  6,  'Completed', '2026-04-20 14:00:00');

-- -----------------------------------------------------------------------------
-- 7. Session records for the 22 bookings above (booking_ids 8..29)
--    Completed rows → session_status = 'Completed'
--    No-Show rows   → session_status = 'No-Show'
-- -----------------------------------------------------------------------------
INSERT INTO Session_Record (booking_id, actual_start_time, actual_end_time, duration_minutes, attendance_status, session_status, session_notes) VALUES
( 8, '2026-04-15 09:00:00','2026-04-15 09:55:00', 55,'Attended',          'Completed','Reviewed variables, loops, and conditionals.'),
( 9, '2026-04-15 11:00:00','2026-04-15 11:50:00', 50,'Attended',          'Completed','Walked through doubly-linked list insertions.'),
(10, '2026-04-15 13:00:00','2026-04-15 13:45:00', 45,'Attended',          'Completed','Covered limits via epsilon-delta.'),
(11, '2026-04-15 14:00:00','2026-04-15 14:10:00', 10,'Missed by Student', 'No-Show',  'Student did not arrive.'),
(12, '2026-04-16 10:00:00','2026-04-16 10:55:00', 55,'Attended',          'Completed','Newton laws + free-body diagrams.'),
(13, '2026-04-16 12:00:00','2026-04-16 12:55:00', 55,'Attended',          'Completed','ER modelling warm-up; normalised a simple schema.'),
(14, '2026-04-16 15:00:00','2026-04-16 15:45:00', 45,'Attended',          'Completed','Matrix multiplication + identity matrix.'),
(15, '2026-04-17 09:00:00','2026-04-17 09:55:00', 55,'Attended',          'Completed','Debugged a recursion exercise.'),
(16, '2026-04-17 11:00:00','2026-04-17 11:50:00', 50,'Attended',          'Completed','Applications of derivatives — optimisation.'),
(17, '2026-04-17 13:00:00','2026-04-17 13:55:00', 55,'Attended',          'Completed','Introduced integrals with worked examples.'),
(18, '2026-04-18 10:00:00','2026-04-18 10:45:00', 45,'Attended',          'Completed','Practice problems on differentiation.'),
(19, '2026-04-18 14:00:00','2026-04-18 14:05:00',  5,'Missed by Student', 'No-Show',  'Student emailed after the slot.'),
(20, '2026-04-18 16:00:00','2026-04-18 16:55:00', 55,'Attended',          'Completed','Work-energy theorem examples.'),
(21, '2026-04-19 10:00:00','2026-04-19 10:50:00', 50,'Attended',          'Completed','Control flow + nested loops.'),
(22, '2026-04-19 13:00:00','2026-04-19 13:55:00', 55,'Attended',          'Completed','Mechanics lab walkthrough.'),
(23, '2026-04-20 09:00:00','2026-04-20 09:50:00', 50,'Attended',          'Completed','Stacks, queues, and circular buffers.'),
(24, '2026-04-20 11:00:00','2026-04-20 11:45:00', 45,'Attended',          'Completed','Derivative applications review.'),
(25, '2026-04-20 14:00:00','2026-04-20 14:55:00', 55,'Attended',          'Completed','Window functions — ROW_NUMBER + RANK.'),
(26, '2026-04-21 09:00:00','2026-04-21 09:10:00', 10,'Missed by Student', 'No-Show',  'Student did not show.'),
(27, '2026-04-21 11:00:00','2026-04-21 11:55:00', 55,'Attended',          'Completed','Full circuit analysis worksheet.'),
(28, '2026-04-21 13:00:00','2026-04-21 13:50:00', 50,'Attended',          'Completed','Transactions + isolation levels demo.'),
(29, '2026-04-21 15:00:00','2026-04-21 15:55:00', 55,'Attended',          'Completed','Calculus I integrals review session.');

-- -----------------------------------------------------------------------------
-- 8. Feedback — 10 out of 18 new completed sessions deliberately un-rated
--    (leaves the "Submit Feedback" tab with work to do during the demo)
-- -----------------------------------------------------------------------------
INSERT INTO Feedback (session_id, student_user_id, rating, comments) VALUES
( 8,  1, 5, 'Jordan nailed the loops explanation — very patient.'),
( 9, 11, 4, 'Solid session, would have loved more live coding.'),
(10, 12, 5, 'Calculus finally clicked, thanks!'),
(13, 15, 5, 'Crystal clear ER diagram walkthrough.'),
(14, 16, 4, 'Great pace, answered all my questions.'),
(15, 17, 5, 'Recursion makes sense now. Amazing tutor.'),
(16, 18, 4, 'Really helpful for the upcoming midterm.'),
(17, 19, 5, 'Loved the worked integral examples.'),
(20, 22, 4, 'Work-energy theorem clicked in the second example.'),
(25, 15, 5, 'Window functions cleared up — RANK vs DENSE_RANK made sense.');
-- Sessions 12, 18, 21, 22, 23, 24, 27, 28, 29 intentionally left without
-- feedback so the Feedback-Submit tab always has demo material.

-- -----------------------------------------------------------------------------
-- 9. Future Pending/Confirmed bookings (live-demo material)
--    Pick four Available slots (ids 34, 36, 38, 40) and mark them Booked.
-- -----------------------------------------------------------------------------
INSERT INTO Booking (slot_id, student_user_id, course_id, topic_id, booking_status, booking_timestamp) VALUES
(34, 21, 1,  2, 'Pending',   '2026-04-21 20:00:00'),
(36, 22, 6, 12, 'Confirmed', '2026-04-21 20:05:00'),
(38, 17, 7, 15, 'Confirmed', '2026-04-21 20:10:00'),
(40, 18, 8, 17, 'Pending',   '2026-04-21 20:15:00');

UPDATE Availability_Slot SET slot_status = 'Booked' WHERE slot_id IN (34, 36, 38, 40);

-- -----------------------------------------------------------------------------
-- 10. Sanity check
-- -----------------------------------------------------------------------------
SELECT 'Total users'        AS metric, COUNT(*) AS value FROM User
UNION ALL SELECT 'Total courses',        COUNT(*) FROM Course
UNION ALL SELECT 'Total slots',          COUNT(*) FROM Availability_Slot
UNION ALL SELECT '  Available',          COUNT(*) FROM Availability_Slot WHERE slot_status='Available'
UNION ALL SELECT '  Booked',             COUNT(*) FROM Availability_Slot WHERE slot_status='Booked'
UNION ALL SELECT '  Cancelled',          COUNT(*) FROM Availability_Slot WHERE slot_status='Cancelled'
UNION ALL SELECT 'Total bookings',       COUNT(*) FROM Booking
UNION ALL SELECT '  Pending',            COUNT(*) FROM Booking WHERE booking_status='Pending'
UNION ALL SELECT '  Confirmed',          COUNT(*) FROM Booking WHERE booking_status='Confirmed'
UNION ALL SELECT '  Completed',          COUNT(*) FROM Booking WHERE booking_status='Completed'
UNION ALL SELECT '  No-Show',            COUNT(*) FROM Booking WHERE booking_status='No-Show'
UNION ALL SELECT 'Session records',      COUNT(*) FROM Session_Record
UNION ALL SELECT 'Feedback submitted',   COUNT(*) FROM Feedback
UNION ALL SELECT 'Feedback pending',
       (SELECT COUNT(*) FROM Session_Record s
        LEFT JOIN Feedback f ON f.session_id = s.session_id
        WHERE s.session_status='Completed' AND f.feedback_id IS NULL);
