import sqlite3
# import sqlalchemy
# dbEngine=sqlalchemy.create_engine('sqlite:////home/stephen/db1.db') # ensure this is the correct path for the sqlite file. 

# command line parameters?
# config file?
db1_path = 'extras/harmonized_table.db'
table1 = "biosample"

db2_path = 'target/biosample_basex.db'
table2 = "biosample_basex_merged"


cnx1 = sqlite3.connect(db1_path)
cursor1 = cnx1.cursor()
cursor1.execute("SELECT * FROM " + table1 + " limit 1")
names1 = set([description[0] for description in cursor1.description])
# print(names1)


cnx2 = sqlite3.connect(db2_path)
cursor2 = cnx2.cursor()
cursor2.execute("SELECT * FROM " + table2 + " limit 1")
names2 = set([description[0] for description in cursor2.description])
# print(names2)

db1_only = list(names1 - names2)
db1_only.sort()

db2_only = list(names2 - names1)
db2_only.sort()

db_intersection = list(names1.intersection(names2))
db_intersection.sort()


print(db1_path)
print(table1)
print(db1_only)

print("\n")


print(db2_path)
print(table2)
print(db2_only)

print("\n")


print(db_intersection)
