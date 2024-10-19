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
                facetAddress: address(erc721F),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ERC721Facet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(merkleF),
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

        vm.stopPrank();
        vm.startPrank(to);
        // Test transferring an NFT
        ERC721Facet(address(diamond)).approve(address(this), 1);

        ERC721Facet(address(diamond)).transferFrom(to, address(0x1), 1);

        assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x1));
        assertEq(ERC721Facet(address(diamond)).balanceOf(to), 0);
        assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x1)), 1);
    }

    // function test_Merkle() public{
    //     // Initialize Merkle Airdrop Facet
    // bytes32 merkleRoot = 0xabc; // Replace with an actual Merkle root
    // MerkleAirdropFacet(address(diamond)).initialize(address(erc721F), merkleRoot);

    // vm.stopPrank();
    
    // // Step 1: Valid Claim Test
    // vm.startPrank(address(0x246));  // Set user address
    // bytes32; // Merkle proof for this user, replace with valid proof
    // validProof[0] = 0x123; // Replace with actual proof part
    // validProof[1] = 0x1234; // Replace with actual proof part

    // // Claim an airdrop for token ID 1
    // MerkleAirdropFacet(address(diamond)).claimAirdrop(1, validProof);

    // // Check if the NFT was minted to the user
    // assertEq(ERC721Facet(address(diamond)).ownerOf(1), address(0x246));
    // assertEq(ERC721Facet(address(diamond)).balanceOf(address(0x246)), 1);

    // // Step 2: Double Claim Test
    // // Try claiming again, it should revert
    // vm.expectRevert(MerkleAirdropErrors.HasClaimedRewardsAlready.selector);
    // MerkleAirdropFacet(address(diamond)).claimAirdrop(1, validProof);

    // vm.stopPrank();

    // // Step 3: Invalid Proof Test
    // vm.startPrank(address(0x789));  // New user
    // bytes32; // Invalid proof
    // invalidProof[0] = 0x123823923;  // Invalid proof part
    // invalidProof[1] = 0x456238238;  // Invalid proof part

    // // Try claiming with invalid proof, it should revert
    // vm.expectRevert(MerkleAirdropErrors.InvalidClaim.selector);
    // MerkleAirdropFacet(address(diamond)).claimAirdrop(2, invalidProof);

    // vm.stopPrank();
    // }
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
