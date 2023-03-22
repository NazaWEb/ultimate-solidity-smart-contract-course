// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Staking is IERC721Receiver, ERC721Holder {

    IERC721 immutable NFTItem;
    using SafeERC20 for IERC20;
    IERC20 immutable token;

    // mapping from address to nft ID that someone is staking to timestamp at when they staked
    mapping(address => mapping(uint256 => uint256)) public stakes;

    constructor(address _token,address _NFTItem) {
        token = IERC20(_token);
        NFTItem = IERC721(_NFTItem);
    }

    event Stake(address indexed owner, uint256 id, uint256 time);
    event UnStake(address indexed owner, uint256 id, uint256 time, uint256 rewardTokens);

    function calculateRate(uint256 _tokenId) private view returns(uint8) {
        uint256 time = stakes[msg.sender][_tokenId];
        if(block.timestamp - time < 1 minutes) {
            return 0;
        } else if(block.timestamp - time <  4 minutes) {
            return 5;
        } else if(block.timestamp - time < 8 minutes) {
            return 10;
        } else {
            return 15;
        }
    }

    function stakeNFT(uint256 _tokenId) public {
        require(NFTItem.ownerOf(_tokenId) == msg.sender,'you dont have enough balance');
        stakes[msg.sender][_tokenId] = block.timestamp;
        NFTItem.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Stake (msg.sender, _tokenId, block.timestamp);
    }

    function calcualteReward(uint256 _tokenId) public view returns (uint256 totalReward) {
        uint256 time = block.timestamp - stakes[msg.sender][_tokenId];
        uint256 reward =  calculateRate(_tokenId) * time  * 10 ** 18/ 1 minutes;
        return reward;
    }

    function unStakeNFT(uint256 _tokenId) public {
        uint256 reward =  calcualteReward(_tokenId);
        delete stakes[msg.sender][_tokenId];
        NFTItem.safeTransferFrom( address(this), msg.sender, _tokenId);

        token.safeTransfer( msg.sender, reward);

        emit UnStake(msg.sender, _tokenId, block.timestamp, reward);
    }

}