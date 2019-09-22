#!/bin/bash

. path.sh

set -x

export LD_LIBRARY_PATH=/home/shmyrev/kaldi/tools/openfst-1.6.7/lib/fst/

lang=data/lang
dir=out
tscale=1.0
loopscale=1.0
tree=exp/chain/tdnn/tree
N=2
P=1
model=exp/chain/tdnn/final.mdl

#---------------

fstdeterminizestar --use-log=true ${lang}/L_disambig.fst | fstarcsort > ${dir}/det.L.fst

#---------------

fstcomposecontext \
    --context-size=$N --central-position=$P \
    --read-disambig-syms=${lang}/phones/disambig.int \
    --write-disambig-syms=${lang}/disambig_ilabels_${N}_${P}.int \
    ${dir}/ilabels_${N}_${P} ${dir}/det.L.fst | \
    fstarcsort --sort_type=ilabel > ${dir}/CL.fst

#---------------

make-h-transducer \
    --disambig-syms-out=${dir}/h.disambig.int \
    --transition-scale=$tscale \
    ${dir}/ilabels_${N}_${P} \
    ${tree} \
    ${model} | \
    fstarcsort --sort_type=olabel > ${dir}/Ha.fst

fstcompose ${dir}/Ha.fst ${dir}/CL.fst > ${dir}/det.HCLa.fst

#---------------

fstdeterminizestar --use-log=true ${dir}/det.HCLa.fst | \
    fstrmsymbols ${dir}/h.disambig.int | \
    fstrmepslocal --use-log | \
    fstminimizeencoded | \
    fstpushspecial | \
    add-self-loops --self-loop-scale=$loopscale --reorder=true ${model} - |
    fstarcsort --sort_type=olabel > ${dir}/HCL.fst


fstconvert --fst_type=olabel_lookahead --save_relabel_opairs=${dir}/g.irelabel ${dir}/HCL.fst > ${dir}/HCLr.fst

#-----------------------------

convert-vocab.py out/g.irelabel ${lang}/words.txt > out/words.txt
ngramread --OOV_symbol="[unk]" --symbols=out/words.txt --ARPA db/etc/default-small.lm | \
     fstconvert --fst_type=ngram > out/Gr.fst

#-----------------------------

fstcompose ${dir}/HCLr.fst ${dir}/Gr.fst | \
    fstconvert --fst_type=const > ${dir}/HCLG.fst
