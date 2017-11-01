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

$run ${i} 64 72:00

sed -i s/select=3:ncpus=24/select=4:ncpus=24/ ${i}.qsub

qsub -q pqnmh ${i}.qsub

cd $Scriptdir

done
