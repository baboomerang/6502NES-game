#include <iostream>
#include <fstream>
#include <assert.h>

/*
 * RLE - Run Length Encoding
 * Takes a file and compresses all repeating bytes.
 *
 * Optimal Case:
 *     aaabbbbbccdeeeeeeee
 *     a3b5c2d1e8
 *
 * Works best on files that have long repeating sequences of bytes.
 * If the file does not have enough repeating bytes, it will result in negative compression.
 *
 * Worst Case:
 *     abcdefg
 *     a1b1c1d1e1f1g1
 *
 */

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " file\n";
        return 1;
    }

    // Open the input file from argv[1]
    std::string filename = argv[1];
    std::ifstream input{filename, std::ios_base::binary};
    assert(input.is_open());

    // Open and create an empty output file
    std::ofstream output{filename + ".rle", std::ios_base::binary};
    assert(output.is_open());

    int count = 1;
    char _byte = input.get();
    while (input) {
        if (input.peek() == _byte) {
            input.ignore(1);
            count++;
        } else {
            output.put(count);
            output.put(_byte);
            _byte = input.get();
            count = 1;
        }
    }

    output.close();
    input.close();

    return 0;
}
