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
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

struct UserCity {
    string[] cityNftUserHaveMint;
}

contract CityNft is ERC721, Initializable, UUPSUpgradeable {
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

    // 这里的mint逻辑
    // tokencounter-ipfs地址的映射
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

    function initialize() public initializer {
        //__Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

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
        //pick city
        // if (CityNFTState.BEIJING == city) {
        //     if (s_userCityCount[msg.sender][city] != 0) {
        //         imageURI = s_beijingSvgUri2;
        //         cityLevel = 1;
        //     } else {
        //         imageURI = s_beijingSvgUri1;
        //         cityLevel = 0;
        //     }
        // } else {
        //     if (s_userCityCount[msg.sender][city] != 0) {
        //         imageURI = s_shanghaiSvgUri2;
        //         cityLevel = 1;
        //     } else {
        //         imageURI = s_shanghaiSvgUri1;
        //         cityLevel = 0;
        //     }
        // }

        return string(abi.encodePacked(bytes(imageURI)));
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
