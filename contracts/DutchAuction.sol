pragma solidity ^0.4.10;

import "./Receiver.sol";

/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);  
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


/// @title Dutch auction contract - distribution of Gnosis tokens using an auction.
/// @author Stefan George - <stefan.george@consensys.net>
contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);
    event AuctionEnded(uint auctionTime, uint moneyRaised, uint tokensSold, uint finalPrice);

    /*
     *  Constants
     */
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    Token public radusToken;
    address public wallet; //This is the wallet that will contain all the tokens to be distributed
    address public owner;
    uint public ceiling; //This is our money cap
    uint public priceFactor;
    uint public startBlock;
    uint public startTime;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    uint public MAX_TOKENS_SOLD; // This should be passed in to the constructor
    uint public timeCap;
    bool public hitMoneyCap;
    bool public phase0;


    mapping (address => uint) public bids;
    mapping (address => bool) public white_list;
    Stages public stage;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            throw;
        _;
    }

    modifier isOwner() {
        if (msg.sender != owner)
            // Only owner is allowed to proceed
            throw;
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet)
            // Only wallet is allowed to proceed
            throw;
        _;
    }

    modifier isValidPayload() {
        if (msg.data.length != 4 && msg.data.length != 36)
            throw;
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

    modifier isPhase0() {
        if (phase0) {_;}
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets owner.
    /// @param _wallet Gnosis wallet.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction price factor.
    function DutchAuction(address _wallet, uint _priceFactor, uint _ceiling, uint tokenCap, uint _timeCap, bool phase)
        public
    {
        if (_wallet == address(0) || _ceiling == 0 || _priceFactor == 0) {
            // Arguments are null.
            revert();
        }
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
        MAX_TOKENS_SOLD = tokenCap;
        timeCap = _timeCap;
        phase0 = phase;
    }

    function addInvestor(address investor)
    isPhase0
    isWallet
    atStage(Stages.AuctionDeployed)
    {
        white_list[investor] == true;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _radusToken Gnosis token address.
    function setup(address _radusToken)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        if (_radusToken == 0) {
            // Argument is null.
            revert();
        }
        radusToken = Token(_radusToken);
        // Validate token balance
        if (radusToken.balanceOf(this) < MAX_TOKENS_SOLD) { //MaxTokensSold for this round may be less than or equal to total tokens left
            revert();
        }
        stage = Stages.AuctionSetUp;
    }

    /// @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
        startTime = now;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        // @change Implements timeCap
        if (now - startTime == timeCap) {
            finalizeAuction();
            msg.sender.transfer(msg.value); //refund sender since he tried to buy after time cap ended
            return;
        }
        if (receiver == 0) {
            receiver = msg.sender;
        }
        if (phase0 && !white_list[receiver]) {
            revert();
        }
        amount = msg.value;
        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.

        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived; //don't need this line because we will pass in MAX_TOKENS_SOLD
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived; //ceiling is money_cap
        // Check if we hit the money cap
        if (amount > maxWeiBasedOnTotalReceived) {
            amount = maxWeiBasedOnTotalReceived;
            hitMoneyCap = true;
            receiver.transfer(msg.value - amount);
        }
        // Only invest maximum possible amount.
        // Note: this will check if we passed the token cap
        if (amount > maxWei && !hitMoneyCap) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            receiver.transfer(msg.value - amount);
        }
        // Forward funding to ether wallet
        if (amount == 0 || !wallet.send(amount)) {
            // No amount sent or sending failed
            throw;
        }
        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount) {
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        }
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0) {
            receiver = msg.sender;
        }
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        radusToken.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        endTime = now;
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        AuctionEnded(endTime, totalReceived, soldTokens, finalPrice);
        wallet.transfer(totalReceived);
        // Auction contract transfers all unsold tokens to Gnosis inventory multisig
        radusToken.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
    }
}
