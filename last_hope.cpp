#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
#include <chrono>
#include "json.hpp"

using json = nlohmann::json;

#define VERTEX_NUMBER 10
#define COMBINATION_NUMBER 1013

int adjacency_matrix[VERTEX_NUMBER][VERTEX_NUMBER];
int combinations_host_array[COMBINATION_NUMBER][VERTEX_NUMBER];

void loadAdjacencyMatrix() {
    
    int adjacency_matrix_temp[VERTEX_NUMBER][VERTEX_NUMBER] = {
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

    std::copy(&adjacency_matrix_temp[0][0], &adjacency_matrix_temp[0][0] + VERTEX_NUMBER * VERTEX_NUMBER, &adjacency_matrix[0][0]);
}

void loadCombinations() {
    std::ifstream file("combinations.json");
    json jsonData;
    file >> jsonData;

    int index = 0;
    for (const auto& item : jsonData) {
        if (index >= COMBINATION_NUMBER) {
            break;
        }

        auto vec = item.get<std::vector<int>>();
        for (size_t i = 0; i < vec.size() && i < VERTEX_NUMBER; ++i) {
            combinations_host_array[index][i] = vec[i];
        }
        ++index;
    }
}

bool isClique(int combination_index) {
    for (int i = 0; i < VERTEX_NUMBER; ++i) {
        if (combinations_host_array[combination_index][i] == -1) {
            break;
        }
        for (int j = 0; j < VERTEX_NUMBER; ++j) {
            if (combinations_host_array[combination_index][j] == -1) {
                break;
            }
            if (combinations_host_array[combination_index][i] == combinations_host_array[combination_index][j]) {
                continue;
            }
            if (adjacency_matrix[combinations_host_array[combination_index][i]][combinations_host_array[combination_index][j]] != 1) {
                return false;
            }
        }
    }
    return true;
}

int main() {
    loadAdjacencyMatrix();
    loadCombinations();

    auto start = std::chrono::steady_clock::now();

    int result_array[COMBINATION_NUMBER] = {0};
    for (int c = 0; c < COMBINATION_NUMBER; ++c) {
        if (isClique(c)) {
            result_array[c] = 1;
        }
    }

    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    std::cout << "Time elapsed: " << duration.count() << " nanoseconds" << std::endl;

    std::cout << "RESULT: \n";
    for (int i = 0; i < COMBINATION_NUMBER; ++i) {
        if (result_array[i] == 1) {
            for (int j = 0; j < VERTEX_NUMBER; ++j) {
                std::cout << combinations_host_array[i][j] << " ";
            }
            std::cout << std::endl;
        }
    }
    std::cout << std::endl;

    return 0;
}
