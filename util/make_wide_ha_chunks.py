from os import listdir
from os.path import join, basename
import pandas as pd
import glob
from datetime import datetime

data_root = "target/chunks_long"
output_root = "target/chunks_wide"

# data_files = listdir(data_root)
data_files = glob.glob(data_root + "/*.tsv")
data_files.sort()

for file in data_files:
    full_path = file
    file = basename(full_path)
    print(file)
    print(full_path)
    print(datetime.now().strftime("%H:%M:%S"))
    long_chunk = pd.read_csv(full_path, sep="\t")
    print(datetime.now().strftime("%H:%M:%S"))
    wide_chunk = long_chunk.pivot(index=["raw_id"], 
                    columns='attribute', 
                    values='value')
    wide_chunk.reset_index(level=0, inplace=True)
    print(datetime.now().strftime("%H:%M:%S"))
#     print(wide_chunk)
    output_path = join(output_root, file)
    print(output_path)
    wide_chunk.to_csv(output_path, sep="\t", index=False)
    print(datetime.now().strftime("%H:%M:%S"))
