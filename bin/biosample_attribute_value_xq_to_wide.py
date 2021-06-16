#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 15 09:50:14 2021

@author: MAM
"""

import os

import pandas as pd

print(os.getcwd())

biosample_attribute_value_long_file = "target/biosample_attribute_value_xq.tsv"

print("reading " + biosample_attribute_value_long_file)
biosample_attribute_value_long = pd.read_csv(biosample_attribute_value_long_file, sep='\t')

duplicated_sample_harmonized_names = biosample_attribute_value_long.groupby(
    ['accession', 'harmonized_name']).size().reset_index().rename(
    columns={0: 'count'})

duplicated_sample_harmonized_names = duplicated_sample_harmonized_names[duplicated_sample_harmonized_names['count'] > 1]

duplicated_sample_harmonized_names.sort_values(['count', 'harmonized_name', 'accession'], ascending=[False, True, True])

biosample_attribute_value_long = biosample_attribute_value_long.applymap(str)

biosample_attribute_value_wide = biosample_attribute_value_long.pivot_table(index='accession',
                                                                            columns='harmonized_name',
                                                                            values='attribute_value',
                                                                            aggfunc='|'.join)

biosample_attribute_value_wide.to_csv("target/biosample_attribute_value_wide.tsv", index=False, sep="\t")
duplicated_sample_harmonized_names.to_csv("target/duplicated_sample_harmonized_names.csv", index=False, sep="\t")
