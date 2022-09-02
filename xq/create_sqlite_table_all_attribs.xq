sql:init(
  "org.sqlite.JDBC"
),
let $conn := sql:connect(
  "jdbc:sqlite:database.db"
)
return (
sql:execute(
    $conn, "drop table if exists all_attribs"
  ),
sql:execute(
    $conn, "create table all_attribs (
       raw_id integer, attribute_name string, harmonized_name string, value string 
    )"
  )
)
