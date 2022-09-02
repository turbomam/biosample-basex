for $db in db:list()
  let $coll := db:open($db)
  where fn:starts-with($db, "biosample_set_")
  for $bs in $coll/BioSampleSet/BioSample
    return data($bs/@id)