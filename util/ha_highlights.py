import sqlite3
import datetime
import pandas as pd
import click


# , help='attribute name patten using SQL %,_, etc.')
@click.command()
@click.option('--database_file', type=click.Path(exists=True), default="target/biosample_basex.db", show_default=True)
# @click.option('--output_file', type=click.Path(), default="reports/investigate_unharmonized.tsv", show_default=True)
def ha_highlights(database_file):
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

    # 2022-01-01 about XXX minutes
    print(datetime.datetime.now())
    overall_res = pd.read_sql_query(overall_query, conn)
    print(datetime.datetime.now())

    print(overall_res)


if __name__ == '__main__':
    ha_highlights()
