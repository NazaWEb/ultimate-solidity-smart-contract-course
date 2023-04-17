// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Builders is ERC721A, Ownable {
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant maxMintPerUser = 5;
    uint256 public constant maxMintSupply = 100;

    uint256 public constant refundPeriod = 3 minutes;
    uint256 public refundEndTimestamp;

    address public refundAddress;

    mapping(uint256 => uint256) public refundEndTimestamps;
    mapping(uint256 => bool) public hasRefunded;

    constructor() ERC721A("Web3Builders", "WE3") {
        refundAddress = address(this);
        refundEndTimestamp = block.timestamp + refundPeriod;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB/";
    }

    function safeMint(uint256 quantity) public payable {
        require(msg.value >= quantity * mintPrice, "Not enough funds");
        require(_numberMinted(msg.sender) + quantity <= maxMintPerUser, "Mint Limit");
        require(_totalMinted() + quantity <= maxMintSupply, "SOLD OUT");

        _safeMint(msg.sender, quantity);
        refundEndTimestamp = block.timestamp + refundPeriod;
        for(uint256 i = _currentIndex - quantity; i < _currentIndex; i++){
            refundEndTimestamps[i] = refundEndTimestamp;
        }
    }

    function refund(uint256 tokenId) external {
        // you have to be the owner of the NFT
        require(block.timestamp < getRefundDeadline(tokenId), "Refund Period Expired");
        require(msg.sender == ownerOf(tokenId), "Not your NFT");
        uint256 refundAmount = getRefundAmount(tokenId);

        // transfer ownership of NFT
        _transfer(msg.sender, refundAddress, tokenId);

        //mark refunded
        hasRefunded[tokenId] = true;
        // refund the Price
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    function getRefundDeadline(uint256 tokenId) public view returns(uint256) {
        if(hasRefunded[tokenId]) {
            return 0;
        }
        return refundEndTimestamps[tokenId];
    }

    function getRefundAmount(uint256 tokenId) public view returns(uint256) {
        if(hasRefunded[tokenId]) {
            return 0;
        }
        return mintPrice;
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > refundEndTimestamp, "It's not past the refund period");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}