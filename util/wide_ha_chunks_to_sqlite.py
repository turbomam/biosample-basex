import pandas as pd
import glob
import sqlite3

from datetime import datetime

from sqlalchemy import create_engine
engine = create_engine('sqlite:///target/biosample_basex.db', echo=False)

# can set lower in dev mode
# be careful, don't forget to set back to soemthing well higher than the number of TSVs
cat_cout = 99

wide_root = "target/chunks_wide"
all_files = glob.glob(wide_root + "/*.tsv")

all_files.sort()

chunk_list = []
column_name_set = set()

for filename in all_files[0:cat_cout]:
    print(filename)
    print(datetime.now().strftime("%H:%M:%S"))
    with open(filename) as f:
        first_line = f.readline()
        # print(first_line)
        col_names = first_line.split()
        column_name_set = column_name_set.union(set(col_names))

column_name_list = list(column_name_set)
column_name_list.remove("raw_id")
column_name_list.sort()
column_name_list.insert(0,"raw_id")


print(column_name_list)
print(len(column_name_list))

for filename in all_files[0:cat_cout]:
    print(filename)
    print(datetime.now().strftime("%H:%M:%S"))
    df = pd.read_csv(filename, index_col=None, sep="\t", low_memory=False)
    print(df.shape)
    print(datetime.now().strftime("%H:%M:%S"))
    current_cols = list(df.columns)
    missing_cols = list(set(column_name_list) - set(current_cols))
    missing_cols.sort()
    # print(missing_cols)
    for i in missing_cols:
        df[i] = ""
    print(datetime.now().strftime("%H:%M:%S"))
    df = df[column_name_list]
    print(datetime.now().strftime("%H:%M:%S"))
    print(df.shape)
    df.to_sql('catted_wide_harmonized_attributes', con=engine, if_exists="append", index=False)
    print(datetime.now().strftime("%H:%M:%S"))
