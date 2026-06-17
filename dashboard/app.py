import os

import awswrangler as wr
import streamlit as st

DATABASE = os.getenv("GLUE_DATABASE", "aws_serverless_data_pipeline")
WORKGROUP = os.getenv("ATHENA_WORKGROUP", "aws-serverless-data-pipeline-workgroup")


@st.cache_data(ttl=300)
def read_query(sql: str):
    return wr.athena.read_sql_query(sql=sql, database=DATABASE, workgroup=WORKGROUP)


st.set_page_config(page_title="USGS Earthquake Pipeline", layout="wide")
st.title("USGS Earthquake Serverless Pipeline")

recent = read_query(
    """
    SELECT event_id, event_time, mag, place, latitude, longitude, depth_km, url
    FROM earthquakes
    WHERE dt >= date_format(current_date - interval '7' day, '%Y-%m-%d')
    ORDER BY event_time DESC
    LIMIT 200
    """
)

col1, col2, col3 = st.columns(3)
col1.metric("Recent events", len(recent))
col2.metric("Max magnitude", round(float(recent["mag"].max()), 2) if not recent.empty else 0)
col3.metric("M5.0+ events", int((recent["mag"] >= 5).sum()) if not recent.empty else 0)

if not recent.empty:
    st.map(
        recent.rename(columns={"latitude": "lat", "longitude": "lon"}),
        latitude="lat",
        longitude="lon",
    )

daily = read_query(
    """
    SELECT dt, count(*) AS quake_count
    FROM earthquakes
    WHERE dt >= date_format(current_date - interval '30' day, '%Y-%m-%d')
    GROUP BY dt
    ORDER BY dt
    """
)
st.subheader("Daily Counts")
st.bar_chart(daily, x="dt", y="quake_count")

st.subheader("Magnitude 5.0+ Events")
st.dataframe(recent[recent["mag"] >= 5].sort_values("event_time", ascending=False))
