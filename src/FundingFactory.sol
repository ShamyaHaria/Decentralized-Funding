//SPDX-License-Identifier: MIT

pragma solidity >0.7.0 <=0.9.0;

import {DecentralizedFunding} from "./DecentralizedFunding.sol";

contract FundingFactory{
    address public owner;
    bool public paused;

    struct Campaign{
        address campaignAddress;
        address owner;
        string name;
        uint256 creationTime;
    }

    Campaign[] public campaigns;
    mapping(address => Campaign[]) public userCampaigns;

    modifier onlyOwner(){
        require(msg.sender == owner,"Not the Owner");
        _;
    }

    modifier notPaused(){
        require(!paused, "Factory is paused");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _target,
        uint256 _durationInDays
    ) external notPaused{
        DecentralizedFunding newCampaign = new DecentralizedFunding(
            msg.sender,
            _name,
            _description,
            _target,
            _durationInDays
        );
        address campaignAddress = address(newCampaign);

        Campaign memory campaign = Campaign({
            campaignAddress : campaignAddress,
            owner : msg.sender,
            name : _name,
            creationTime : block.timestamp
        });
        campaigns.push(campaign);
        userCampaigns[msg.sender].push(campaign);
    }
    function getUserCampaigns(address _user) external view returns (Campaign[] memory) {
        return userCampaigns[_user];
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }
}