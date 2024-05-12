// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

struct UserCity {
    string[] cityNftUserHaveMint;
}

contract CityNft is ERC721 {
    uint256 private s_cityIndex;
    uint256 private s_tokenCounter;

    //new state
    mapping(uint256 cityIndex => string nftAddress) private s_indexToNft;
    mapping(address user => mapping(string country => string nowPosition)) s_userCountryPosition;
    mapping(address user => mapping(string country => UserCity)) s_userCountryNft;

    event mintOwnNft(uint256 indexed s_tokenCounter);

    constructor() ERC721("CITY NFT", "CITYNFT") {
        s_tokenCounter = 0;
    }

    function mintNft(
        string memory countryName,
        string memory cityName,
        string memory nftAddress
    ) public {
        uint256 tokenCounter = s_tokenCounter;
        _safeMint(msg.sender, tokenCounter);
        s_indexToNft[tokenCounter] = nftAddress;
        s_tokenCounter += 1;

        //更新用户当前位置
        s_userCountryPosition[msg.sender][countryName] = cityName;

        //更新用户在当前国家已拥有的nft
        UserCity storage userCity = s_userCountryNft[msg.sender][countryName];
        //must storage can use push
        userCity.cityNftUserHaveMint.push(cityName);

        // emit相应的事件出去
        emit mintOwnNft(tokenCounter);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://aquamarine-fascinating-grouse-888.mypinata.cloud/ipfs/";
    }

    /**
     *
     * @param tokenId tokenId
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        //通过tokenid 获取到对应IPFS的路径 映射给前端展示
        string memory imageURI = string.concat(
            _baseURI(),
            s_indexToNft[tokenId]
        );

        return
            string(
                abi.encodePacked(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"An NFT is describe View of AllOverTheWorld!", ',
                            '"attributes": ["image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            );
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getUserMintedCity(
        string memory countryName
    ) public view returns (string[] memory cityNftUserHaveMint) {
        UserCity storage userCity = s_userCountryNft[msg.sender][countryName];
        return userCity.cityNftUserHaveMint;
    }

    function getUserPosition(
        string memory countryName
    ) public view returns (string memory positonCity) {
        return s_userCountryPosition[msg.sender][countryName];
    }
}