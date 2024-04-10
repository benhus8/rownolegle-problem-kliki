#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
#include <cuda_runtime.h>
#include "json.hpp"
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/copy.h>
#include <chrono>

#define VERTEX_NUMBER 10
#define COMBINATION_NUMBER 1013
#define THREADS_NUMBER 10

using json = nlohmann::json;


__constant__ int const_adjacency_matrix[VERTEX_NUMBER][VERTEX_NUMBER];
__device__ int const_combinations_array[COMBINATION_NUMBER][VERTEX_NUMBER];


    // ADJENCY MATRIX SIZE 
__global__ void myKernel(int threads_number, int combination_number, int vertex_number, int* result_array) {
    int id_x = threadIdx.x;

    for(int c = id_x; c < combination_number; c+=threads_number) {
        bool isClique = true;
        for(int i = 0; i < vertex_number; i++) {
            if(const_combinations_array[c][i] == -1) {
                break;
            }
            for(int j = 0; j < vertex_number; j++) {
                if(const_combinations_array[c][j] == -1) {
                    break;
                }
                if(const_combinations_array[c][i] == const_combinations_array[c][j]) {
                    continue;
                }
                if(const_adjacency_matrix[const_combinations_array[c][i]][const_combinations_array[c][j]] != 1) {
                    isClique = false;
                }
            }
        }
        if(isClique) {
            result_array[c] = 1;
        } else {
            result_array[c] = 0;
        }
    }
    
}

int main() {
    std::ifstream file("combinations.json");
    json jsonData;
    file >> jsonData;

    //                                COMBINATION DATA 

    int combinations_host_array[COMBINATION_NUMBER][VERTEX_NUMBER];
    for (int i = 0; i < COMBINATION_NUMBER; ++i) {
        for (int j = 0; j < VERTEX_NUMBER; ++j) {
            combinations_host_array[i][j] = -1;
        }
    }

    int index = 0;
    for (const auto& item : jsonData) {
        if (index >= COMBINATION_NUMBER) {
            break;
        }
        
        auto vec = item.get<std::vector<int>>();
        for (size_t i = 0; i < vec.size(); ++i) {
            if (i >= VERTEX_NUMBER) {
                break;
            }
            combinations_host_array[index][i] = vec[i];
        }
        ++index;
    }

    //CHANGE VERTEXES SIZE
    int adjacency_matrix[VERTEX_NUMBER][VERTEX_NUMBER] = {
        {0, 1, 0, 0, 1, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    };

    // COPY ALL DATA TO GPU
    cudaMemcpyToSymbol(const_adjacency_matrix, adjacency_matrix, VERTEX_NUMBER * VERTEX_NUMBER * sizeof(int));
    cudaMemcpyToSymbol(const_combinations_array, combinations_host_array, COMBINATION_NUMBER * VERTEX_NUMBER * sizeof(int));

    //RESULT_ARRAY
    int* h_result_array = (int*)malloc(COMBINATION_NUMBER * sizeof(int));
    for (int i = 0; i < COMBINATION_NUMBER; ++i) {
        h_result_array[i] = -1;
    }

    int* d_result_array;
    cudaMalloc(&d_result_array, COMBINATION_NUMBER * sizeof(int));
    cudaMemcpy(d_result_array, h_result_array, COMBINATION_NUMBER * sizeof(int), cudaMemcpyHostToDevice);

    std::cout << "BEFORE: \n";
    auto start = std::chrono::steady_clock::now();
    myKernel<<<1, THREADS_NUMBER>>>(THREADS_NUMBER, COMBINATION_NUMBER, VERTEX_NUMBER, d_result_array);
    auto end = std::chrono::steady_clock::now();;
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);

    std::cout << "Time elapsed: " << duration.count() << " nanoseconds" << std::endl;

    cudaMemcpy(h_result_array, d_result_array, COMBINATION_NUMBER * sizeof(int), cudaMemcpyDeviceToHost);
    std::cout << "RESULT: \n";
    for (int i = 0; i < COMBINATION_NUMBER; ++i) {
        if( h_result_array[i] == 1) {
            for (int j = 0; j < VERTEX_NUMBER; ++j) {
                std::cout << combinations_host_array[i][j] << " ";
            }
            std::cout << std::endl;
        }
    }
    std::cout << std::endl;

    cudaFree(d_result_array);
    free(h_result_array);
    return 0;
}