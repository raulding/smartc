pragma solidity ^0.4.18;

contract owned {
    address public owner;
    
    function owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceof;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed _from, uint256 _value);
    
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceof[msg.sender] = totalSupply;
        name = tokenName;
        symbol= tokenSymbol;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceof[_from] >= _value);
        require(balanceof[_to] + _value > balanceof[_to]);
        
        uint preTotalBalances = balanceof[_from] + balanceof[_to];
        balanceof[_from] -= _value;
        balanceof[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        assert(balanceof[_from] + balanceof[_to] == preTotalBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceof[msg.sender] >= _value);
        
        balanceof[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceof[_from] >= _value)；
        require(allowance[_from][msg.sender] >= _value);
        
        balanceof[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        
        return true;
    }
}

contract VVT is owned, TokenERC20 {
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    mapping (address => bool) public frozenAccount;
    
    event frozenFunds(address to, bool frozen);
    
    function VVT(
        uint256 initialSupply, 
        string tokenName, 
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceof[_from] >= _value);
        require(balanceof[_to] + _value >= balanceof[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        
        balanceof[_from] -= _value;
        balanceof[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function mint(address _to, uint256 amount) onlyOwner public {
        require(_to != 0x0);
        
        balanceof[_to] += amount;
        totalSupply += amount;
        emit Transfer(0, this, amount);
        emit Transfer(this, _to, amount);
    }
    
    function freezeAccount(address _to, bool freeze) onlyOwner public {
        frozenAccount[_to] = freeze;
        emit frozenFunds(_to, freeze);
    }
    
    /// @notice Allow user to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require(newSellPrice > 0);
        require(newBuyPrice > 0);
        
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public {
        require(buyPrice > 0);
        
        uint256 amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }
    
    function sell(uint256 amount) public {
        require(sellPrice > 0);
        
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
}