// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract LECountryNFT is ERC721, Ownable {
    error LECountryNFT__InvalidCountry(string country);
    error LECountryNFT__OnlyOwnerOrCollateralOwner(address _opeartor);

    event LECountryNFT__NFTMinted(uint256 indexed tokenCounter, address indexed owner, string indexed countryName);

    uint256 private s_tokenCounter;
    string[] private s_countries;

    mapping(uint256 nftIndex => string nftAddress) private s_indexToNft;
    mapping(string => uint256) private s_maxSupplyCountryNFT;
    mapping(string => uint256) private s_numCountryNFT;
    mapping(address user => string[]) s_userCountriesNft;

    constructor(string[] memory _countries) ERC721("Limited Edition Country NFT", "LECTNFT") Ownable(msg.sender) {
        s_tokenCounter = 0;
        s_countries = _countries;
    }

    function isValidCountry(string memory _countryName) private view returns (bool valid) {
        string[] memory countries = s_countries;
        for (uint256 i = 0; i < s_countries.length; i++) {
            bytes32 countriesHash = keccak256(abi.encodePacked(countries[i]));
            bytes32 countryNameHash = keccak256(abi.encodePacked(_countryName));
            if (countriesHash == countryNameHash) {
                return true;
            }
        }
    }

    // Need to update the following functions:
    function mintNft(string memory _countryName, string memory nftAddress) public OnlyOwnerOrCollaborators {
        if (!isValidCountry(_countryName)) {
            revert LECountryNFT__InvalidCountry(_countryName);
        }

        uint256 tokenCounter = s_tokenCounter;
        s_numCountryNFT[_countryName]++;

        _safeMint(msg.sender, tokenCounter);
        s_indexToNft[tokenCounter] = nftAddress;
        s_tokenCounter++;

        // 更新用户已拥有的国家 NFT
        string[] storage userCountries = s_userCountriesNft[msg.sender];
        userCountries.push(_countryName);

        emit LECountryNFT__NFTMinted(tokenCounter, msg.sender, _countryName);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://aquamarine-fascinating-grouse-888.mypinata.cloud/ipfs/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //通过 tokenid 获取到对应 IPFS 的路径 映射给前端展示
        string memory imageURI = string.concat(_baseURI(), s_indexToNft[tokenId]);
        return string(abi.encodePacked(bytes(imageURI)));
    }

    /* GETTER */
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getUserMintedCountries() public view returns (string[] memory countriesNftUserHave) {
        return s_userCountriesNft[msg.sender];
    }

    function getCountries() public view returns (string[] memory) {
        return s_countries;
    }

    /* SETTER */
    function setCountries(string[] memory _countries) public OnlyOwnerOrCollaborators {
        s_countries = _countries;
    }

    function setCountryMaxSupply(string memory _country, uint256 _maxSupply) public OnlyOwnerOrCollaborators {
        s_maxSupplyCountryNFT[_country] = _maxSupply;
    }

    /* Modifiers */

    // 合作伙伴地址到布尔值的映射，表示是否为合作伙伴
    mapping(address => bool) internal s_collateralOwners;

    modifier OnlyOwnerOrCollaborators() {
        if (msg.sender != owner() && !s_collateralOwners[msg.sender]) {
            revert LECountryNFT__OnlyOwnerOrCollateralOwner(msg.sender);
        }
        _;
    }

    // 允许合约所有者添加合作伙伴
    function addCollaborator(address _collaborator) external onlyOwner {
        s_collateralOwners[_collaborator] = true;
    }

    // 允许合约所有者移除合作伙伴
    function removeCollaborator(address _collaborator) external onlyOwner {
        s_collateralOwners[_collaborator] = false;
    }
}
