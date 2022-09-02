import sqlite3
import datetime
import pandas as pd

import os

from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.

# pd.set_option('display.max_columns', 500)

# click
# logger

chunk_size = int(os.getenv("PIVOT_CHUNK_SIZE"))
print(f"chunk_size = {chunk_size}")

database_file = os.getenv("DATABASE_FOR_PIVOTING")
print(f"database_file = {database_file}")

print(f"current working directory: {os.getcwd()}")

# stats = os.stat(os.path.join(os.getcwd(), database_file))
# print(stats.st_size)

# 320 054 875 rows about 24 341 464 biosamples

conn = sqlite3.connect(database_file)
# print(conn)

# all_attribs
# non_attribute_metadata

# # slow even with index
# # 50 seconds
# aa_rc_q = 'select count(1) from all_attribs'
# print(datetime.datetime.now())
# cursor = conn.execute(aa_rc_q)
# aa_rc_res = cursor.fetchone()
# print(aa_rc_res[0])

aa_max_id_q = 'select max(cast(raw_id as int)) from all_attribs aa'
print("counting biosamples")
print(datetime.datetime.now())
cursor = conn.execute(aa_max_id_q)
aa_max_id_res = cursor.fetchone()[0]
print(f"{aa_max_id_res} biosamples")

all_hns_q = '''
select
    distinct harmonized_name
from
    all_attribs aa
where
    harmonized_name != ''
    and harmonized_name is not null
order by
    harmonized_name'''

print("discovering attributes")
print(datetime.datetime.now())
all_hns_frame = pd.read_sql_query(all_hns_q, conn)
print(all_hns_frame.shape)
# print(all_hns_frame)

all_hns = list(all_hns_frame['harmonized_name'])
# print(all_hns)

all_hns.insert(0, "raw_id")

empty_frame = pd.DataFrame(columns=all_hns)
# print(empty_frame.dtypes)

drop_aa_q = 'drop table if exists harmonized_wide'
conn.execute(drop_aa_q)

if aa_max_id_res < chunk_size:
    chunk_size = aa_max_id_res / 3

starts = list(range(0, aa_max_id_res, chunk_size))
stops = list(range(chunk_size - 1, aa_max_id_res + chunk_size, chunk_size))

start_stops = dict(zip(starts, stops))

for start, stop in start_stops.items():
    print(f"{start} to {stop}")
    hns_rows_in_range_q = f'''
    select
    --    distinct raw_id, harmonized_name, GROUP_CONCAT(value, "|||") as value
    raw_id, harmonized_name, value
    from
        all_attribs aa
    where
        harmonized_name !="" and harmonized_name is not null
        and raw_id > {start}
        and raw_id < {stop}
        group by raw_id, harmonized_name'''
    print("starting query")
    print(datetime.datetime.now())
    hns_rows_in_range_frame = pd.read_sql_query(hns_rows_in_range_q, conn)
    print("query done")
    print(datetime.datetime.now())

    pivoted_in_range = hns_rows_in_range_frame.pivot(index="raw_id", columns="harmonized_name", values="value")
    print("pivot done")
    print(datetime.datetime.now())

    harmonized_wide = pd.concat([empty_frame, pivoted_in_range])
    print("frame concatenation done")
    print(datetime.datetime.now())

    harmonized_wide["raw_id"] = harmonized_wide.index

    harmonized_wide.to_sql("harmonized_wide", conn, index=False, if_exists="append")
    print("insertion back into SQLite done")
    print(datetime.datetime.now())
