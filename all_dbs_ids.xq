for $db in db:list()
  let $coll := db:open($db)
  for $bs in $coll/BioSampleSet/BioSample
    return data($bs/@id)
