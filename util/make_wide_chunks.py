from os import listdir
from os.path import join
import pandas as pd

data_root = "target/chunks"
output_root = "target/chunks_wide"

data_files = listdir(data_root)
data_files.sort()

for file in data_files:
    print(file)
    full_path = join(data_root, file)
#     print(full_path)
    long_chunk = pd.read_csv(full_path, sep="\t")
    wide_chunk = long_chunk.pivot(index=["id"], 
                    columns='attribute', 
                    values='value')
    wide_chunk.reset_index(level=0, inplace=True)
#     print(wide_chunk)
    output_path = join(output_root, file)
#     print(output_path)
    wide_chunk.to_csv(output_path, sep="\t", index=False)
