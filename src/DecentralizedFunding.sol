//SPDX-License-Identifier: MIT

pragma solidity >0.7.0 <=0.9.0;

contract DecentralizedFunding{
    string public name;
    string public description;
    uint256 public target;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState{Active,Successful,Failed}
    CampaignState public state;

    struct Tier{
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer{
        uint256 totalContribution;
        mapping(uint256 => bool) fundedTiers;
    }

    Tier[] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner(){
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    modifier campaignOpen(){
        require(state == CampaignState.Active, "Campaign is not Active");
        _;
    }

    modifier notPaused(){
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        uint256 _target,
        uint256 _durationinDays
    ){
        name= _name;
        description= _description;
        target= _target;
        deadline= block.timestamp + (_durationinDays * 1 days);
        owner=_owner;
        state=CampaignState.Active;
    }

    function checkAndUpdateCampaignState() internal {
        if(state == CampaignState.Active){
            if(block.timestamp >= deadline){
                state = address(this).balance >= target ? CampaignState.Successful : CampaignState.Failed;
            }else{
                state = address(this).balance >= target ? CampaignState.Successful : CampaignState.Active;
            }
        }
    }

    function fund(uint256 _tierindex) public payable campaignOpen notPaused{
        require(_tierindex < tiers.length, "Invalid Tier");
        require(msg.value == tiers[_tierindex].amount, "Incorrect Amount");

        tiers[_tierindex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierindex] = true;

        checkAndUpdateCampaignState();
    }

    function addTier(        
        string memory _name,
        uint256 _amount
    )public onlyOwner{
        require(_amount > 0, "Amount must be Greater than Zero");
        tiers.push(Tier(_name,_amount,0));
    }

    function removeTier(uint256 _index) public onlyOwner{
        require(_index < tiers.length, "Tier doesn't Exist");
        tiers[_index]=tiers[tiers.length - 1];
        tiers.pop();
    }

    function withdraw() public onlyOwner{
        checkAndUpdateCampaignState();
        require(state == CampaignState.Successful, "Campaign not Successful yet");

        uint256 balance = address(this).balance;
        require(balance > 0, "No Balance to Withdraw");

        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function refund() public{
        checkAndUpdateCampaignState();
        require(state == CampaignState.Failed,"Refunds not Available");
        uint256 amount = backers[msg.sender].totalContribution;
        require(amount > 0,"No Contribution for Refund");

        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hasFundedTier(address _backer, uint256 _tierIndex) public view returns(bool){
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function getTiers() public view returns(Tier[] memory){
        return tiers;
    }

    function togglePause() public onlyOwner{
        paused=!paused;
    }

    function getCampaignStatus()public view returns(CampaignState){
        if(state == CampaignState.Active && block.timestamp > deadline){
            return address(this).balance >= target? CampaignState.Successful : CampaignState.Failed; 
        }
        return state;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen{
        deadline += _daysToAdd * 1 days;
    }
}