NVCC = nvcc
MGPU_PATH = ../../moderngpu2
GEN_PATH = ../../MPI/generator
NVCC_OPTS = -O3 -lineinfo -Xcompiler -fopenmp -I. -I../../ -I$(MGPU_PATH)/include -L/usr/lib/ -L$(MGPU_PATH) -L$(GEN_PATH)
LD_OPTIONS = -L/usr/lib/ -L$(MGPU_PATH) -L$(GEN_PATH)
#NVCC_OPTS = -G -g -Xptxas -v -Xcompiler -fopenmp  -I. -I../../
#NVCC_ARCHS = -gencode=arch=compute_20,code=sm_20
#NVCC_ARCHS = -gencode arch=compute_35,code=sm_35
MPI_PATH = /gruntdata/app_data/zhisong.fzs/openmpi-1.8.5rc3-build
LD_LIBS = -lgomp -lmgpu -lstdc++ -lgen 

GEN_SM35 = -gencode=arch=compute_35,code=\"sm_35,compute_35\" 
GEN_SM30 = -gencode=arch=compute_30,code=\"sm_30,compute_30\" 
GEN_SM20 = -gencode=arch=compute_20,code=\"sm_20,compute_20\" 
GEN_SM13 = -gencode=arch=compute_13,code=\"sm_13,compute_13\" 
GEN_SM10 = -gencode=arch=compute_10,code=\"sm_10,compute_10\" 
SM_TARGETS = $(GEN_SM20) $(GEN_SM30) $(GEN_SM35) 

# Uncomment if you have	gcc 4.5	and would like to use its improved random number facility.
#RAND_OPTS=--compiler-options "-std=c++0x"

all: config.o BFS csv2mtx csv2mtx2
	
config.o: config.cpp ../../getvalue.h config.h Makefile register.h
	nvcc -c -o $@ $< $(NVCC_OPTS) $(SM_TARGETS) $(RAND_OPTS)

BFS.o: bfs.cu bfs.h ../../GASengine/enactor_vertex_centric.cuh ../../MPI/wave.h
	nvcc --compiler-bindir $(MPI_PATH)/bin/mpicc -c -o $@ $< $(NVCC_OPTS) $(SM_TARGETS) $(RAND_OPTS)

BFS: BFS.o config.o
	nvcc --compiler-bindir $(MPI_PATH)/bin/mpicc -o $@ $^ $(LD_OPTIONS) $(LD_LIBS)

csv2mtx.o: csv2mtx.cu ../../GASengine/csv_graph_reader.cuh 
	nvcc -c -o $@ $< $(NVCC_OPTS) $(SM_TARGETS) $(RAND_OPTS)
	
csv2mtx: csv2mtx.o
	nvcc -o $@ $^
	
csv2mtx2.o: csv2mtx2.cu ../../GASengine/csv_graph_reader.cuh 
	nvcc -c -o $@ $< $(NVCC_OPTS) $(SM_TARGETS) $(RAND_OPTS)
	
csv2mtx2: csv2mtx2.o
	nvcc -o $@ $^
	
clean:
	rm -f BFS csv2mtx csv2mtx2 *.o

