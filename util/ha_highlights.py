import sqlite3
import datetime
import pandas as pd
import click


# , help='attribute name patten using SQL %,_, etc.')
@click.command()
@click.option('--database_file', type=click.Path(exists=True), default="target/biosample_basex.db", show_default=True)
# @click.option('--output_file', type=click.Path(), default="target/ha_highlights.tsv", show_default=True)
@click.option('--output_dir', type=click.Path(), default="reports", show_default=True)
def ha_highlights(database_file, output_dir):
    """Tabulate the values of some attributes with harmonized names by environmental package"""
    conn = sqlite3.connect(database_file)

    overall_query = f"""
    select
        hw.raw_id,
        hwr.env_package,
        hw.bacteria_carb_prod,
        hw.collection_date,
        hw.experimental_factor,
        hw.investigation_type,
        hw.link_addit_analys,
        hw.microbial_biomass,
        hw.samp_collect_device,
        hw.samp_mat_process,
        hw.samp_size,
        hw.sample_name,
        hw.sieving,
        hw.size_frac,
        hw.source_material_id,
        hw.store_cond
    from
        harmonized_wide hw
    join harmonized_wide_repaired hwr on
        hw.raw_id = hwr.raw_id;
    """

    # 2022-01-01 about 10 minutes
    print(datetime.datetime.now())
    highlights_frame = pd.read_sql_query(overall_query, conn)
    print(datetime.datetime.now())

    # overall_res.to_csv(highlights_frame, sep="\t", index=False)

    hfc = list(highlights_frame.columns)
    hfc.remove("raw_id")
    hfc.remove("env_package")
    hfc.sort()

    for i in hfc:
        print(i)
        # use path join?
        output_file = f"{output_dir}/{i}_by_env_package.tsv"
        by_env_pack = pd.DataFrame(
            highlights_frame.value_counts(["env_package", i], dropna=False)
        ).reset_index()
        by_env_pack.rename(columns={0: "count"}, inplace=True)
        #     print(by_env_pack)
        print(output_file)
        by_env_pack.to_csv(output_file, sep="\t", index=False)


if __name__ == '__main__':
    ha_highlights()
