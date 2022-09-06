declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

for $db in db:list()
  let $coll := db:open(
  $db
)
  where fn:starts-with(
  $db, "biosample_set_"
)

for $bs in $coll/BioSampleSet/BioSample

let $id := fn:normalize-space(
  string-join(
    data(
      $bs/@id
    ),"|"
  )
)

return

<result><csv>


<id>
{
  $id
}
</id>

</csv></result>

