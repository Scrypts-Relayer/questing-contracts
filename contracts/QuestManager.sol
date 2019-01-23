pragma solidity >=0.4.21 <0.6.0;

/**

  Quest Manager for quest platform on Ethereum. A quest can be 
  created by defining a set of required tokens, and by locking up 
  a prize. 

  A prize can be EITHER an ERC721 or an amount of ERC20 tokens. 

  A required token MUST be an ERC721. 

  To "complete" a quest a user must first give this contract 
  'transfer' rights 

 */
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract QuestManager {

  event QuestCreated(uint indexed _questId, address indexed _creator);
  event QuestCompleted(uint indexed _questId, address indexed _completer);
  event toggleQuestOpem(uint indexed _questId, bool _open);

  uint public questId = 0;

  struct Quest {
    uint id;
    bool openForSubmission; 
    address prizeTokenAddress;
    uint prizeTokenId;
    uint prizeTokenAmount; 
    bool prizeIsNFT;
    address questMaker;
    address[] requirementsList;
    address ipfs; // ipfs address for associated data
    bool open;// is the quest open for submissions
  }

  mapping  (uint => Quest) public QUESTS; // all quests
  mapping (uint => bool) questExists; //store boolen for existing quests
  
  constructor() public {
    // nothing here yet 
  }

  function createQuest (
    address _prizeTokenAddress, 
    uint _prizeTokenId,  
    uint _prizeTokenAmount, 
    bool _prizeIsNFT,
    address[] memory _requirementsList,
    address _IPFSdata
    )  
    public returns(uint){
    
    require(_prizeTokenAmount > 0, "prize amount must be greater than 0");
   
    //if an NFT, check that its valid
    if (_prizeIsNFT) {
      ERC721 nft = ERC721(_prizeTokenAddress);
      //use the 165 function to check it supports the ERC721 interface
      nft;
      //check that the quest maker owns the NFT
      require(nft.ownerOf(_prizeTokenId) == msg.sender, "error over here");
    
    } else {
      //check if the ERC20 prize is a valid token 
      //check that they have a high enough balance
    }

    //create the new quest
    Quest memory newQuest = Quest({
      id : questId,
      openForSubmission : true,
      prizeTokenAddress : _prizeTokenAddress,
      prizeTokenId : _prizeTokenId,
      prizeTokenAmount : _prizeTokenAmount,
      prizeIsNFT : _prizeIsNFT,
      questMaker : msg.sender,
      requirementsList : _requirementsList,
      ipfs : _IPFSdata,
      open : true
    });

    questId++; //increment the id counter
    QUESTS[newQuest.id] = newQuest; //add to the global quest mapping
    questExists[newQuest.id] = true;

    emit QuestCreated(newQuest.id, newQuest.questMaker);
  }


  //need to get data for UIs
  //refercing the way crypto kitties does this 
  //https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code
  function getQuest(uint _questId) public view returns (
    uint id,
    bool openForSubmission, 
    address prizeTokenAddress,
    uint prizeTokenId,
    uint prizeTokenAmount,
    bool prizeIsNFT,
    address questMaker,
    address[] memory requirementsList,
    address ipfs// ipfs address for associated data
  ) {

    //check that the quest exists
    require(questExists[_questId]);

    Quest memory quest = QUESTS[_questId];

    //check that the quest isnt over 
    require(quest.open);

    id = quest.id;
    openForSubmission = quest.openForSubmission;
    prizeTokenAddress = quest.prizeTokenAddress;
    prizeTokenId = quest.prizeTokenId;
    prizeTokenAmount = quest.prizeTokenAmount;
    prizeIsNFT = quest.prizeIsNFT;
    questMaker = quest.questMaker;
    requirementsList = quest.requirementsList;
    ipfs = quest.ipfs;
  }

  //we need a separate function to call to check if the 'maker'
  //has locked up the prize after quest creation
  //locked implies this contract has ownership over funds
  function checkPrizeLockup(uint _questId) internal returns (bool open) {

    //check that we have a quest with this id
    require(questExists[_questId]);

    //get the current quest
    Quest memory currentQuest = QUESTS[_questId];

    //if prize is an NFT, check that we have ownership of prize
    if (currentQuest.prizeIsNFT){
      ERC721 prizeToken = ERC721(currentQuest.prizeTokenAddress);

      //check that this NFT is owned by us 
      require(prizeToken.ownerOf(currentQuest.prizeTokenId) == address(this));

      open = true;
      return open;
    }
    //else, the prize is an ERC20 and we have enough tokens given to us by quest maker
    else {

      ERC20 prizeToken = ERC20(currentQuest.prizeTokenAddress);

      //get the balance for our contract 
      uint256 allowance = prizeToken.allowance(currentQuest.questMaker ,address(this));

      //check that this allowance is at least the amount for the prize 
      require(allowance >= currentQuest.prizeTokenAmount);

      //require that the quest creator owns enough tokens 
      require(prizeToken.balanceOf(currentQuest.questMaker) >= currentQuest.prizeTokenAmount);

      return true;
    }
    return false;
  }

  // function cancelOrder(uint _questId) public{
  //   //code to transfer ownership back to the maker
  // }

  function completeQuest(uint _questId, uint[] memory _submittedTokenIds) public {
    
    //check if the quest with that id exists
    require(questExists[_questId]); 

    //check that quest is open for submissions
    require(QUESTS[_questId].open); 

    //only let users complete quests if our contract has access to the prize
    require (checkPrizeLockup(_questId));

    Quest memory quest = QUESTS[_questId];
    
    //now check they have submitted transfer rights of all requirements to us
    for (uint i=0; i<quest.requirementsList.length; i++) {

      //get the NFT that is required
      address requiredTokenAddress = quest.requirementsList[i];
      ERC721 requiredToken = ERC721(requiredTokenAddress);

      //check that the submitter actual owns the NFT they are trying to submit
      require(requiredToken.ownerOf(_submittedTokenIds[i]) == msg.sender);

      //check that the user has given transfer rights to us
      require(requiredToken.getApproved(_submittedTokenIds[i]) == address(this));

    }

    //if you got this far the submitter owns all NFT requirements and has given us transfer rights

    // swap the prize to the submitter 
    if (quest.prizeIsNFT){
      ERC721 prizeToken = ERC721(quest.prizeTokenAddress);

      //give the prize NFT to the submitter
      prizeToken.safeTransferFrom(address(this), msg.sender, quest.prizeTokenId);
    }
    else {
      ERC20 prizeToken = ERC20(quest.prizeTokenAddress);

      //give the amount of tokens to the submitter
      prizeToken.transfer(msg.sender, quest.prizeTokenAmount);
    }

    //now swap submitted tokens to maker
    for (uint i=0; i<quest.requirementsList.length; i++) {

      //get the NFT that is required
      address requiredTokenAddress = quest.requirementsList[i];
      ERC721 requiredToken = ERC721(requiredTokenAddress);

      //give new ownership to the maker
      requiredToken.safeTransferFrom(msg.sender, quest.questMaker, _submittedTokenIds[i]);
    }

    //now close the quest and remove it from set of existing quests
    QUESTS[quest.id].open = false;
    questExists[quest.id] = false;

  }


}

