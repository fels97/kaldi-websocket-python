ATLASLIBS = /usr/lib/libatlas.so.3 /usr/lib/libf77blas.so.3 /usr/lib/libcblas.so.3 /usr/lib/liblapack_atlas.so.3
#ATLASLIBS = /usr/lib/x86_64-linux-gnu/libatlas.so.3 /usr/lib/x86_64-linux-gnu/libf77blas.so.3 /usr/lib/x86_64-linux-gnu/libcblas.so.3 /usr/lib/x86_64-linux-gnu/liblapack_atlas.so.3 -Wl,-rpath=/usr/lib/x86_64-linux-gnu
KALDI_ROOT=$(HOME)/ec/kaldi
CXX := g++

KALDI_FLAGS := -DKALDI_DOUBLEPRECISION=0 -DHAVE_POSIX_MEMALIGN \
-Wno-sign-compare -Wno-unused-local-typedefs -Winit-self \
-DHAVE_EXECINFO_H=1 -rdynamic -DHAVE_CXXABI_H -DHAVE_ATLAS \
-I$(KALDI_ROOT)/tools/ATLAS/include \
-I$(KALDI_ROOT)/tools/openfst/include -I$(KALDI_ROOT)/src 

CXXFLAGS := -std=c++11 -O3 -mfma -mavx -g -Wall -DPIC -fPIC $(KALDI_FLAGS) -DFST_NO_DYNAMIC_LINKING

KALDI_LIBS = \
	-rdynamic -Wl,-rpath=$(KALDI_ROOT)/tools/openfst/lib \
	$(KALDI_ROOT)/src/online2/kaldi-online2.a \
	$(KALDI_ROOT)/src/decoder/kaldi-decoder.a \
	$(KALDI_ROOT)/src/ivector/kaldi-ivector.a \
	$(KALDI_ROOT)/src/gmm/kaldi-gmm.a \
	$(KALDI_ROOT)/src/nnet3/kaldi-nnet3.a \
	$(KALDI_ROOT)/src/tree/kaldi-tree.a \
	$(KALDI_ROOT)/src/feat/kaldi-feat.a \
	$(KALDI_ROOT)/src/lat/kaldi-lat.a \
	$(KALDI_ROOT)/src/hmm/kaldi-hmm.a \
	$(KALDI_ROOT)/src/transform/kaldi-transform.a \
	$(KALDI_ROOT)/src/cudamatrix/kaldi-cudamatrix.a \
	$(KALDI_ROOT)/src/matrix/kaldi-matrix.a \
	$(KALDI_ROOT)/src/fstext/kaldi-fstext.a \
	$(KALDI_ROOT)/src/util/kaldi-util.a \
	$(KALDI_ROOT)/src/base/kaldi-base.a \
	$(KALDI_ROOT)/tools/openfst/lib/libfst.a \
	$(KALDI_ROOT)/tools/openfst/lib/libfstngram.a \
	$(ATLASLIBS) \
	-lm -lpthread

all: libkaldiwrap.so

libkaldiwrap.so: kaldi_wrap.cc kaldi_recognizer.cc model.cc
	$(CXX) -fpermissive $(CXXFLAGS) -shared -o $@ kaldi_recognizer.cc model.cc kaldi_wrap.cc $(KALDI_LIBS)

kaldi_wrap.cc: kaldi_recognizer.i
	swig -csharp -dllimport "libkaldiwrap.so" \
	    -namespace "Kaldi" -c++ -outdir gen -o kaldi_wrap.cc kaldi_recognizer.i

clean:
	$(RM) *.so kaldi_recognizer_wrap.cc *.o gen/*.cs

