// SPDX-License-Identifier: Beerware
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MemecoinNFT
 * @dev An NFT collection that requires spending an ERC20 token to mint
 */
contract MemecoinNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    // Token ID counter
    Counters.Counter private _tokenIdCounter;
    
    // Maximum NFTs that can be minted per address
    uint256 public constant MAX_MINTS_PER_ADDRESS = 42;

    // Maximum supply of NFTs
    uint256 public constant MAX_SUPPLY = type(uint256).max - 1;
    
    // Mapping to track mints per address
    mapping(address => uint256) public mintCount;
    
    // Reference to the memecoin contract
    IERC20 public memeCoin;
    
    // Cost in ERC20 token to mint 1 NFT (100 tokens with 18 decimals)
    uint256 public mintCost = 100 * 10**18;
    
    // Collection metadata
    string public description = "A collection of NFTs for which an ERC20 must be spent to mint";
    
    // Events
    event NFTMinted(address indexed minter, uint256 tokenId, uint256 tokenCost);
    event MintCostUpdated(uint256 newCost);
    
    // Background colors for NFTs
    string[] private backgroundColors = [
        "#FFA07A", // Light Salmon
        "#98FB98", // Pale Green
        "#87CEFA", // Light Sky Blue
        "#DDA0DD", // Plum
        "#FFDAB9", // Peach Puff
        "#F08080", // Light Coral
        "#FFA500", // Orange
        "#FF7F50", // Coral
        "#EEE8AA", // Pale Goldenrod
        "#F0E68C", // Khaki
        "#E6E6FA", // Lavender
        "#66CDAA", // Medium Aquamarine
        "#9ACD32", // Yellow Green
        "#00FA9A", // Medium Spring Green
        "#7FFFD4", // Aquamarine
        "#00FFFF", // Aqua / Cyan
        "#AFEEEE", // PaleTurquoise
        "#87CEEB" // Sky Blue
    ];
    
    // Silly faces for NFTs
    string[] private icons = [
        unicode"🙃", 
        unicode"🤨", 
        unicode"🤪", 
        unicode"😗", 
        unicode"🧐", 
        unicode"🤓",
        unicode"😎",
        unicode"😏",
        unicode"😒",
        unicode"😕",
        unicode"🥺",
        unicode"🤔",
        unicode"😑",
        unicode"🤑",
        unicode"😤",
        unicode"😡",
        unicode"🤯",
        unicode"😳",
        unicode"🥶",
        unicode"😶‍🌫️",
        unicode"😱",
        unicode"🫡",
        unicode"🤫",
        unicode"🫠",
        unicode"🤥",
        unicode"😶",
        unicode"🫥",
        unicode"😐",
        unicode"😬",
        unicode"🙄",
        unicode"🥱",
        unicode"🤐",
        unicode"😈",
        unicode"👿",
        unicode"👻",
        unicode"👾",
        unicode"🤖",
        unicode"😼",
        unicode"👊",
        unicode"🤌",
        unicode"🫵"
    ];
    
    // Silly phrases for NFTs
    string[] private phrases = [
        "IBIWISI",
        "TANSTAAFL",
        "Opel Monza 160i GSI 1991",
        "Threadkiller",
        "RAS",
        "Imminent!",
        "tldr",
        "OP",
        "FTFY",
        "IMNSHO",
        "FTW",
        "a/s/l",
        "zOMG",
        "NSFW",
        "NSFL",
        "k",
        "RTFM",
        "Pwnage",
        "IANAL",
        "mxm",
        "tsek",
        "epic fail",
        "Massive"
    ];

    constructor(address _coinAddress) ERC721("Memecoin NFT", "MCNFT") Ownable(msg.sender) {
        // Set the ERC20 token contract address
        memeCoin = IERC20(_coinAddress);
        
        // Start token IDs at 1
        _tokenIdCounter.increment();
    }
    
    /**
     * @dev Anyone can mint NFTs by paying the required amount of ERC20 token
     */
    function mintNFT() external {
        // Check if max supply has been reached
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_SUPPLY, "Max supply reached");
        
        // Check if address has reached max mints
        require(mintCount[msg.sender] < MAX_MINTS_PER_ADDRESS, "Max mints per address reached");
        
        // Transfer tokens from the user to this contract
        bool success = memeCoin.transferFrom(msg.sender, address(this), mintCost);
        require(success, "Token transfer failed");
        
        // Increment mints for this address
        mintCount[msg.sender]++;
        
        // Mint the NFT
        _safeMint(msg.sender, tokenId);
        
        // Generate and set the token URI
        string memory _tokenURI = generateTokenURI(tokenId);
        _setTokenURI(tokenId, _tokenURI);
        
        // Increment the token ID counter
        _tokenIdCounter.increment();
        
        emit NFTMinted(msg.sender, tokenId, mintCost);
    }
    
    /**
     * @dev Allows owner to update the mint cost
     */
    function setMintCost(uint256 _newCost) external onlyOwner {
        mintCost = _newCost;
        emit MintCostUpdated(_newCost);
    }
    
    /**
     * @dev Allows owner to withdraw accumulated tokens
     */
    function withdrawTokens() external onlyOwner {
        uint256 balance = memeCoin.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        
        bool success = memeCoin.transfer(owner(), balance);
        require(success, "Token transfer failed");
    }
    
    /**
     * @dev Generates a random number based on various inputs
     */
    function _random(string memory input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            input,
            block.timestamp,
            block.prevrandao,
            msg.sender
        )));
    }
    
    /**
     * @dev Generates on-chain SVG for the NFT
     */
    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        uint256 randBg = _random(string(abi.encodePacked("BACKGROUND", tokenId.toString())));
        uint256 randFace = _random(string(abi.encodePacked("FACE", tokenId.toString())));
        uint256 randPhrase = _random(string(abi.encodePacked("PHRASE", tokenId.toString())));
        
        // Select random elements for this NFT
        string memory bgColor = backgroundColors[randBg % backgroundColors.length];
        string memory face = icons[randFace % icons.length];
        string memory phrase = phrases[randPhrase % phrases.length];

        string memory signalBars = string(abi.encodePacked(
            '<rect x="10" y="330" width="10" height="20" fill="white" />',
            '<rect x="30" y="310" width="10" height="40" fill="white" />',
            '<rect x="50" y="290" width="10" height="60" fill="white" />',
            '<rect x="70" y="270" width="10" height="80" fill="white" />'
        ));
        
        // Generate SVG
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" viewBox="0 0 350 350">',
            '<rect width="100%" height="100%" fill="', bgColor, '" />',
            signalBars,
            '<text x="175" y="100" font-family="Courier New" font-size="40" text-anchor="middle" fill="black">',
            face,
            '</text>',
            '<text x="175" y="180" font-family="Courier New" font-size="24" text-anchor="middle" fill="black">',
            phrase,
            '</text>',
            '<text x="175" y="260" font-family="Georgia" font-size="16" text-anchor="middle" fill="black">',
            'Token #', tokenId.toString(),
            '</text>',
            '</svg>'
        ));
    }
    
    /**
     * @dev Generates the complete token URI with metadata and SVG
     */
    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory svg = generateSVG(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Meme NFT #', tokenId.toString(), '",',
            '"description": "', description, '",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            '"attributes": [',
            '{"trait_type": "Token ID", "value": "', tokenId.toString(), '"},',
            '{"trait_type": "Mint Cost", "value": "100 Tokens"}',
            ']}'
        ))));
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    
    /**
     * @dev Override functions required by multiple inheritance
     */
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}