// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {MerkleAirdropErrors, MerkleEvents} from "../interfaces/Errors.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {MerkleProof} from "../libraries/utils/Merkle.sol";

contract MerkleAirdropFacet {
    function initialize(address _tokenAddress, bytes32 _merkleRoot) external {
        LibDiamond.enforceIsContractOwner();
        if (_tokenAddress != address(0)) {
            revert MerkleAirdropErrors.CannotReinitialize();
        }
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.nftTokenAddress = _tokenAddress;
        ds.merkleRoot = _merkleRoot;

        emit MerkleEvents.AirdropInit(msg.sender, _tokenAddress, _merkleRoot);
    }

    // @dev prevents zero address from interacting with the contract
    function sanityCheck(address _user) private pure {
        if (_user == address(0)) {
            revert MerkleAirdropErrors.ZeroAddressDetected();
        }
    }

    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert MerkleAirdropErrors.ZeroValueDetected();
        }
    }

    // @dev prevents users from accessing onlyOwner privileges
    // function onlyOwner() private view {
    //     if (msg.sender != owner) {
    //         revert MerkleAirdropErrors.UnAuthorizedFunctionCall();
    //     }
    // }

    // @dev returns if a user has claimed or not
    function _hasClaimedAirdrop() private view returns (bool) {
        sanityCheck(msg.sender);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.claimedAirdropMap[msg.sender];
    }

    // @dev checks contract token balance
    function getContractBalance() public view returns (uint256) {
        // onlyOwner();
        LibDiamond.enforceIsContractOwner();

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return IERC721(ds.nftTokenAddress).balanceOf(address(this));
    }

    // @user for claiming airdrop
    function claimAirdrop(
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) external {
        sanityCheck(msg.sender);
        if (_hasClaimedAirdrop()) {
            revert MerkleAirdropErrors.HasClaimedRewardsAlready();
        }
        // @dev we hash the encoded byte form of the user address and amount to create a leaf
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId));
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // @dev check if the merkleProof provided is valid or belongs to the merkleRoot
        if (!MerkleProof.verify(_merkleProof, ds.merkleRoot, leaf)) {
            revert MerkleAirdropErrors.InvalidClaim();
        }

        ds.claimedAirdropMap[msg.sender] = true;
        ds.totalClaimed += 1;

        IERC721(ds.nftTokenAddress).mint(msg.sender, _tokenId);

        emit MerkleEvents.AirdropClaimed(msg.sender, _tokenId);
    }

    // @user for the contract owner to update the Merkle root
    // @dev updates the merkle state
    function updateMerkleRoot(bytes32 _merkleRoot) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.merkleRoot = _merkleRoot;
    }

    // @user get current merkle proof
    function getMerkleRoot() external view returns (bytes32) {
        sanityCheck(msg.sender);
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.merkleRoot;
    }
}
