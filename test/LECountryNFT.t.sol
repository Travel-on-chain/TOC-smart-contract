// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {LECountryNFT} from "../src/LECountryNFT.sol";
import {LECountryNFTDeployer, LEINFO} from "../script/LECountryNFT.s.sol";

// struct LEINFO {
//     string[] countries;
//     uint16 maxSupply;
// }

contract LECountryNFTTest is Test {
    /* Errors from LECountryNFT.sol */
    error LECountryNFT__InvalidCountry(string country);
    error LECountryNFT__MaximumQuantityReached(
        string country,
        uint16 maxSupply
    );
    error LECountryNFT__OnlyOwnerOrCollateralOwner(address _opeartor);

    event LECountryNFT__NFTMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string indexed countryName,
        uint16 holderRank
    );

    modifier onlyOwnerOperate() {
        vm.startPrank(OWNER);
        _;
        vm.stopPrank();
    }

    modifier maxMintedThen(address to) {
        vm.startPrank(OWNER);
        uint16 maxSupply = leINFO.maxSupply;
        uint16 excessiveAmount = 20;
        string memory nftCountryAddress = leINFO.countries[0];
        for (uint16 i = 0; i < maxSupply; i++) {
            vm.expectEmit(true, true, true, true);
            emit LECountryNFT__NFTMinted(i, to, nftCountryAddress, i + 1);
            leCountryNFT.mintNft(to, nftCountryAddress, nftCountryAddress);
        }
        (uint16 numNFTMinted, uint16 maxSupplySetting) = leCountryNFT
            .getNumCountryNFT(nftCountryAddress);
        assertEq(maxSupply, maxSupplySetting);
        assertEq(maxSupply, numNFTMinted);

        for (uint i = 0; i < excessiveAmount; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    LECountryNFT__MaximumQuantityReached.selector,
                    nftCountryAddress,
                    maxSupply
                )
            );
            leCountryNFT.mintNft(to, nftCountryAddress, nftCountryAddress);
        }
        (numNFTMinted, ) = leCountryNFT.getNumCountryNFT(nftCountryAddress);
        assertEq(maxSupply, numNFTMinted);
        _; // Encapsulated logic implementation
        vm.stopPrank();
    }

    LECountryNFT public leCountryNFT;
    LEINFO public leINFO;

    address public OWNER = vm.addr(6433);
    address public USER = vm.addr(87);

    uint16 private constant DEFUALT_MAX_SUPPLY = 100;
    string[] private DEFUALT_COUNTRIES = [
        "Shanghai",
        "Beijing",
        "Sichuan",
        "Zhejiang"
    ];

    function setUp() external {
        LEINFO memory setting = LEINFO(DEFUALT_COUNTRIES, DEFUALT_MAX_SUPPLY);
        LECountryNFTDeployer deployer = new LECountryNFTDeployer();
        // (leCountryNFT, leINFO) = deployer.run(OWNER);
        (leCountryNFT, leINFO) = deployer.run_with(OWNER, setting);
    }

    function testOwnerCanMint() public {
        vm.prank(OWNER);
        string memory nftCountryAddress = leINFO.countries[0];
        leCountryNFT.mintNft(USER, nftCountryAddress, nftCountryAddress);
        uint256 tokenCounter = leCountryNFT.getTokenCounter();
        assertEq(tokenCounter, 1);
    }

    // expectRevert
    function testOnlyOwnerCanMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                LECountryNFT__OnlyOwnerOrCollateralOwner.selector,
                USER
            )
        );
        vm.prank(USER);
        string memory nftCountryAddress = leINFO.countries[0];
        leCountryNFT.mintNft(USER, nftCountryAddress, nftCountryAddress);
        for (uint i = 1; i < 10; i++) {
            address tester = vm.addr(i);
            vm.expectRevert(
                abi.encodeWithSelector(
                    LECountryNFT__OnlyOwnerOrCollateralOwner.selector,
                    tester
                )
            );
            vm.prank(tester);
            leCountryNFT.mintNft(tester, nftCountryAddress, nftCountryAddress);
        }
    }

    // expectEmit
    function testOwnerCanMintOneCityInMutipleTimes() public onlyOwnerOperate {
        uint16 numsOfNFT = leINFO.maxSupply;
        string memory nftCountryAddress = leINFO.countries[0];
        for (uint16 i = 0; i < numsOfNFT; i++) {
            // Ensure the mint event is emitted and data is correct
            vm.expectEmit(true, true, true, true);
            emit LECountryNFT__NFTMinted(i, USER, nftCountryAddress, i + 1);
            leCountryNFT.mintNft(USER, nftCountryAddress, nftCountryAddress);
        }
        uint256 tokenCounter = leCountryNFT.getTokenCounter();
        assertEq(numsOfNFT, tokenCounter);

        uint256 NFT_USER_holds = leCountryNFT.balanceOf(USER);
        assertEq(numsOfNFT, NFT_USER_holds);

        (uint16 numOfNFTActualRecorded, uint16 maxSupply) = leCountryNFT
            .getNumCountryNFT(nftCountryAddress);
        assertTrue(maxSupply >= numOfNFTActualRecorded);
        assertEq(numsOfNFT, numOfNFTActualRecorded);
    }

    // expectEmit, expectRevert
    // its the source of modifier maxMintedThen
    function testLimitedMint() public onlyOwnerOperate {
        uint16 maxSupply = leINFO.maxSupply;
        uint16 excessiveAmount = 20;
        string memory nftCountryAddress = leINFO.countries[0];

        // mint
        for (uint16 i = 0; i < maxSupply; i++) {
            vm.expectEmit(true, true, true, true);
            emit LECountryNFT__NFTMinted(i, USER, nftCountryAddress, i + 1);
            leCountryNFT.mintNft(USER, nftCountryAddress, nftCountryAddress);
        }
        (uint16 numNFTMinted, uint16 maxSupplySetting) = leCountryNFT
            .getNumCountryNFT(nftCountryAddress);
        assertEq(maxSupply, maxSupplySetting);
        assertEq(maxSupply, numNFTMinted);

        // cannot mint due to insufficient mint quantity
        for (uint i = 0; i < excessiveAmount; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    LECountryNFT__MaximumQuantityReached.selector,
                    nftCountryAddress,
                    maxSupply
                )
            );
            leCountryNFT.mintNft(USER, nftCountryAddress, nftCountryAddress);
        }
        (numNFTMinted, ) = leCountryNFT.getNumCountryNFT(nftCountryAddress);
        assertEq(maxSupply, numNFTMinted);
    }

    // Need to update.
    string[] private countriesNeedModify;

    function concatListToString(
        string[] memory _list
    ) private pure returns (string memory result) {
        bytes memory _result = bytes("");
        for (uint i = 0; i < _list.length; i++) {
            _result = abi.encodePacked(_result, ",", _list[i]);
        }
        return string(_result);
    }

    function testMAXMintedThenIncreaseLimition() public maxMintedThen(USER) {
        // clear the countriesNeedModify and then add countries
        delete countriesNeedModify;
        string memory countryName = "Shanghai";
        countriesNeedModify.push(countryName);
        console.log(concatListToString(countriesNeedModify)); // log the actual content of countriesNeedModify

        // set new MAXSupply
        uint16 newAddedQuantity = 20;
        leCountryNFT.setCountriesMaxSupply(
            countriesNeedModify,
            leINFO.maxSupply + newAddedQuantity
        );

        // mint
        for (uint16 i = 0; i < newAddedQuantity - 2; i++) {
            vm.expectEmit(true, true, true, true);
            emit LECountryNFT__NFTMinted(
                leINFO.maxSupply + i,
                USER,
                countryName,
                leINFO.maxSupply + i + 1
            );
            leCountryNFT.mintNft(USER, countryName, countryName);
        }
        (uint16 numNFTMinted, uint16 maxSupplySetting) = leCountryNFT
            .getNumCountryNFT(countryName);
        assertEq(leINFO.maxSupply + newAddedQuantity, maxSupplySetting);
        assertEq(leINFO.maxSupply + newAddedQuantity - 2, numNFTMinted);
    }
}
