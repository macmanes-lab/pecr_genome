#!/bin/bash

#SBATCH --partition=macmanes
#SBATCH -J Peromyscus_crinitus.maker
#SBATCH --ntasks=80
#SBATCH --mem 310Gb
#SBATCH --output %x.log
source ~/.bash_profile

module purge
module load anaconda/colsa
source activate maker-3.01.02

species="Peromyscus_crinitus"
genome="pecr10X_v2_HiC_gapclosed.fasta"
PREFIX="Peromyscus_crinitus"
ANNOT_VERSION="v3"
base="$species"__"$genome"_"$ANNOT_VERSION"

cd $SHARE/peromyscus_genomes/"$species"/genome/maker

mpiexec -n 80 $HOME/test/maker/bin/maker \
-fix_nucleotides -base "$base" -quiet \
-genome $SHARE/peromyscus_genomes/"$species"/genome/"$genome" \
/mnt/home/macmaneslab/macmanes/maker_control_files/maker_opts_pero.ctl \
/mnt/home/macmaneslab/macmanes/maker_control_files/maker_bopts.ctl \
/mnt/home/macmaneslab/macmanes/maker_control_files/maker_exe.ctl

fasta_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base"
gff3_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base".gff3 -n
sed -i '/^>/! s/-/N/g' "$base".all.maker.proteins.fasta
lastal -P38 $HOME/transporters/swissprot "$base".all.maker.proteins.fasta -f BlastTab > blast.out
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.proteins.fasta > "$base".functional.proteins.fasta
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.transcripts.fasta > "$base".functional.transcripts.fasta
maker_functional_gff $HOME/transporters/uniprot_sprot.fasta blast.out "$base".gff3 > "$base".functional.gff3
maker_map_ids --prefix "$PREFIX" --justify 6 "$base".gff3 > "$base".genome.all.id.map
map_fasta_ids "$base".genome.all.id.map  "$base".functional.proteins.fasta
map_gff_ids "$base".genome.all.id.map  "$base".functional.gff3
map_fasta_ids "$base".genome.all.id.map  "$base".functional.transcripts.fasta
rm -f blast.out
gzip *functional.gff3 *functional.*.fasta
rm -f *map
rm -f *all.maker.*.fasta
rm -f *gff3
