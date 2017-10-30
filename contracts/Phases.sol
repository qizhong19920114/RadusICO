pragma solidity ^0.4.0;
import "./DutchAuction.sol";
import "./Receiver.sol";

//This contract implements the functionality of a crowdsale held in phases including managing the movements of funds, the caps at which to stop each phase, refund functionality, etc. etc. Calls the Dutch Exchange countract in each round.

contract Phases{

    //The current phase
    uint phaseNumber;

    //amount of money sent to contract
    uint moneyCap;

    //The time cap at which the current phase ends (units of days)
    uint timeCap = 20 days;

    //The number of tokens in circulation
    uint tokensInCirculation;

    //The total number of tokens
    uint totalTokens = 1000000000;

    uint exchangeRate;

    //The number of tokens that have been sold
    uint soldTokens;

    //The amount of tokens allocated to the team. Determined to be 10% of the overall token supply
    uint teamFunds;

    //Keeps track of the refunds owed to investors in the case that Phase 0 fails
    mapping(address => uint) refunds;

    //Creates a Dutch Auction object which we call during each phase
    DutchAuction de;

    //Address of owner
    address owner;

    //Checks that the auction is in phase 0
    modifier checkForPhase0(){
        require(phaseNumber == 0);
        _;
    }

    //Checks that the auction is past phase 0
    modifier checkForPhaseN(){
        require(phaseNumber > 0);
        _;
    }

    modifier ownerOnly(){
        require(owner == msg.sender);
        _;
    }

    //Constructs the Phases smart contract
    function Phases(uint _phaseNumber, uint _moneyCap, uint _tokenCap){
        phaseNumber = _phaseNumber;
        moneyCap = _moneyCap;
        owner = msg.sender;
    }

    //Set totalTokens after Phase 0
    function setTotal() private checkForPhaseN(){
        totalTokens = 10 * soldTokens;
    }

    //Sets the money cap based on the specific round N and leaves it the same if the money c cap was not hit the previous ruond
    function setMoneyCap() returns (uint cap){
        if (phaseNumber == 0) {
            moneyCap = 10000000 ether;
        }
        if (de.hitMoneyCap()) {
            moneyCap = moneyCap + ((moneyCap / 10) * 3);
        }
        return moneyCap;
    }

    //Implements Phase "N" of the auction
    function generalAuction() checkForPhaseN(){
       de = new DutchAuction(owner, 1194, setMoneyCap(), 1000000000, 20 days, false);
       de.setup(0xda1fe67d1BFA715513777fa7D26B4f45D062B6D6);
       de.startAuction();
       de.claimTokens(owner);
       phaseNumber += 1;
       tokensInCirculation = totalTokens - de.wallet().balance;
       soldTokens = de.wallet().balance;
    }

    //Implements Phase 0 of the auction
    function initiateAuction(uint moneyCap, uint tokenCap, address[] investors) ownerOnly checkForPhase0(){
        de = new DutchAuction(owner, 1194, setMoneyCap(), 1000000000, 20 days, true);
        for (uint i = 0; i < investors.length; i++) {
          de.addInvestor(investors[i]);
        }
        generalAuction();
    }

    //Creates the current exchange rate based on the pricing function and where each specific phase ends
    function createExchangeRate(){
        exchangeRate = de.calcTokenPrice();
    }

    //Sends the 10% of overall token supply allocated for the team to the team. Only called after Phase 1.
    //Returns True if tokens succesfully sent, False otherwise
    function sendFundsToTeam() returns (bool fund) {
        teamFunds = (10*totalTokens)/10;
        if (!msg.sender.send(teamFunds)){
            return false;
        }
        return true;
    }
}
