pragma solidity ^0.4.8;

// @title PowerCoin
contract PowerCoin {

    struct Wallet {
        string name;
        string symbol;
        uint decimals;
        uint balance;
    }

    struct powerAccount {
        address customer;
        bool frozen;
        mapping (uint => Wallet) wattage;
	    mapping (uint => Wallet) carbon;
        mapping (uint => Wallet) usdBalance;
	}

    /******** Mappings ********/
    // An array of all customers
    mapping (address => powerAccount) public accounts;

    // An array of all the frozen accounts.
    mapping (address => bool) public frozenAccount;

    /******** Public Variables *********/
    string public standard = 'Token 0.1';
    //TestNet
    address public owner = 0xf6862A9749346DA65CA2163A485FE2b558E66fB2;

    //Production address public owner =

    string public tokenName = 'PowerCoin';
    uint8 public decimalUnits = 6;
    uint public carbonPrice = 0;
    uint public wattagePrice = 0;

    // Initializes contract with initial supply tokens to the creator of the contract
    function newCustomer(address _to) {
        powerAccount thisAccount = accounts[msg.sender];

        thisAccount.customer = msg.sender;
        thisAccount.frozen = false;

        Wallet wattageWallet = accounts[msg.sender].wattage[0];
        Wallet carbonWallet = accounts[msg.sender].carbon[0];
        Wallet dollarWallet = accounts[msg.sender].usdBalance[0];

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

        //Check to make sure there is wattage to send.
        Wallet txWattage = txAccount.wattage[0];
        Wallet rxWattage = rxAccount.wattage[0];

        if (txWattage.balance < _value) throw;           // Check if the sender has enough

        // Perform the Transaction
        txWattage.balance -= _value;
        rxWattage.balance += _value;

        // Notify the blockchain
        Transfer(msg.sender, _to, _value);

        //Check to make sure there is wattage to send.
        Wallet txCarbon = txAccount.carbon[0];
        Wallet rxCarbon = rxAccount.carbon[0];

        if (txWattage.balance < _value) throw;           // Check if the sender has enough

        // Perform the Transaction
        txWattage.balance -= _value;
        rxWattage.balance += _value;

        // Notify the blockchain
        Transfer(msg.sender, _to, _value);

        // Done
        return true;
    }

    // Make more PowerCoin Wattage
    function mintWattage(address target, uint256 mintedAmount) onlyOwner {
        Wallet wattageWallet = accounts[msg.sender].wattage[0];
        wattageWallet.balance += mintedAmount;

        PowerCoinAlert(block.timestamp, msg.sender, target, mintedAmount, "Minting more Wattage.");
    }

    // Make more Carbon Credits
    function mintCredits(address target, uint256 mintedAmount) onlyOwner {
        Wallet carbonWallet = accounts[msg.sender].carbon[0];
        carbonWallet.balance += mintedAmount;

        PowerCoinAlert(block.timestamp, msg.sender, target, mintedAmount, "Minting more Carbon Credits.");
    }

    // Freeze an inactive or abusive account
    function freezeAccount(address target, bool freeze) onlyOwner {
        powerAccount thisAccount = accounts[msg.sender];
        thisAccount.frozen = freeze;

        FrozenFunds(target, freeze);
    }

    // Set the price of a Megawatt Hour
    function adjustWattagePrice(address _to, uint newPrice) {
        wattagePrice = newPrice;
    }

    // Set the price of a ton of Carbon
    function adjustCarbonPrice(address _to, uint newPrice) {
        carbonPrice = newPrice;
    }

    // Make `_newOwner` the new owner of this contract.
    function changeOwner(address _newOwner) onlyOwner
    {
        owner = _newOwner;
    }

    /******** Modifers ********/
    modifier onlyOwner {
        if (msg.sender != owner) {
            PowerCoinAlert(block.timestamp, msg.sender, owner, 0, "Error: Unauthorized Access Attempted");
        }
        _;
    }

    /******** Events ********/
    event PowerCoinAlert (uint eventTimeStamp,
                            address indexed callingAddress,
                            address indexed meterKey,
                            uint indexed currentCoinValue,
                            string description);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds (address target, bool frozen);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}
