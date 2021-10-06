declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";


for $bs in doc(
  'biosample_set'
)/BioSampleSet/BioSample

let $id := data(
  $bs/@id
)

(: 
let $env_package_attrib := data(
  $bs/Attributes/Attribute[@harmonized_name='env_package']
)

where $env_package_attrib != "" and $env_package_attrib != "missing"
:)


(: make [@harmonized_name] optional?
ie allow the huge number of non-harmonized attributes?
or do it on a one-by-one basic in the wide query? :)

for $attribute in distinct-values(
  $bs/Attributes/Attribute[@harmonized_name]/@harmonized_name
)
let $single_value := data(
  $bs/Attributes/Attribute[@harmonized_name=$attribute]
)

(: lower-case? :)

let $value := fn:normalize-space(
  string-join(
    sort(
      distinct-values(
        $single_value
      )
    ),'|||'
  )
)

return 

<csv><record> 
<id>{
  $id
}</id>
<attribute>{
  $attribute
}</attribute>
<value>{
  $value
}</value>
</record></csv>

