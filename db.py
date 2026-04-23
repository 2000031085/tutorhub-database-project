import os

import mysql.connector
import pandas as pd
import streamlit as st


@st.cache_resource
def get_connection():
    return mysql.connector.connect(
        host=os.environ.get("MYSQL_HOST", "localhost"),
        port=int(os.environ.get("MYSQL_PORT", "3306")),
        user=os.environ.get("MYSQL_USER", "root"),
        password=os.environ.get("MYSQL_PASSWORD", ""),
        database=os.environ.get("MYSQL_DB", "TutorHub"),
    )


def run_select(query, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(query, params or ())
    rows = cursor.fetchall()
    cursor.close()
    return pd.DataFrame(rows)


def run_action(query, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query, params or ())
    conn.commit()
    cursor.close()


def run_transaction(queries_with_params):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        for query, params in queries_with_params:
            cursor.execute(query, params or ())
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()