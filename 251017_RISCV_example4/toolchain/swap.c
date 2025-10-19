void sort(int *pData, int size);
void swap(int *pA, int *pB);

int main()
{
    int arData[6] = {5, 4, 3, 2, 1};
    sort(arData, 5);

    return 0;
}

void sort(int *pData, int size) {
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (pData[j] > pData[j+1])
                swap(&pData[j], &pData[j+1]);
        }
    }
}

void swap(int *pA, int *pB) {
    int temp;
    temp = *pB;
    *pB = *pA;
    *pA = temp;
}