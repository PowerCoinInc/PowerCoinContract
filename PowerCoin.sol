pragma solidity ^0.4.8;

import "./installed_contracts/zeppelin/contracts/SafeMath.sol";
import "./DateTime.sol";

// @title PowerCoin
contract PowerCoin is SafeMath, DateTime{

    struct Wallet {

        string name;
        string symbol;
        uint decimals;
        uint balance;
        uint lastUpdated;
    }

    struct powerAccount {
        address customer;
        bool frozen;
        mapping (uint8 => mapping (uint16 => Wallet) ) wattage;
	    mapping (uint8 => mapping (uint16 => Wallet) ) carbon;
        Wallet usdBalance;
	}

    /******** Mappings ********/
    // An array of all customers
    mapping (address => powerAccount) accounts;

    // An array of all the frozen accounts.
    mapping (address => bool) public frozenAccount;

    /******** Public Variables *********/
    string public standard = 'Token 0.1';
    //TestNet
    address public owner = 0xf6862A9749346DA65CA2163A485FE2b558E66fB2;

    //Production address
    //public owner =

    string public tokenName = 'PowerCoin';
    uint8 public decimalUnits = 6;
    uint public currentCarbonPrice = 0;
    uint public currentWattagePrice = 0;

    uint8 public currentMonth = DateTime.getMonth(block.timestamp); // Current month
    uint16 public currentYear = DateTime.getYear(block.timestamp); // Current year

    // Initializes contract with initial supply tokens to the creator of the contract
    function newCustomer(address _to) {
        powerAccount thisAccount = accounts[_to];

        thisAccount.customer = _to;
        thisAccount.frozen = false;

        Wallet wattageWallet = accounts[_to].wattage[currentMonth][currentYear];
        Wallet carbonWallet = accounts[_to].carbon[currentMonth][currentYear];
        Wallet dollarWallet = accounts[_to].usdBalance;

        // Create the Wattage Token
        wattageWallet.name = 'Wattage';
        wattageWallet.symbol = 'MWh';
        wattageWallet.decimals = decimalUnits;
        wattageWallet.balance = 0;

        // Create the Carbon Offset Token
        carbonWallet.name = 'Carbon Credits';
        carbonWallet.symbol = 'CO2';
        carbonWallet.decimals = decimalUnits;
        carbonWallet.balance = 0;

        // Create the USD balance
        dollarWallet.name = 'USD';
        dollarWallet.symbol = '$';
        dollarWallet.decimals = 2;
        dollarWallet.balance = 0;
    }

    // Send PowerCoin Wattage and Carbon Credits
    function transfer(address _to, uint256 _value) returns (bool success) {
        powerAccount txAccount = accounts[msg.sender];
        powerAccount rxAccount = accounts[_to];

        //Check if either account is frozen
        if (rxAccount.frozen) throw;
        if (txAccount.frozen) throw;

        //Make sure that somet amount is being passed.
        if (_value == 0) throw;

        //Check to make sure there is wattage to send.
        Wallet txWattage = txAccount.wattage[currentMonth][currentYear];
        Wallet rxWattage = rxAccount.wattage[currentMonth][currentYear];

        if (txWattage.balance < _value) throw;           // Check if the sender has enough

        // Perform the Transaction
        txWattage.balance -= _value;
        rxWattage.balance += _value;

        // Notify the blockchain
        Transfer(msg.sender, _to, _value);

        //Check to make sure there is wattage to send.
        Wallet txCarbon = txAccount.carbon[currentMonth][currentYear];
        Wallet rxCarbon = rxAccount.carbon[currentMonth][currentYear];

        if (txCarbon.balance < _value) throw;           // Check if the sender has enough

        // Perform the Transaction
        txCarbon.balance -= _value;
        rxCarbon.balance += _value;

        // Notify the blockchain
        Transfer(msg.sender, _to, _value);

        // Done
        return true;
    }

    // Make more PowerCoin Wattage
    function mintWattage(address target, uint256 mintedAmount) onlyOwner {
        Wallet wattageWallet = accounts[msg.sender].wattage[currentMonth][currentYear];
        wattageWallet.balance += mintedAmount;

        PowerCoinAlert(block.timestamp, msg.sender, mintedAmount, "Minting more Wattage.");
    }

    // Make more Carbon Credits
    function mintCredits(address target, uint256 mintedAmount) onlyOwner {
        Wallet carbonWallet = accounts[msg.sender].carbon[currentMonth][currentYear];
        carbonWallet.balance += mintedAmount;

        PowerCoinAlert(block.timestamp, msg.sender, mintedAmount, "Minting more Carbon Credits.");
    }

    //
    function createWattageBill(address _account, uint8 month, uint year) {
            powerAccount thisAccount = accounts[_account];

            Wallet thisWattage = thisAccount.wattage[currentMonth][currentYear];
            Wallet thisCarbon = thisAccount.carbon[currentMonth][currentYear];

            if (thisWattage.balance >= 0 ) {

                uint billAmount = SafeMath.safeMul(thisWattage.balance, currentWattagePrice);
                thisWattage.balance = thisWattage.balance + billAmount;
                thisWattage.lastUpdated = block.timestamp;

                PowerCoinAlert(block.timestamp, msg.sender,
                    thisWattage.balance, "Alert: Bill created.");
            } else {
                PowerCoinAlert(block.timestamp, msg.sender,
                    thisWattage.balance, "Error: Bill creation");
            }
    }

    function cashoutCarbon() {

    }

    // Freeze an inactive or abusive account
    function freezeAccount(address target, bool freeze) onlyOwner {
        powerAccount thisAccount = accounts[msg.sender];
        thisAccount.frozen = freeze;

        FrozenFunds(block.timestamp, target, freeze);
    }

    // Set the price of a Megawatt Hour
    function adjustWattagePrice(uint newPrice) onlyOwner {
        currentWattagePrice = newPrice;
    }

    // Set the price of a ton of Carbon
    function adjustCarbonPrice(uint newPrice) onlyOwner {
        currentCarbonPrice = newPrice;
    }

    // Make `_newOwner` the new owner of this contract.
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }

    /******** Modifers ********/
    modifier onlyOwner {
        if (msg.sender != owner) {
            PowerCoinAlert(block.timestamp, msg.sender, 0, "Error: Unauthorized Access Attempted");
        }
        _;
    }

    /******** Events ********/
    event PowerCoinAlert (uint eventTimeStamp,
                            address indexed callingAddress,
                            uint indexed currentCoinValue,
                            string description);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds (uint eventTimeStamp, address target, bool frozen);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }

}
