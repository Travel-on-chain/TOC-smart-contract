// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract LECountryNFT is ERC721 {
    uint256 private s_tokenCounter;
    mapping(string => uint256) private s_countries;

    constructor() ERC721("Limited Edition Country NFT", "LECTNFT") {}
}
