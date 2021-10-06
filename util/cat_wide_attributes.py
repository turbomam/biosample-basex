import pandas as pd
import glob

from datetime import datetime

cat_cout = 40

wide_root = "target/chunks_wide"
all_files = glob.glob(wide_root + "/*.tsv")

output_file = "target/catted_wide_attributes.tsv"

all_files.sort()

li = []

for filename in all_files[0:cat_cout]:
    print(filename)
    print(datetime.now().strftime("%H:%M:%S"))
    df = pd.read_csv(filename, index_col=None, sep="\t", low_memory=False)
    print(df.shape)
    print(datetime.now().strftime("%H:%M:%S"))
    li.append(df)

print(datetime.now().strftime("%H:%M:%S"))    
frame = pd.concat(li, axis=0, ignore_index=True)
print(datetime.now().strftime("%H:%M:%S"))
print(frame.shape)
frame.to_csv(output_file, sep="\t", index=False)
print(datetime.now().strftime("%H:%M:%S"))

