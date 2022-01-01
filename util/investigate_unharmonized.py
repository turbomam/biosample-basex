import sqlite3
import datetime
import pandas as pd

database_file = "target/biosample_basex.db"
# "../target/biosample_basex.db"
pattern = '%grow%facil%'
output_file = 'target/investigate_unharmonized.tsv'

conn = sqlite3.connect(database_file)

pattern_query = f"""
select
	aa.raw_id ,
	hwr.env_package,
	aa.attribute_name ,
	aa.harmonized_name ,
	aa.value
from
	all_attribs aa
join harmonized_wide_repaired hwr 
	on
	aa.raw_id = hwr.raw_id
where
	lower(attribute_name) like '{pattern}'
;
"""

# print(pattern_query)

print(datetime.datetime.now())
patterns_res_frame = pd.read_sql_query(pattern_query, conn)
print(datetime.datetime.now())

# print(patterns_res_frame)

patterns_res_frame.to_csv(output_file, sep="\t", index=False)
