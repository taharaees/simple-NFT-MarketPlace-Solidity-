pragma solidity ^0.8.20;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable, IERC721Receiver {
    // Struct to represent a product
    struct Product {
        address owner;
        uint256 price;
        address tokenAddress;
        uint256 tokenId;
        bool isNFT;
    }

    mapping(uint256 => Product) public products;
    uint256 public productIndex;

    event ProductAdded(uint256 indexed productId, address indexed owner, uint256 price, address tokenAddress, uint256 tokenId, bool isNFT);
    event ProductSold(uint256 indexed productId, address indexed buyer, uint256 price);

    constructor() Ownable(msg.sender) {}

    function addProduct(uint256 _price, address _tokenAddress, uint256 _tokenId, bool _isNFT) external {
        products[productIndex] = Product({
            owner: msg.sender,
            price: _price,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            isNFT: _isNFT
        });
        emit ProductAdded(productIndex, msg.sender, _price, _tokenAddress, _tokenId, _isNFT);
        productIndex++;
    }

    function buyProduct(uint256 _productId) external payable {
        Product storage product = products[_productId];
        require(product.owner != address(0), "Product does not exist");
        require(msg.value >= product.price, "Insufficient payment");

        if (product.isNFT) {
            require(msg.sender != product.owner, "You can't buy your own NFT");
            IERC721(product.tokenAddress).safeTransferFrom(address(this), msg.sender, product.tokenId);
        } else {
            IERC20(product.tokenAddress).transferFrom(msg.sender, product.owner, product.price);
        }

        payable(product.owner).transfer(msg.value);
        emit ProductSold(_productId, msg.sender, product.price);
        delete products[_productId];
    }

    function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
