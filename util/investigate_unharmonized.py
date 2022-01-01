import sqlite3
import datetime
import pandas as pd
import click


# , help='attribute name patten using SQL %,_, etc.')
@click.command()
@click.option('--pattern', required=True, help='attribute name patten using SQL %,_, etc.')
@click.option('--database_file', type=click.Path(exists=True), default="target/biosample_basex.db", show_default=True)
@click.option('--output_file', type=click.Path(), default="target/investigate_unharmonized.tsv", show_default=True)
def investigate_unharmonized(pattern, database_file, output_file):
    """Find rows in all_attribs where the attribute_name matches the pattern."""
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

    # 2022-01-01 about 6 minutes
    print(datetime.datetime.now())
    patterns_res_frame = pd.read_sql_query(pattern_query, conn)
    print(datetime.datetime.now())

    patterns_res_frame.to_csv(output_file, sep="\t", index=False)


if __name__ == '__main__':
    investigate_unharmonized()
