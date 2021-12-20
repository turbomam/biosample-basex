(: declare option output:method "csv";
declare option output:csv "header=yes, separator=tab"; :)

(: for $bs in doc(
  'biosample_set'
)/BioSampleSet/BioSample :)

for $id in doc(
  'biosample_set'
)/BioSampleSet/BioSample/Ids/Id

return

  data(
    $id/@db
  )

(: <csv><record> 
<raw_id>{
  data(
    $id/@db
  )
}</raw_id>

</record></csv> :)