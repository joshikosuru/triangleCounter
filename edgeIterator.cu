#include <bits/stdc++.h>
using namespace std;
#include "timer.h"

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>

int n,m,*edg,*degree,*startNode,*endNode;
thrust::host_vector<thrust::pair<int,int> > stEdges;
int md,*dedg,*dstartNode,*dendNode,*dresult;
int threads_per_block = 1024,blocks_per_grid = 16;

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

__global__ void numTri(int m,int * __restrict__ edg,int * __restrict__ startNode,int * __restrict__ endNode,int * result) {
    int t = blockDim.x * blockIdx.x + threadIdx.x,ret = 0;
    int numThreads = gridDim.x * blockDim.x; 
    if(t < m) {
    	int rem = m % numThreads,count = m/numThreads,st,en;
	    if(t < rem) {
	        st = t * (count + 1);
	        en = st + count;
	    }
	    else {
	        st = t*count + rem;
	        en = st + count - 1 ;
	    }
    	for(int i=st;i<=en;i++) {
	    	int u = edg[i],v = edg[m+i];
			int su = startNode[u],eu = endNode[u]; int sv = startNode[v],ev = endNode[v];
			if(su != -1 and sv != -1) {
				while(su <= eu and sv <= ev) {
					int diff = edg[su+m]-edg[sv+m];
					if(diff == 0) {
						su++; sv++; ret++;
					}
					else if(diff > 0) sv++;
					else su++;
				}
			}
	    }
    }
    result[t] = ret;
}

void setupDeviceMemory() {
	int sizeVer = n * sizeof(int),sizeEdg = 2*m * sizeof(int);
	int tem = threads_per_block * blocks_per_grid * sizeof(int);
	gpuErrchk(cudaMalloc(&dedg,sizeEdg));
	gpuErrchk(cudaMalloc(&dstartNode,sizeVer));
	gpuErrchk(cudaMalloc(&dendNode,sizeVer));
	gpuErrchk(cudaMalloc(&dresult,tem));  
   	gpuErrchk(cudaMemcpy(dedg,edg,sizeEdg,cudaMemcpyHostToDevice));
   	gpuErrchk(cudaMemcpy(dstartNode,startNode,sizeVer,cudaMemcpyHostToDevice));
   	gpuErrchk(cudaMemcpy(dendNode,endNode,sizeVer,cudaMemcpyHostToDevice));
}

void freeDeviceMemory() {
	free(edg); free(degree); free(startNode); free(endNode);
	gpuErrchk(cudaFree(dedg)); gpuErrchk(cudaFree(dstartNode)); gpuErrchk(cudaFree(dendNode)); gpuErrchk(cudaFree(dresult));
}

int main() {
	scanf("%d %d",&n,&m);
	int sizeVer = n * sizeof(int),sizeEdg = 2*m * sizeof(int);
	edg = (int *) malloc(sizeEdg);
	degree = (int *) malloc(sizeVer);
	startNode = (int *) malloc(sizeVer);
	endNode = (int *) malloc(sizeVer);
	for(int i=0;i<n;i++) {
		degree[i] = 0; startNode[i] = -1; endNode[i] = -1;
	}
	for(int i = 0 ; i < m ; i++) {
		int node1,node2;
		scanf("%d %d",&node1,&node2);
		stEdges.push_back(make_pair(node1,node2));
		degree[node1]++; degree[node2]++;
	}
	for(int i = 0 ;i < stEdges.size(); i++) {
		if(degree[stEdges[i].first] > degree[stEdges[i].second]) {
			swap(stEdges[i].first,stEdges[i].second);
		}
	}
	thrust::device_vector<thrust::pair<int,int> > dEdg = stEdges;
	thrust::sort(dEdg.begin(),dEdg.end());
	stEdges = dEdg;
	for(int i = 0 ;i < stEdges.size(); i++) {
		edg[i] = stEdges[i].first; edg[i+m] = stEdges[i].second;
		if(startNode[stEdges[i].first] == -1) startNode[stEdges[i].first] = i;
		endNode[stEdges[i].first] = i;
	}
	double start,finish;
	GET_TIME(start);
	setupDeviceMemory();
	numTri<<<blocks_per_grid,threads_per_block>>>(m,dedg,dstartNode,dendNode,dresult);
	cudaDeviceSynchronize();
	thrust::device_ptr<int> dptr(dresult);
	int  result = thrust::reduce(dptr,dptr+(threads_per_block*blocks_per_grid));
	cout << result << "\n";
	GET_TIME(finish);
	cudaDeviceSynchronize();
	freeDeviceMemory();
	printf("Elapsed time = %e seconds\n",finish - start);
}