//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/*
            z is return value
            y = 5
            if 5 > 3
                z = 5
                x = 5/2 + 1  => 3


                while(x < z => 3 < 5) 
                    z = x => 3
                    x = (5 / x + x) / 2;
                    
                   x = ( 5 / 3 + 3 ) / 2
                   x = (1 + 3) / 2 => 2 


        */




// This function always returns floor value
// sqrt(165) => 12

// function sqrt(uint256 y) public view returns (uint256 z) {
//     if (y > 3) {
//         z = y; // 64
//         uint256 x = y / 2 + 1; // 33
//         while (x < z) {
//             // 33 < 64, 17 < 33, 10 < 33, 8 < 10, 8 < 8
//             z = x; // 33, 17,10
//             x = (y / x + x) / 2;
//             /* 
//                     (64 / 33 + 33) / 2  => (1 + 33) / 2  => 17 
//                     (64 / 17 + 17) / 2 => (3 + 17) / 2 => 10
//                     (64 / 10 + 10) / 2  => (6 + 10) / 2 => 8 
//                     (64 / 8 + 8) / 2 => (8+8) / 2 => 8
//             */
//             // console.log(x);
//         }
//     } else if (y != 0) {
//         z = 1;
//     }
// }

