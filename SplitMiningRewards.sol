pragma solidity >=0.6.0 <0.7.0;

/// @author 71ae and The Coding Army.
/// @title Split and Distribute Mining Rewards between a costcenter and a beneficiary.
contract SplitMiningRewards
{

    // DATA

    address payable owner;
    mapping(address => bool) delegates;

    address payable costcenter;
    address payable beneficiary;

    // EVENTS

    event PaymentReceived(address from, uint value);
    event DelegationChanged(address from, address delegate, bytes32 txt);
    event PayeeChanged(address from, address payee, bytes32 txt);

    event Log(string message, address a1);
    //event LogSplitting(string s1, uint u1, string s2, uint u2, string s3, uint a3);
    event LogSplitting(uint Donated, uint Sent_to_costcentre, uint Remainder);
    // MODIFIERS

    modifier onlyDelegates()
    {
        require(delegates[msg.sender], "Caller is not an allowed delegate.");
        _;
    }

    // CONSTRUCTOR

    /// Input adresses for costcenter and beneficiary.
    constructor(address payable _beneficiary, address payable _costcenter) public
    {
        owner = msg.sender;
        costcenter = _costcenter;
        beneficiary = _beneficiary;
        delegates[owner] = true;
        //emit writeaddress(address(this)); // CAUSES COMPILE ERROR
    }

    // MAIN CONTRACT FUNCTIONS

    // Receiving pure Ether.
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    uint minimum_donation = 1000000000000000000 wei;  //= 1ETH. a threshhold value of the least amount of rewards to donate (because the transaction costs may not be worth it if the donation is very small)

    function SplitAndPay(uint electricity_cost) external payable
    {
        uint transaction_fee = tx.gasprice * 21000; // calculating the transaction fee by multiplying the gas price with the default gas limit
        uint _balance = address(this).balance; // getting the amount of coin in this account
        uint coin_to_leave_behind = electricity_cost / 10;   // a quantity of coin to be left over after the electricity costs have been paid and the rest of the rewards sent to the beneficiary, just in case e.g. electricity costs or coin conversion turn out more expensive than expected


        require(_balance > transaction_fee, "Essentialy no coin on contract. No transactions made.");   // if there is enough money in the account to send the costcenter the electricity costs
        
        uint donation = 0;  // variable in which to remember the amount of coin donated
        // sending rewards to the beneficiary if enough coin has been mined
        if(_balance > electricity_cost + 2*transaction_fee + coin_to_leave_behind + minimum_donation)    // if there is enough ether on this wallet to cover the electricity costs and transaction fees, and if there would be enough ether left to make a donation to the reward address worthwhile
        {
            donation = _balance - electricity_cost - transaction_fee;   // calculating the value of the donation
            beneficiary.transfer(donation); // sending the donation to the beneficiary address
        }

        _balance = address(this).balance; // getting the amount of coin left in this account
        
        uint sent_electricity_costs = 0;    // variable in which to remember the amount of coin sent to cover electricity costs
        // Sending money to the costcenter to cover the electicity costs:
        if(_balance > electricity_cost + transaction_fee)   // if there is enough money in the account to send the costcenter the electricity costs
            sent_electricity_costs = electricity_cost;
        else // there is not enough money in this wallet to cover all the electricity costs
            sent_electricity_costs = _balance - transaction_fee;   // sending the costcenter all the money in this account
        costcenter.transfer(sent_electricity_costs); // sending the costcenter the money to cover the electricity costs
        
        _balance = address(this).balance; // getting the amount of coin left in this account
        
       // LogSplitting("Donated: ", donation, "Sent to costcenter: ", sent_electricity_costs, "Remaining coin: ", _balance);
       LogSplitting(donation, sent_electricity_costs, _balance);
    }

    // POTENTIALLY, SUPPORTING FUNCTIONS

    // SAFE-GUARD

// CAUSES COMPILER ERROR, PLEASE FIX
    // Make fallback payable to receive funds even when people don't know what they're doing.
    // We're not polite to send them back.
    fallback() external payable { } // for Solidity >= 0.6.0
    //function() external payable { } // for Solidity < 0.6.0

    // Safe-guard: withdraw all remaining balance on the contract address to the owner.
    function withdrawAll() public
    {
        require(msg.sender == owner, "No access if you're not the owner.");
        uint _balance = address(this).balance;
        require (_balance > 21000 wei, "Not enough funds.");
        // TO-DO: emit an event
        owner.transfer(_balance);

    }

    // MAINTENANCE

    // Maintenance: add delegate 'newDelegate'
    function addDelegate(address _newDelegate) public onlyDelegates()
    {
        delegates[_newDelegate] = true;
        emit DelegationChanged(msg.sender, _newDelegate, "added as new delegate.");
    }

    // Maintenance: delete delegate 'removeDelegate'
    function delDelegate(address _removeDelegate) public onlyDelegates()
    {
        // TO-DO: add additional safe-guard here not to delete the last remaining delegate!
        // Within this code, delegates[] is a hash table, which does not allow counting its members.
        // We'll have to think about different options. Otherwise we may lose access to the main functionality.
        // For now: The owner of the contract is always the first delegate, and we'll ensure here that the owner cannot be removed.
        require(_removeDelegate != owner, "Removal of the owner as delegate is not provided.");
        if (delegates[_removeDelegate])
        {
            delegates[_removeDelegate] = false;
            emit DelegationChanged(msg.sender, _removeDelegate, "removed as delegate.");
        }
    }

    // Maintenance: Change costcenter payee address
    function changePayeeCostcenter(address _newCostcenter) public onlyDelegates()
    {
      costcenter = payable(_newCostcenter);
      emit PayeeChanged(msg.sender, _newCostcenter, "changed to costcenter address.");
    }

    // Maintenance: Change beneficiary payee address
    function changePayeeBeneficiary(address payable _newBeneficiary) public onlyDelegates()
    {
        beneficiary = _newBeneficiary;
        emit Log("Beneficiary changed to ", beneficiary);
    }

    // TO-DO: Write some more functions.

}
