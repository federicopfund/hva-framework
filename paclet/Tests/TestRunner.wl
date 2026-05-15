Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "Kernel", "HVA.wl"}]];

testFiles = SortBy[FileNames["*.wlt", DirectoryName[$InputFileName], Infinity], ToLowerCase];

TestReport[testFiles]
