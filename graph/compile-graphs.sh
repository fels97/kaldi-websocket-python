#!/bin/bash

. path.sh

set -x

export LD_LIBRARY_PATH=$(HOME)/kaldi/tools/openfst-1.6.7/lib/fst/

lang=data/lang_test_red
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
    fstarcsort > ${dir}/CL.fst

#---------------

make-h-transducer \
    --disambig-syms-out=${dir}/h.disambig.int \
    --transition-scale=$tscale \
    ${dir}/ilabels_${N}_${P} \
    ${tree} \
    ${model} > ${dir}/Ha.fst

cat ${dir}/Ha.fst > ${dir}/det.Ha.fst

#---------------

fstarcsort --sort_type=ilabel ${dir}/CL.fst > ${dir}/la.CL.fst

fstarcsort --sort_type=olabel ${dir}/det.Ha.fst | \
     fstcompose - ${dir}/la.CL.fst > ${dir}/det.HaCL.fst

#---------------

fstdeterminizestar --use-log=true ${dir}/det.HaCL.fst | \
    fstrmsymbols ${dir}/h.disambig.int | \
    fstrmepslocal | \
    fstminimizeencoded | \
    fstpushspecial | \
    add-self-loops --self-loop-scale=$loopscale --reorder=true ${model} - | 
    fstarcsort --sort_type=olabel |
    fstconvert --fst_type=const > ${dir}/HCL.fst

#-----------------------------

fstconvert --fst_type=olabel_lookahead --save_relabel_opairs=${dir}/g.irelabel ${dir}/HCL.fst > ${dir}/HCLr.fst
fstrelabel --relabel_ipairs=${dir}/g.irelabel ${lang}/G.fst | \
    fstarcsort --sort_type=ilabel | \
    fstconvert --fst_type=const > ${dir}/Gr.fst

fstcompose ${dir}/HCLr.fst ${dir}/Gr.fst | \
    fstconvert --fst_type=const > ${dir}/HCLrGr.fst
