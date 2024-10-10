// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";
contract NFT is ERC721URIStorage{
    using Counters for Counters.Counter; 
    Counters.Counter private tokenIds;
    address contractaddr;
    constructor(address marketaddr) ERC721("Karthiks Adda","PKG"){
        contractaddr=marketaddr;
    }
    function createtoken(string memory URI) public {
        tokenIds.increment();
        uint curr=tokenIds.current();
        _mint(msg.sender, curr);
        _setTokenURI(curr, URI);
        setApprovalForAll(contractaddr, true);

    }
    
}
contract NFTmarket is ReentrancyGuard{
  using Counters for Counters.Counter;
  Counters.Counter private itemIds;
  Counters.Counter private sold;
 address payable owner;
 uint listingprice= 1 ether;
 constructor() {
  owner=payable(msg.sender);
 }
  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
  }
  mapping(uint256=>MarketItem) private idtomarketitem;
  event MarketItemCreated (uint indexed itemId,address indexed nftContract,uint256 indexed tokenId,address seller,address owner,uint256 price);
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(price >= 1, "at least 1 eth");
    require(msg.value==listingprice, "not equal to listing price");

    itemIds.increment();
    uint256 itemId = itemIds.current();
  
    idtomarketitem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price
    );
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price
    );
    payable(owner).transfer(listingprice);
  }
    function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
    uint price = idtomarketitem[itemId].price;
    uint tokenId = idtomarketitem[itemId].tokenId;
    require(msg.value == price, "not equal to asking price");

    idtomarketitem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idtomarketitem[itemId].owner = payable(msg.sender);
    sold.increment();
    
  }
    function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = itemIds.current();
    uint unsoldItemCount = itemIds.current() - sold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idtomarketitem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idtomarketitem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idtomarketitem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idtomarketitem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idtomarketitem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }
  }
  
