# GPU test (macOS)
This app generates two arrays of user-specified amount of floats and multiplies them.
RNG and multiplications are done on the Mac GPU, but the seed for RNG algorithm is generated on CPU using built-in methods.

## Usage
Download the app from the releases tab, unzip and open it holding the *left control* key.

In the app there is a checkbox named *Safe memory*.
Checking it makes the GPU use only 1/4 of the "recommended max memory".
It is recommended to use this option, because usually the OS reports too much memory available.
