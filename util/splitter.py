import os

import click


@click.command()
@click.option('--input_file_name', required=True, type=click.Path(exists=True),
              help='un-packed NCBI biosample set XML file')
@click.option('--output_dir', required=True, type=click.Path(exists=True),
              help='destination for smaller BioSampleSet XML files')
@click.option('--biosamples_per_file', default=300000, help='Number of biosamples to put in each output file.')
@click.option('--last_biosample', help='Stop after this many biosamples have been written to output files.')
def cli(input_file_name, biosamples_per_file, last_biosample, output_dir):
    """Chunks the NCBI biosample set into smaller but valid BioSampleSet XML files."""
    biosamples_seen = 0
    # expect ~ 30 000 000 biosamples
    # want ~ 10 chunks
    # start with more, smaller chunks
    smallfile = None
    with open(input_file_name) as bigfile:
        for lineno, line in enumerate(bigfile):
            if not smallfile:
                small_filename = os.path.join(output_dir, f"biosample_set_from_{biosamples_seen}.xml")
                smallfile = open(small_filename, "w")
                smallfile.write('<?xml version="1.0" encoding="UTF-8"?>\n')
                smallfile.write('<BioSampleSet>\n')
            offset = biosamples_seen % biosamples_per_file
            # print(
            #     f"{biosamples_seen} complete biosamples have been seen as of line #{lineno}. For chunks of {biosamples_per_file}, the modulo is {offset}. Active output file =  {small_filename}")
            if not (line.startswith("<?xml") or line.startswith("<BioSampleSet>")):
                smallfile.write(line)
            if line.startswith('</BioSample>'):
                biosamples_seen += 1
                if offset == 0 and biosamples_seen > 1:
                    print(
                        f"{biosamples_seen} complete biosamples have been seen as of line #{lineno}. For chunks of {biosamples_per_file}, the modulo is {offset}. Active output file =  {small_filename}")

                    smallfile.write('</BioSampleSet>\n')
                    smallfile.close()
                    if last_biosample and biosamples_seen > last_biosample:
                        print("Emergency break")
                        break
                    small_filename = os.path.join(output_dir, f"biosample_set_from_{biosamples_seen}.xml")
                    smallfile = open(small_filename, "w")
                    smallfile.write('<?xml version="1.0" encoding="UTF-8"?>\n')
                    smallfile.write('<BioSampleSet>\n')
        if smallfile:
            smallfile.close()


if __name__ == '__main__':
    cli()
