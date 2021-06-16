#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 15 09:50:14 2021

@author: MAM
"""

import os
import pandas as pd
import datetime

print(os.getcwd())

# print statements lag
# use log messages or print to std err instead?

biosample_attribute_value_long_file = "target/biosample_attribute_value_xq.tsv"


# one minute?
print(datetime.datetime.now())
print("reading " + biosample_attribute_value_long_file)
biosample_attribute_value_long = pd.read_csv(biosample_attribute_value_long_file, sep='\t')
print(datetime.datetime.now())

# #---- probably slow. should time this too
# # is this causing a out of memory condition? lower priority than doing the pivot
# print(datetime.datetime.now())
# print("counting duplicated sample/harmonized name pairs")
# duplicated_sample_harmonized_names = biosample_attribute_value_long.groupby(
#     ['accession', 'harmonized_name']).size().reset_index().rename(
#     columns={0: 'count'})
# print(datetime.datetime.now())
# print("only keeping duplicates")
# duplicated_sample_harmonized_names = duplicated_sample_harmonized_names[duplicated_sample_harmonized_names['count'] > 1]
# print(datetime.datetime.now())
# print("sorting")
# duplicated_sample_harmonized_names.sort_values(['count', 'harmonized_name', 'accession'], ascending=[False, True, True])
# print(datetime.datetime.now())
# duplicated_sample_harmonized_names.to_csv("target/duplicated_sample_harmonized_names.csv", index=False, sep="\t")

#---- probably slow. should time this too
print(datetime.datetime.now())
print("casting long data to strings")
biosample_attribute_value_long = biosample_attribute_value_long.applymap(str)

print(datetime.datetime.now())
print("pivoting with | join of duplicate values")
biosample_attribute_value_wide = biosample_attribute_value_long.pivot_table(index='accession',
                                                                            columns='harmonized_name',
                                                                            values='attribute_value',
                                                                            aggfunc='|'.join)
print(datetime.datetime.now())

biosample_attribute_value_wide.to_csv("target/biosample_attribute_value_wide.tsv", index=False, sep="\t")

