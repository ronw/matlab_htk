#~/bin/bash
#
# Trains a speech recognizer using HTK.  Starts from a flat start
# model.  The final HMM can be found in $TMPDIR/hmm/hmmdefs

TRAINFILE=$1 
TRAINFEATFILE=$TRAINFILE
GRAMFILE=$2 
WDLIST=$3 
DICTFILE=$4 
#word level transcripts
TRAINTRANSFILE=$5 
#TRAINEVAL=./train_eval.mlf

PROTO_FILE=$6
# how many mixtures per gaussian?
NMIX=$7
TMPDIR=$8

cd $TMPDIR

# given a bunch of training wav files listed in $TRAINFILE, a grammar in
# $GRAMFILE, a word list file in $WDLIST, a pronunciation dictionary
# $DICTFILE, and a file of word level transcriptions for all of the
# training data $TRAINTRANSFILE, this script (and its associated files)
# will bootstrap and train an HTK recognizer...

# files it depends on:
#   sil.hed 

# outputs:
#   wdnet       - HTK grammar
#   dlog        - dictionary log (check for errors)
#   monophones0 - 


# standard command line options (to get reasonable error reports)
#SOPTS="-A -D -T 1"
#SOPTS="-A -D "
SOPTS=$9

# trap any errors when running an HTK command
function runcmd ()
{
    "$@"
    local ERRORCODE=$?

    if [ $ERRORCODE != 0 ]
        then exit $ERRORCODE
    fi
}

# we do this a lot...
# arg 1 = starting HMM
# arg 2 = ending HMM (number of last HMM to be trained)
# arg 3 = name of file containing transcripts to use
# arg 4 = name of file containing list of symbols (e.g. phones) in transcripts
function trainhmms ()
{
  local x=$1     
  while test $x -le $(($2-1))
    do mkdir hmm$(($x+1))
    #runcmd HERest $SOPTS -I $3 -s statistics -t 250.0 250.0 3000.0  -S $TRAINFILE -H hmm$x/macros -H hmm$x/hmmdefs -M hmm$(($x+1)) $4
    #runcmd HERest $SOPTS -I $3 -t 250.0 250.0 3000.0  -S $TRAINFILE -H hmm$x/macros -H hmm$x/hmmdefs -M hmm$(($x+1)) $4
runcmd HERest $SOPTS -I $3 -t 250.0 250.0 3000.0  -v 1 -S $TRAINFILE -H hmm$x/macros -H hmm$x/hmmdefs -M hmm$(($x+1)) $4
    x=$((x+1))
  done

  HMM=$x    
}

# #global config:
# export HCONFIG="
# SOURCEFORMAT = HTK
# SOURCEKIND = USER
# TARGETFORMAT = HTK
# TARGETKIND = USER"


# 1. make a grammar that HTK understands
if [ -e $GRAMFILE ]
then
  if [ `head -1 $GRAMFILE | cut -d " " -f 1 | cut -d "=" -f 1` == "VERSION" ]
      # the grammar already an SLF file?
      then cp $GRAMFILE wdnet
  else
      runcmd HParse $GRAMFILE wdnet
  fi
fi

# 2. compile an HTK formatted dictionary
runcmd HDMan $SOPTS -m -w $WDLIST -n monophones0 -e . -l dlog dict $DICTFILE

#     add sil to monophones0
cp monophones0 tmp;
echo sil >> tmp;
sort tmp | uniq > monophones0;
rm -f tmp;

# 3. convert word level transcripts to phone level transcripts
echo "EX
IS sil sil
DE sp" > mkphones0.led
# FIXME
echo "EX
DE sp" > mkphones0.led

runcmd HLEd $SOPTS -l '*' -d dict -i phones0.mlf mkphones0.led $TRAINTRANSFILE

# This script doesn't do feature extraction.
## 4. feature extraction from training data:
##HCopy $SOPTS -S $TRAINFEATFILE

# 5. HMM training:
#    a. compute initial 3 state phone HMM - just gets overall
#       mean/variance of all training data
HMM=0
mkdir hmm$HMM
runcmd HCompV $SOPTS -f 0.01 -m -S $TRAINFILE  -M hmm$HMM $PROTO_FILE


VECSIZE=`cat $PROTO_FILE | grep -i MEAN | head -1 | cut -s -d ">" -f 2 | tr -d ' '`


#    b. copy the phone HMM in proto (above) into a new HMM for every
#       phone in monophones0 in hmmdefs.  also create basic macro file
echo "~o" > hmm$HMM/macros
echo "<VecSize> $VECSIZE" >> hmm$HMM/macros
echo "<USER>" >> hmm$HMM/macros
#echo "<MFCC_0_D_A>" >> hmm$HMM/macros
cat hmm$HMM/vFloors >> hmm$HMM/macros

proto=`echo $PROTO_FILE | rev | cut -d "/" -f 1 | rev`
perl -ne "BEGIN {open(FD,\"hmm$HMM/$proto\"); @proto=<FD>; close FD; @proto=@proto[4..\$#proto];}  chop; print \"\~h \\\"\$_\\\"\n@proto\n\";" monophones0 > hmm$HMM/hmmdefs

#    c. do some training rounds (monophones0 should contain sil but not sp)
trainhmms $HMM $((HMM+3)) phones0.mlf monophones0

#5   e. realign the training data, forcing the beginning and end of the
#       utterance to fall into the silence state
echo "silence sil" >> dict
#HVite $SOPTS -l '*' -o SWT -b silence -a -H hmm$HMM/macros -H hmm$HMM/hmmdefs -i aligned.mlf -m -t 250.0 -y lab -I $TRAINTRANSFILE -S $TRAINFILE dict monophones1 
runcmd HVite $SOPTS -l '*' -o SWT -b silence -a -H hmm$HMM/macros -H hmm$HMM/hmmdefs -i aligned.mlf -m -y lab -I $TRAINTRANSFILE -S $TRAINFILE dict monophones0 

trainhmms $HMM $((HMM+3)) aligned.mlf monophones0

#    f. do a sequence of mixture splits (up to $NMIX mixtures per
#       state for every phone
NSTATES=`grep -i NUMSTATES $PROTO_FILE | sed -e 's/[^0-9]*//'`
# The HTK book recommends that we only increment by one or two
# components at a time since it has all sorts of heuristics for
# determining the optimal way to split things
for ((N=2; N <= NMIX-1; N+=2))
  do echo "MU $N {*.state[2-$(($NSTATES-1))].mix}" > mu.hed

  echo Splitting GMMs to $N components...
  
  if test ! -d hmm$(($HMM+1))
      then mkdir hmm$(($HMM+1));
  fi
  runcmd HHEd $SOPTS -H hmm$HMM/macros -H hmm$HMM/hmmdefs -M hmm$(($HMM+1)) mu.hed monophones0
  HMM=$(($HMM+1))

  trainhmms $HMM $((HMM+3)) aligned.mlf monophones0
done

# make sure we get the correct number of mixture components
echo Splitting GMMs to $NMIX components...
echo "MU $((NMIX)) {*.state[2-$(($NSTATES-1))].mix}" > mu.hed
if test ! -d hmm$(($HMM+1))
    then mkdir hmm$(($HMM+1));
fi
runcmd HHEd $SOPTS -H hmm$HMM/macros -H hmm$HMM/hmmdefs -M hmm$(($HMM+1)) mu.hed monophones0
HMM=$(($HMM+1))
trainhmms $HMM $((HMM+3)) aligned.mlf monophones0

# Done!
mv hmm$HMM hmm_final


