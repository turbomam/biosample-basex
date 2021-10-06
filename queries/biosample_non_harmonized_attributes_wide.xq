declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

let $delim := "|||"

for $element in doc(
  'biosample_set'
)/BioSampleSet/BioSample

let $sraid :=  fn:normalize-space(
  string-join(
    data(
      $element/Ids/Id[@db="SRA"]
    ),"|||"
  )
)

let $accession :=  fn:normalize-space(
  string-join(
    data(
      $element/@accession
    ),"|||"
  )
)

let $biosample_id := fn:normalize-space(
  string-join(
    data(
      $element/@id
    ),"|||"
  )
)
let $dna_source := fn:normalize-space(
  string-join(
    data(
      $element/Links/Link[@type="url" and @label="DNA Source"]
    ),"|||"
  )
)
let $doi := fn:normalize-space(
  string-join(
    data(
      $element/Links/Link[@label="DOI"]
    ),"|||"
  )
)

let $entrez_link := $element/Links/Link[@type="entrez"]

let $entrez_links := fn:normalize-space(
  string-join(
    $entrez_link/concat(
      @target,':',@label,":",.
    ),$delim
  )
)

let $model_cat := fn:normalize-space(
  string-join(
    data(
      $element/Models/Model
    ),"|||"
  )
)
let $package := fn:normalize-space(
  string-join(
    data(
      $element/Package
    ),"|||"
  )
)
let $package_display_name := fn:normalize-space(
  string-join(
    data(
      $element/Package/@display_name
    ),"|||"
  )
)
let $paragraph_cat := fn:normalize-space(
  string-join(
    data(
      $element/Description/Comment/Paragraph
    ),"|||"
  )
)

let $primary_id_data := fn:normalize-space(
  string-join(
    data(
      $element/Ids/Id[@is_primary="1"]
    ),"|||"
  )
)

let $status := fn:normalize-space(
  string-join(
    data(
      $element/Status/@status
    ),"|||"
  )
)
let $taxonomy_id := fn:normalize-space(
  string-join(
    data(
      $element/Description/Organism/@taxonomy_id
    ),"|||"
  )
)
let $taxonomy_name := fn:normalize-space(
  string-join(
    data(
      $element/Description/Organism/@taxonomy_name
    ),"|||"
  )
)
let $title := fn:normalize-space(
  string-join(
    data(
      $element/Description/Title
    ),"|||"
  )
)
let $when := fn:normalize-space(
  string-join(
    data(
      $element/Status/@when
    ),"|||"
  )
)

let $emp500_principal_investigator := fn:normalize-space(
  string-join(
    data(
      $element/Attributes/Attribute[@attribute_name='emp500_principal_investigator']
    ),"|||"
  )
)

let $emp500_study_id := fn:normalize-space(
  string-join(
    data(
      $element/Attributes/Attribute[@attribute_name='emp500_study_id']
    ),"|||"
  )
)

let $emp500_title := fn:normalize-space(
  string-join(
    data(
      $element/Attributes/Attribute[@attribute_name='emp500_title']
    ),"|||"
  )
)

return

<result><csv>

<accession>{
  $accession
}
</accession>


<SRA_id>{
  $sraid
}</SRA_id>

<id>{
  $biosample_id
}
</id>
<primary_id>{
  $primary_id_data
}</primary_id>

 <dna_source>{
  $dna_source
}</dna_source>
<doi>{
  $doi
}</doi>

<entrez_links>
{
  $entrez_links
}
</entrez_links>

<model>{
  $model_cat
}</model>

<package>{
  $package
}</package>
<package_name>{
  $package_display_name
}</package_name>

<status>{
  $status
}</status>

<title>{
  $title
}</title>


<status_date>{
  $when
}</status_date>

<taxonomy_id>{
  $taxonomy_id
}</taxonomy_id>
<taxonomy_name>{
  $taxonomy_name
}</taxonomy_name>

<paragraph>{
  $paragraph_cat
}</paragraph>

<emp500_principal_investigator>
{$emp500_principal_investigator}
</emp500_principal_investigator>

<emp500_study_id>
{$emp500_study_id}
</emp500_study_id>

<emp500_title>
{$emp500_title}
</emp500_title>



</csv></result>

