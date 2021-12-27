import sqlite3
import datetime
import pandas as pd

# pd.set_option('display.max_columns', 500)

# click
# logger

database_file = '../target/biosample_basex.db'
# 320 054 875 rows about 24 341 464 biosamples
chunk_size = 1000

conn = sqlite3.connect(database_file)

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
cursor = conn.execute(aa_max_id_q)
aa_max_id_res = cursor.fetchone()[0]
print(f"{aa_max_id_res} rows")

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

all_hns_frame = pd.read_sql_query(all_hns_q, conn)
all_hns = list(all_hns_frame['harmonized_name'])
all_cols = all_hns
all_cols.insert(0, "raw_id")

empty_frame = pd.DataFrame(columns=all_cols)
# print(empty_frame.dtypes)

drop_aa_q = 'drop table if exists harmonized_wide'
conn.execute(drop_aa_q)

starts = list(range(0, aa_max_id_res, chunk_size))
stops = list(range(chunk_size - 1, aa_max_id_res + chunk_size, chunk_size))

start_stops = dict(zip(starts, stops))

for start, stop in start_stops.items():
    print(f"{start} to {stop}")
    hns_rows_in_range_q = f'''
    select
    	distinct raw_id, harmonized_name, GROUP_CONCAT(value, "|||") as value
    from
    	all_attribs aa
    where
        harmonized_name !="" and harmonized_name is not null
    	and raw_id > {start}
    	and raw_id < {stop}
    	group by raw_id, harmonized_name'''
    hns_rows_in_range_frame = pd.read_sql_query(hns_rows_in_range_q, conn)

    pivoted_in_range = hns_rows_in_range_frame.pivot(index="raw_id", columns="harmonized_name", values="value")

    harmonized_wide = pd.concat([empty_frame, pivoted_in_range])
    harmonized_wide["raw_id"] = harmonized_wide.index

    harmonized_wide.to_sql("harmonized_wide", conn, index=False, if_exists="append")
