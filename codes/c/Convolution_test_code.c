#include "regs/cheshire.h"
#include "dif/clint.h"
#include "dif/uart.h"
#include "params.h"
#include "util.h"


// Function to perform convolution
int convolution3x3(int matrixA[3][3], int matrixB[3][3]) {
    int output = 0;

    // Perform element-wise multiplication and summation
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            output += matrixA[i][j] * matrixB[i][j];
        }
    }

    return output;
}


// Function to convert integer to string
void int_to_string(int num, char *str) {
    sprintf(str, "%d", num);  // Using sprintf to convert int to string
}


int main() {

    // Define two 3x3 matrices
    int matrixA[3][3] = {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9}
    };

    int matrixB[3][3] = {
        {9, 8, 7},
        {6, 5, 4},
        {3, 2, 1}
    };

    // Perform convolution and get the result
    int result = convolution3x3(matrixA, matrixB);

    // Convert the result to a string
    char resultStr[12];  // Buffer to hold the result as a string
    int_to_string(result, resultStr);

    // Initialize UART
    uint32_t rtc_freq = *reg32(&__base_regs, CHESHIRE_RTC_FREQ_REG_OFFSET);
    uint64_t reset_freq = clint_get_core_freq(rtc_freq, 2500);
    uart_init(&__base_uart, reset_freq, __BOOT_BAUDRATE);

    // Send the result string via UART
    uart_write_str(&__base_uart, "The result of the convolution is: ", 33);
    uart_write_str(&__base_uart, resultStr, sizeof(resultStr));
    uart_write_str(&__base_uart, "\r\n", 2);
    uart_write_flush(&__base_uart);

    return 0;
}
