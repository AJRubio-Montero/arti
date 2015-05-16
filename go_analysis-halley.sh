# /************************************************************************/
# /*                                                                      */
# /* Package:  CrkTools                                                   */
# /* Module:   do_analysis-halley.sh                                      */
# /*                                                                      */
# /************************************************************************/
# /* Authors:  Hernán Asorey                                              */
# /* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
# /*                                                                      */
# /************************************************************************/
# /* Comments: This script automates the creation of a new simulation     */
# /*           project in the halley cluster                              */
# /*                                                                      */
# /************************************************************************/
# /* 
#  
# Copyright 2013
# Hernán Asorey
# Lab DPR (CAB-CNEA), Argentina
# Grupo Halley (UIS), Colombia
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
# NO EVENT SHALL LAB DPR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing
# official policies, either expressed or implied, of Lab DPR.
# 
# */
# /************************************************************************/
# 
VERSION="v3r1"; # vie may 15 17:17:15 ART 2015

showhelp() {
  echo 
  echo -e "$0 version $VERSION"
  echo 
  echo -e "USAGE $0:"
  echo
  echo -e "  -b <project base name>  : Project base name (suggested format: nnn)"
  echo -e "  -p <project name>       : Project name, typically nnnxx"
  echo -e "  -t                      : Only transfer files and perform checks"
  echo -e "  -?                      : Shows this help and exit."
  echo
}

bsn="";
prj="";
ana=true;

echo

while getopts ':b:p:t?' opt; do
  case $opt in
    b)
      bsn=$OPTARG
      echo -e "#  Project base name             = $bsn"
      ;;
    p)
      prj=$OPTARG
      echo -e "#  Project name                  = $prj"
      ;;
    t)
      ana=false;
      echo -e "#  Data analysis                 = $ana"
      ;;
    ?)
      showhelp
      exit 1;
      ;;
  esac
done

##################################################
## YOU SHOULD NOT EDIT ANYTHING BELOW THIS LINE ##
##################################################

if [ "X${bsn}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project base name (suggested format: nnn)"
  showhelp
  exit 1;
fi

if [ "X${prj}" == "X" ]; then
  echo; echo -e "#  ERROR: You have to provide a project name (typically format: nnnxx)"
  showhelp
  exit 1;
fi

# asuming you will work where you are
h=$(hostname | awk '{if ($1=="frontend") {print 0} else {print $0}}' | sed -e 's/halley0//')
# and them the final directory will be: 
home=/home/h${h}/${bsn}/flux-${prj}

echo -e "#  STATUS: Working node:               halley0${h}"
echo -e "#  STATUS: Project base name:          ${bsn}"
echo -e "#  STATUS: Project name:               ${prj}"
echo -e "#  STATUS: Work directory:             ${home}"
echo -e "#  STATUS: Data analysis:              ${ana}"
echo; echo -e "#  READY: Press enter to continue, <ctrl-c> to abort!"
read

mkdir ${home}

# transfering files
for i in $(seq 0 6); do
  rsync -aPv h${i}:/home/h${i}/${bsn}/${prj}/DAT??????.bz2  ${home}
  rsync -aPv h${i}:/home/h${i}/${bsn}/${prj}/*.lst* ${home}
done

tst=$(ls -1 ${home}/DAT??????.bz2 | wc -l)

if [ "X${tst}" != "X60" ]; then
    ls -1 ${home}/DAT??????.bz2 | wc -l
  echo "#  ERROR: There are not $tst/60 output files"
  echo "#  ERROR: Please check"
  exit 1
fi
echo -e "#  Test 1: PASS: There are 60 output files"

# Test if all the processes ended correctly
tst=$(bzcat ${home}/*.lst.bz2 | tail -q -n 1 | grep -v "END OF RUN"; done)
if [ "X${tst}" != "X" ]; then
  echo "#  ERROR: Some processes failed:"
  bzcat ${home}/*.lst.bz2 | tail -n 1 | grep -v "END OF RUN"
  echo "#  ERROR: Please check"
  exit 1
fi
echo -e "#  Test 2 PASS: all processes ended normally"

echo; echo -e "#  READY: All test passed. Press enter to continue, <ctrl-c> to abort!"
read

#similar flux separation, using 3 branchs
if [ ! $ana ]; then
  echo -e "#  READY: Files transferred."
  exit 0
fi

cd ${home}
mkdir ${home}/f1
mkdir ${home}/f2
mkdir ${home}/f3

for i in 001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521; do
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 1 4); do
  printf -v n %02d $j
  i=0${j}0402 
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 1 8); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 9 20); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f2
done

for j in $(seq 21 32); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f3
done

# analisys
for k in $(seq 1 3); do
  file=f${k}
  echo "cd ${home}/f${k}
for i in DAT??????.bz2; do
  j=\$(echo \$i | sed -e 's/.bz2//')
  u=\$(echo \$j | sed -e 's/DAT//');
  bzip2 -v -d -k \$i
  echo \$j | lagocrkread | analysis -v \$u
  rm \$j
done
cd ${home}/
rm f${k}.sh" > f${k}.sh
  chmod 744 f${k}.sh
  screen -d -m -a -S flux-${k} ${home}/f${k}.sh 
  screen -ls
done
