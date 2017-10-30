pragma solidity ^0.4.8;

import "./Receiver.sol";
//import "./ERC223.sol";

 /**
 * Modified ERC223 token to fit with our crowdsale model. Main difference is that tokenSupply is not immediately set
 * Shamelessly stolen from ERC23 token example by Dexaran
 *
 * https://github.com/Dexaran/ERC23-tokens
 */


 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) {revert();}
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) {revert();}
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {return 0;}
        if (x > MAX_UINT256 / y) {revert();}
        return x * y;
    }
}

contract RadusToken is SafeMath {

  mapping(address => uint256) balances;

  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  event LogBurn(address indexed burner, uint256 _value);

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  address public Creator;
  address public crowdSale;

  //create these modifiers to make sure unpermissioned addresses cannot call restricted methods
  modifier isCreator() {if(msg.sender == Creator) {_;}}
  modifier isCrowdSale() {if(msg.sender == crowdSale) {_;}} //method can only be called by crowdsale
  modifier isInitialized() {if(initialized) {_;}}

  event TokenSupplySet(uint256 supply);

  bool public initialized = false;


  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

  function RadusToken(string _name, string _symbol, uint8 _decimals, uint256 _tokenSupply) {
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      Creator = msg.sender;
      initialized = true;
      totalSupply = _tokenSupply;
      balances[Creator] = totalSupply;
  }


  function setSupply(uint256 supply) //should only be called by crowdsale contract after R0
  isCrowdSale()
  isInitialized()
  {
      totalSupply = supply;
      TokenSupplySet(supply);
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) returns (bool success) {

    if (isContract(_to)) {
        if (balanceOf(msg.sender) < _value) {revert();}
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        Receiver receiver = Receiver(_to);
        receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    } else {
        return transferToAddress(_to, _value, _data);
    }
}


  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {

    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) returns (bool success) {

    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) {revert();}
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) {revert();}
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Receiver receiver = Receiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}

    //allows for burning of tokens
    function burn(uint256 _value) public {
      require(_value > 0);
      require(_value <= balances[msg.sender]);
      address burner = msg.sender;
      balances[burner] -= _value;
      totalSupply -= _value;
      LogBurn(burner, _value);
    }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
