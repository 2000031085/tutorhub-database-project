# Tutor Hub — Campus Tutoring & Office-Hours Booking Platform

A production-grade relational database system and full-stack web application for managing tutoring and office-hours scheduling on a university campus. Built as the final project for **EDS 6343 — Database Management Tools for Engineers** (Team 11, Spring 2026) at the **University of Houston**.

![Tech](https://img.shields.io/badge/MySQL-8.0-blue) ![Tech](https://img.shields.io/badge/Python-3.10+-green) ![Tech](https://img.shields.io/badge/Streamlit-1.x-red) ![Status](https://img.shields.io/badge/status-complete-success)

---

## Overview

Tutor Hub unifies tutoring and office-hours scheduling into a single normalised MySQL database with a Streamlit frontend. Students browse available slots, book transactionally, and leave feedback; tutors publish availability; administrators monitor demand and at-risk students through window-function-powered analytics.

### Highlights

- **10-table normalised schema** in MySQL 8 with foreign keys and CHECK constraints
- **Atomic booking workflow** using `sp_book_slot` with `SELECT ... FOR UPDATE` to prevent double-booking
- **Automatic audit trail** via AFTER-UPDATE triggers on Booking and Availability_Slot
- **Advanced SQL analytics** — `RANK`, `DENSE_RANK`, `NTILE`, `ROW_NUMBER`, recursive CTE, moving-average forecasting
- **Role-based Streamlit UI** — student, tutor, and admin views
- **University of Houston** branded design system (Cougar Red)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Presentation Layer    Streamlit (Python)               │
│                        Role-based pages for Student,    │
│                        Tutor, and Admin                 │
├─────────────────────────────────────────────────────────┤
│  Application Layer     db.py  (mysql-connector-python)  │
│                        Stored procedure calls           │
├─────────────────────────────────────────────────────────┤
│  Data Layer            MySQL 8                          │
│                        10 tables, 4 views,              │
│                        3 stored procedures, 3 triggers, │
│                        2 audit tables                   │
└─────────────────────────────────────────────────────────┘
```

See `er_diagram.png` / `er_diagram.svg` for the full entity-relationship diagram.

---

## Tech Stack

| Layer        | Technology                                          |
|--------------|-----------------------------------------------------|
| Database     | MySQL 8.0                                           |
| Backend      | Python 3.10+ with `mysql-connector-python`          |
| Frontend     | Streamlit + Plotly                                  |
| Theming      | Custom CSS design system (`theme.py`)               |
| Tooling      | MySQL Workbench, VS Code, Git                       |

---

## Repository Structure

```
TutorHub_App/
├── .streamlit/
│   └── config.toml                            # UH-red Streamlit theme
├── pages/
│   ├── 1_Book_Session.py
│   ├── 2_Available_Slots.py
│   ├── 3_My_Bookings.py
│   ├── 4_Admin_Dashboard.py
│   ├── 5_Feedback.py
│   └── 6_Advanced_Analytics.py
├── app.py                                     # Home page
├── db.py                                      # MySQL connection helper
├── theme.py                                   # Design system (hero, KPIs, Plotly)
├── requirements.txt
├── TEAM_11_SQL_Implementation_Phase_3.sql     # Schema + base seed
├── TutorHub_MasterLevel.sql                   # Views, procedures, triggers, analytics
├── TutorHub_DemoSeed.sql                      # Demo data for presentations
├── er_diagram.png
└── er_diagram.svg
```

> The full written project report, master-level roadmap, and final slide deck are maintained outside this repository.

---

## Getting Started

### Prerequisites

- MySQL 8.0 or newer
- Python 3.10 or newer
- `pip` and a virtual environment (recommended)

### 1. Load the database

Open MySQL Workbench (or `mysql` CLI) and execute the three SQL files **in this exact order**:

```sql
source TEAM_11_SQL_Implementation_Phase_3.sql;   -- creates TutorHub schema + base seed
source TutorHub_MasterLevel.sql;                 -- adds views, procs, triggers, indexes
source TutorHub_DemoSeed.sql;                    -- adds demo data for the UI
```

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure database credentials

Set these environment variables before running Streamlit (see `db.py`):

```bash
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_DB=TutorHub
```

### 4. Launch the app

```bash
streamlit run app.py
```

The app opens at `http://localhost:8501`. Use the sidebar to navigate between pages.

---

## Advanced SQL Layer

The `TutorHub_MasterLevel.sql` script adds a master-level SQL layer on top of the Phase 3 schema:

| Category         | Objects                                                                  |
|------------------|--------------------------------------------------------------------------|
| Views            | `vw_booking_details`, `vw_tutor_utilisation`, `vw_course_demand`, `vw_student_profile` |
| Stored procedures| `sp_book_slot` (transactional), `sp_cancel_booking`, `sp_complete_session` |
| Triggers         | `trg_booking_status_audit`, `trg_slot_status_audit`, `trg_feedback_rating_guard` |
| Audit tables     | `Booking_Audit`, `Slot_Audit`                                            |
| Performance      | 11 secondary indexes on common JOIN/WHERE paths                          |
| Analytics        | Window functions (`RANK`, `NTILE`, `ROW_NUMBER`), recursive CTEs, moving-average forecasting |

All DDL is idempotent — safe to re-run thanks to a `information_schema`-based helper procedure (`_th_create_index_if_absent`).

---

## Screens at a Glance

- **Home** — KPI tiles for users, slots, bookings, and average rating
- **Book Session** — Live booking form backed by `sp_book_slot`
- **Available Slots** — Filterable list of open tutor availability windows
- **My Bookings** — Per-student history with status breakdown
- **Admin Dashboard** — Demand by course, session outcomes, rating distribution, repeat students
- **Feedback** — Submit ratings for completed sessions
- **Advanced Analytics** — Tutor scorecard, department rankings, at-risk scoring, tutor recommender, demand heatmap, audit trail

---

## Team

Team 11 · EDS 6343 · University of Houston · Spring 2026

- Gayatri Chekuri
- Rekha Laxmi Sarojini Atluri
- Sri Vardhini Venna
- (fourth teammate)

---

## License

This project was developed as part of coursework at the University of Houston and is shared here for academic and portfolio purposes.
