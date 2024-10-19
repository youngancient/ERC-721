// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/MerkleAirdropFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet erc721F;
    MerkleAirdropFacet merkleF;

    function testDeployDiamond() public {
        address owner = address(0x123);
        vm.startPrank(owner);

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(dCutFacet));   // add owner as owner
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        erc721F = new ERC721Facet();
        merkleF = new MerkleAirdropFacet();
        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("MerkleAirdropFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
        
         // Initialize the ERC721Facet
        ERC721Facet(address(diamond)).initialize("TestToken", "TTK");


        address to = address(0x246);

        // Test minting an NFT
        ERC721Facet(address(diamond)).mint(to, 1);
        assertEq(ERC721Facet(address(diamond)).ownerOf(1), to);
        assertEq(ERC721Facet(address(diamond)).balanceOf(to), 1);

        // Test transferring an NFT
        // ERC721Facet(address(diamond)).transferFrom(address(this), address(0x1), 1);
        // assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x1));
        // assertEq(ERC721Facet(address(diamond)).balanceOf(address(this)), 0);
        // assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 1);
    }

    function test_Fn() public{
        assertEq(2 == 2, 3 == 3);
    }
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
