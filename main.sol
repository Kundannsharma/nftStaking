// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// contracts/token/ERC721/

contract NFTStaking is Ownable {
    IERC721 public nftToken;
    IERC20 public rewardToken;

    struct Stake {
        address owner;
        uint256 nftId;
        uint256 amount;
        uint256 startTime;
        uint endTime;
    }

    mapping(address => mapping(uint256 => Stake)) public stakedNFTs;
    mapping(address => uint256[]) public stakerNFTs;
    mapping(address => uint256) public rewards;

    uint256 public rewardRate =10; // Fixed rate of 50 tokens per minute

    constructor(address _nftToken, address _rewardToken) {
        nftToken = IERC721(_nftToken);
        rewardToken = IERC20(_rewardToken);
    }

   function stakeNFT(uint256 nftId, uint256 stakingDuration) external {
    require(nftToken.ownerOf(nftId) == msg.sender, "You don't own this NFT");

    nftToken.transferFrom(msg.sender, address(this), nftId);

    uint256 startTime = block.timestamp;
    uint256 endTime = startTime + stakingDuration;

    stakedNFTs[msg.sender][nftId] = Stake({
        owner: msg.sender,
        nftId: nftId,
        amount: nftId,
        startTime: startTime,
        endTime: endTime  // Store the end time of the staking period
    });
    
    stakerNFTs[msg.sender].push(nftId);
}

    function withdrawNFT(uint256 nftId) external {
        require(stakedNFTs[msg.sender][nftId].amount > 0, "No NFT staked");
        require(nftToken.ownerOf(nftId) == address(this), "NFT not staked here");

        // Use safeTransferFrom to transfer the NFT to the user
        nftToken.safeTransferFrom(address(this), msg.sender, nftId);

        delete stakedNFTs[msg.sender][nftId];

    }

    function claimRewards() external {
        uint256 totalReward = calculateReward(msg.sender);
        require(totalReward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, totalReward);
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 totalReward = 0;
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i < stakerNFTs[account].length; i++) {
            uint256 nftId = stakerNFTs[account][i];
            uint256 stakedTime = stakedNFTs[account][nftId].startTime;
            uint256 elapsedTime = currentTime - stakedTime;

            totalReward += (stakedNFTs[account][nftId].amount * elapsedTime * rewardRate) / 1 minutes;
        }

        return totalReward;
    }

    function getTotalRewards(address account) external view returns (uint256) {
    return calculateReward(account);
}

}