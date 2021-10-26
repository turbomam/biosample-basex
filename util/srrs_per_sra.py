import pandas as pd

per_srr_input = "target/biosample_srrs.txt"
per_srr_col_delim = "|"
per_srr_cols = ["sra", "srr"]
per_sra_ouput = "target/biosample_srrs.tsv"
per_sra_srr_delim = "|"
per_sra_col_delim = "\t"

biosample_srrs = pd.read_csv(
    per_srr_input, sep=per_srr_col_delim, index_col=False, names=per_srr_cols
)

grouped = biosample_srrs.groupby("sra")["srr"].apply(list).reset_index(name="srrs")

grouped["srrs"] = grouped["srrs"].str.join(per_sra_srr_delim)

grouped.to_csv(per_sra_ouput, sep=per_sra_col_delim, index=False)

