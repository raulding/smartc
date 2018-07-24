pragma solidity ^0.4.8;

import "./ReleaseableToken.sol";
import "./MintableToken.sol";
import "./BurnableToken.sol";

contract VVCToken is ReleasableToken, MintableToken, BurnableToken {
    
    string public name;
    string public symbol;
    
    uint public decimals = 18;
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address to, bool frozen);
    
    constructor (string _tokenName, string _tokenSymbol, uint _initialSupply, bool _mintable) public {
        
        owner = msg.sender;
        
        name = _tokenName;
        symbol = _tokenSymbol;
        
        totalSupply_ = _initialSupply;
        
        // Create initially all balance
        balances[owner] = totalSupply_;
        
        if(totalSupply_ > 0) {
            emit Minted(owner, totalSupply_);
        }
        
        if(!_mintable) {
            mintingFinished = true;
            require(totalSupply_ != 0); // Cannot create a token without supply and no minting
        }
    }
    
    /**
     * When token is released to be transferable, enforce no new tokens can be created.
     */
    function releaseTokenTransfer() public onlyReleaseAgent {
        mintingFinished = true;
        super.releaseTokenTransfer();
    }
    
    function freezeAccount(address _target, bool freeze) onlyOwner public {
        frozenAccount[_target] = freeze;
        emit FrozenFunds(_target, freeze);
    }
    
    /** Allow user to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth */
    function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyOwner public {
        require(_newSellPrice > 0);
        require(_newBuyPrice > 0);
        
        sellPrice = _newSellPrice;
        buyPrice = _newBuyPrice;
    }
    
    function buy() payable public {
        require(buyPrice > 0);
        
        uint256 amount = msg.value / buyPrice;
        transferFrom(this, msg.sender, amount);
    }
    
    function sell(uint256 _amount) public {
        require(sellPrice > 0);
        
        address myAddress = this;
        require(myAddress.balance >= _amount * sellPrice);
        transferFrom(msg.sender, this, _amount);
        msg.sender.transfer(_amount * sellPrice);
    }
}