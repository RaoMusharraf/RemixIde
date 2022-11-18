/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
contract EncodeGenerate {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) public pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

    function GetImageUrl( string memory deposited, string memory MaturityTime, string memory Persentage, string memory ERC20ContractAddress, string memory NFTContractAddress, string memory ContractName, string memory ContractSymbol, string memory TotalClaim) public pure returns (string memory) {
        bytes memory svg =   
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500">',
                '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
                '<rect width="100%" height="100%" fill="blue" />',
                '<text x="50%" y="30%" class="base" dominant-baseline="middle" text-anchor="middle">',"My Contract",'</text>',
                '<text x="50%" y="35%" class="base" dominant-baseline="middle" text-anchor="middle">',"This is deposit and withdraw contract",'</text>',
                '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', "Deposited: ",deposited,'</text>',
                '<text x="50%" y="45%" class="base" dominant-baseline="middle" text-anchor="middle">', "Maturity: ",MaturityTime,'</text>',
                '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', "Percentage: ",Persentage,'</text>',
                '<text x="50%" y="55%" class="base" dominant-baseline="middle" text-anchor="middle">', "ERC20ContractAddress: ",ERC20ContractAddress,'</text>',
                '<text x="50%" y="60%" class="base" dominant-baseline="middle" text-anchor="middle">', "NFTContractAddress: ",NFTContractAddress,'</text>',
                '<text x="50%" y="65%" class="base" dominant-baseline="middle" text-anchor="middle">', "ContractName: ",ContractName,'</text>',
                '<text x="50%" y="70%" class="base" dominant-baseline="middle" text-anchor="middle">', "ContractSymbol: ",ContractSymbol,'</text>',
                '<text x="50%" y="75%" class="base" dominant-baseline="middle" text-anchor="middle">', "TotalClaim: ",TotalClaim,'</text>',
                '</svg>');
        return string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    encode(svg)
                )    
            );
    }

    function GetUrl( string memory deposited, string memory MaturityTime, string memory Persentage, string memory ERC20ContractAddress, string memory NFTContractAddress, string memory ContractName, string memory ContractSymbol, string memory TotalClaim, string memory iUrl) public pure returns (string memory) {
                return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked('{"name": "My Contract","image": "',iUrl,'" ,"description": "This is deposit and withdraw contract", "attributes": [{ "trait_type": "deposited","value": "',deposited,'"},{"trait_type": "maturity","value": "',MaturityTime,'"},{"trait_type": "percentage","value": "',Persentage,'"},{ "trait_type": "ERC20ContractAddress","value": "',ERC20ContractAddress,'"},{"trait_type": "NFTContractAddress","value": "',NFTContractAddress,'"},{"trait_type": "ContractName","value": "',ContractName,'"},{ "trait_type": "ContractSymbol","value": "',ContractSymbol,'"},{"trait_type": "TotalClaim","value": "',TotalClaim,'"}]}'
                            )
                        )
                    )
                )
            );
    }
}