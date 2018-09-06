#

source ~/.profile

run='/home/gmallia/CRYSTAL17_cx1/v1/qcry'

FILES="
116.573346  119.713653  122.894958  124.512598  127.054446  128.656314  131.463313  134.309582  137.200672  
118.139505  121.297131  124.510211  125.884132  127.265886  130.054927  132.880152  135.750582           
"

Scriptdir=`pwd`

cd $Scriptdir

for i in ${FILES}; do

cd $Scriptdir

rm -Rf  $i
mkdir $i

cp ${i}.d12 ./${i}

cd ${i}


# Rename all *.out in a folder, to *.d12
for f in *.out; do
mv -- "$f" "${f%.out}.d12"
done

# Given an *.out file, it creates the input file:

# Delete lines from "date" to "input data" in the *.out:
sed -i '/date/,/input data/d' ${i}.d12

# Delete from "Defaulting to ethernet" till the end in the *.out file:
sed -i '/Defaulting to ethernet/,$d' ${i}.d12

# Delete from "PROCESSORS WORKING" till the end in the *.out file:
sed -i '/PROCESSORS WORKING/,$d' ${i}.d12

#Change:
# SCELPHONO
# 4 0 0 
# 0 4 0
# 0 0 4
#by:
# SCELPHONO
# 2 0 0 
# 0 2 0
# 0 0 2
sed -i '/SCELPHONO/ {N;N;N;s/SCELPHONO\n4 0 0\n0 4 0\n0 0 4/SCELPHONO\n2 0 0\n0 2 0\n0 0 2/}' ${i}.d12

# Remove this block:
# MPP
# CMPLXFAC
# 2
sed -i '/MPP/,/2/d' ${i}.d12

# Change:
# SHRINK 1 1
#by:
# SHRINK 3 3
sed -i '/SHRINK/ {N;s/SHRINK\n1 1/SHRINK\n3 3/}' ${i}.d12

# Delete RESTART:
sed -i '/RESTART/d' ${i}.d12

# Change:
# TOLDEE
# 8
#by:
# TOLDEE
# 8
# MPP
# CMPLXFAC
# 2
sed -i '/TOLDEE/ {N;N;s/TOLDEE\n8/TOLDEE\n8\nMPP\nCMPLXFAC\n2/}'  ${i}_T.d12

#Substitute:
# DISPERSI
#by:
# DISPERSI
# RESTART
# PDOS
# 1600 800
# 0
sed -i '/DISPERSI/ {N;s/DISPERSI/DISPERSI\nRESTART\nPDOS\n1600 800\n0/}' ${i}_PDOS.d12

#Substitute:
# DISPERSI
#by:
# DISPERSI
# RESTART
# BANDS
# 2 64
# 5
# 1 0 0   0 0 0
# 0 0 0   1 1 1
# 1 1 1   1 1 0
# 1 1 0   1 0 0
# 1 0 0   1 1 1
sed -i '/DISPERSI/ {N;s/DISPERSI/DISPERSI\nRESTART\nBANDS\n2 64\n5\n1 0 0   0 0 0\n0 0 0   1 1 1\n1 1 1   1 1 0\n1 1 0   1 0 0\n1 0 0   1 1 1/}' ${INPUT}_PD.d12

#Remove this block:
# TEMPERAT 
# 100 10 2000
sed -i '/TEMPERAT/,/100 10 2000/d' ${i}_PDOS.d12

#Remove this block:
# MULTITASK
# 31
sed -i '/MULTITASK/,/31$/d' ${i}.d12

#Remove this block:
# ENDSCF
# 
# ... end of file
sed -i '/^$/,$d'  ${i}.d12

# Extract volumes from a series of *_T.out outputs:
grep  -A2  "LATTICE PARAMETERS  (ANGSTROMS AND DEGREES) - PRIMITIVE CELL" *T.out  |grep -v "LATTICE" |grep -v "VOLUME" | awk '{ print $1,    $8}' | grep -v "\-\-"

# Imagine you are greping a string into files on folders. If the file is not in a folder,
# grep will complain saying there is not cuch file, so that you can see which output
# was not generated. 
# If the output is present but is not a finished run, grep will not prompt any message,
# because he has found the file but not the string.
# The only way of make grep to say something if the string has not been found (but the file yes)
# is by doing:
# This will show up the path of the files:

files="
128.358654
120.643070
"

Scriptdir=`pwd`

for i in ${files}; do

if grep  "Disk usage:" ${i}/${i}.out; then
    echo "Finished!!"
else
    echo "Did not!!"
    cd ${i}
    pwd
    cd ${Scriptdir}

fi

done

# Remove RANGE:
sed -i '/RANGE/d' ./calcite_optimization_bulk_modif_1_optimised_EOS_analysis.d12

# Remove 0.77
sed -i '/0.77/d' ./calcite_optimization_bulk_modif_1_optimised_EOS_analysis.d12

# sed EOS for:
#SCELPHONO
#4 0 0
#0 4 0
#0 0 4
#FREQCALC
#NOINTENS
#NOOPTGEOM
#DISPERSI

newstring="SCELPHONO\n4 0 0\n0 4 0\n0 0 4\nFREQCALC\nNOINTENS\nDISPERSI"
sed -i "s/EOS/$newstring/" calcite_optimization_bulk_modif_1_optimised_EOS_analysis.d12


# Given an imput file, this script splits the input file into 2 output files:
grep -v "#" all_data.dat > all_dat_without_title.dat
f=`basename all_dat_without_title.dat .dat`
split -d -a2 -l2 --additional-suffix=.dat  ${f}.dat ${f}_
#   -d, --numeric-suffixes  use numeric suffixes instead of alphabetic
#   -a, --suffix-length=N   use suffixes of length N (default 2)
#       If the parent file will produce 10 files, then -a2
#       If the parent file will produce 100 files, then -a3
#   --additional-suffix=SUFFIX  append an additional SUFFIX to file names.


$run ${i} 64 72:00
sed -i s/select=3:ncpus=24/select=4:ncpus=24/ ${i}.qsub
qsub -q pqnmh ${i}.qsub
cd $Scriptdir

done

# In order to copy temporary files before run finishes:
###################################################
hostname="r2i0n6"
tmp="/scratch2/pbs.115582.cx2/120.417178_3253"

echo "scp dcarrasc@${hostname}:${tmp}/${i}"


at 19:34 <<EOF
scp dcarrasc@${hostname}:${tmp}/SCFOUT.LOG .
scp dcarrasc@${hostname}:${tmp}/fort.13 .
scp dcarrasc@${hostname}:${tmp}/fort.9 .
scp dcarrasc@${hostname}:${tmp}/fort.20 .
scp dcarrasc@${hostname}:${tmp}/FREQINFO.DAT .
EOF
################################################

# I dont manage for this option to work:
FILES="
SCFOUT.LOG
fort.13
fort.9
fort.20
FREQINFO.DAT
"
hostname="r2i0n6"
tmp="/scratch2/pbs.115582.cx2/120.417178_3253"

echo "scp dcarrasc@${hostname}:${tmp}/${i}"
#exit

for i in ${FILES}; do
`scp dcarrasc@${hostname}:${tmp}/${i} .` | at 19:18
done

