#include <iostream>
#include <fstream>
#include <assert.h>

/* RLE - Run Length Encoding
 * Takes 1 file and encodes repeating bytes into format
 *          a#b#c#d#e#.....
 *  This program encodes the given file into rle.
 *  Compression is highly variable from negative compression to 90%
 */

int main(int argc, char* argv[]) {
    if (!(argc == 2)) {
        std::cout << "Usage: " << argv[0] << " <file>\n";
        return 1;
    }

    std::string filename = argv[1];
    std::ifstream input{filename, std::ios_base::binary};
    assert(input.is_open());

    std::ofstream output{filename + ".rle", std::ios_base::binary};
    assert(output.is_open());

    int c = 1;
    char byte = input.get();
    while (input) {
        if (byte == input.peek()) {
            input.ignore(1);
            c++;
        } else {
            output.put(byte);
            output.put(c);
            byte = input.get();
            c = 1;
        }
    }

    output.close();
    input.close();
    return 0;
}
