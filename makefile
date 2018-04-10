all: nodeIterator edgeIteratorV1 edgeIteratorV2 edgeIteratorV3 sqrtDecompn edgeIteratorCuda mpiEdgeIteratorForwardArray

nodeIterator: nodeIterator.cpp
	g++ nodeIterator.cpp -std=c++11 -o nodeIterator

nodeiteratorCore: nodeIterator_core.cpp
	g++ nodeIterator_core.cpp -std=c++11 -o nodeiteratorCore

edgeIteratorV1: edgeIterator_forward.cpp
	g++ edgeIterator_forward.cpp -std=c++11 -o edgeIteratorV1

edgeIteratorV2: edgeIterator_compactforward.cpp
	g++ edgeIterator_compactforward.cpp -std=c++11 -o edgeIteratorV2

edgeIteratorV3: edgeIteratorForwardArrays.cpp
	g++ edgeIteratorForwardArrays.cpp -std=c++11 -o edgeIteratorV3

edgeIteratorCuda: edgeIterator.cu
	nvcc edgeIterator.cu -o edgeIteratorCuda

sqrtDecompn: sqrtDecompn.cpp
	g++ sqrtDecompn.cpp -std=c++11 -o sqrtDecompn

mpiEdgeIteratorForwardArray: mpi_edgeIteratorForwardArray.cpp
	mpicxx mpi_edgeIteratorForwardArray.cpp -o mpiEdgeIteratorForwardArray

clean:
	rm nodeIterator edgeIteratorV1 edgeIteratorV2 edgeIteratorV3 sqrtDecompn edgeIteratorCuda
