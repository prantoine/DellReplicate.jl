# The paper
This work is based on the paper "Temperature Shocks and Economic Growth: Evidence from the Last Half Century" published by M. Dell, Benjamin F. Jones and Benjamin A. Olken in 2012. It shows that in countries with higher temperatures, GDP growth is lower than in countries with lower temperatures. This is not true for precipitation. We replicate their results by writing code entirely in `Julia` and find very similar results.

Running this package produces three figures which are locally saved, as well as the main results of the paper (Table 2) which are displayed in the terminal. These results are all available on this website, as well as a description of the different functions of the source code.
# How to run the package

Follow these steps to run the package:
   1) Create an empty directory
   2) From this directory, run
```
git clone https://github.com/prantoine/DellReplicate.jl.git
```
3)  Launch a `Julia REPL`
4)  type `]` followed by `activate .` to start the package environment
5)  Type `instantiate` to download the necessary dependencies
6)  Exit the package mode
7)  Start the module by typing
```
include("src/DellReplicate.jl")
```
Relevant graphs will be saved under the `./assets` directory, and tables printed in the `REPL`. They are also available in the documentation.

# References

Dell, M. and Jones, B. F. and Olken, B. A. (2012) "Temperature Shocks and Economic Growth: Evidence from the Last Half Century", *American Economic Journal: Macroeconomics*, Vol. 4, No. 3, pp. 66-95.

Cameron, A. and Gelbach, J. B. and Miller, D. L. (2011) "Robust inference with multiway clustering", *Journal of Business & Economic Statistics*,  Vol. 29, No. 2, pp. 238-249.

Engler, H. (1997) "The Behavior of the QR-Factorization
Algorithm with Column Pivoting", *Appl. Math. Lett.*, Vol. 10, No. 6, pp. 7-11.