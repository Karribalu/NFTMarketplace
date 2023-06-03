// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import counters contract from openzeppelin
import "@openzeppelin/contracts/utils/Counters.sol";
//import extensions from openzeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    mapping (uint256 => MarketItem) private idMarketItem;
    uint256 listingPrice = 0.025 ether;
    struct MarketItem{
        uint256 itemId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed owner,
        uint256 price,
        bool sold
    );
    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = payable(msg.sender);
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }

    //createa nft token function
    function createToken(string memory _tokenURI, uint256 price) public payable returns(uint256){
         require(price > 0, "Price must be greater than 0");
        // require(_exists(tokenId), "Token does not exist");
        require(msg.value == listingPrice, "Price must be equal to listing price");
         
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
       
        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    function resaleToken(uint256 tokenId, uint256 price) public payable{
        require(idMarketItem[tokenId].owner == msg.sender, "You are not the owner of this token");
        require(price > 0, "Price must be greater than 0");
        require(_exists(tokenId), "Token does not exist");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }
    // Function CreateMarketSale
    function createMarketSale(uint256 tokenId) public payable{
        uint256 price = idMarketItem[tokenId].price;
        // uint256 tokenId = idMarketItem[tokenId].tokenId;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        _transfer(address(this), msg.sender, tokenId);
        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
        payable( idMarketItem[tokenId].seller).transfer(msg.value);
    }
    // Getting unsold NFT Data
    function fetchMarketItem() public view returns(MarketItem[] memory){ 
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0; 
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for(uint256 i = 0; i < itemCount; i++){
            if(idMarketItem[i + 1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }

    //Purchase Item
    function fetchMyNFTs() public view returns(MarketItem[] memory){
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i = 0; i < totalItemCount; i++){
            if(idMarketItem[i + 1].owner == msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i < totalItemCount; i++){
            if(idMarketItem[i + 1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //SINGLE USER ITEMS
    function fetchItemsSold() public view returns(MarketItem[] memory){
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i = 0; i < totalItemCount; i++){
            if(idMarketItem[i + 1].seller == msg.sender){
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i < totalItemCount; i++){
            if(idMarketItem[i + 1].seller == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    
}