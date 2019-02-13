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
  uint256[] public ids;

  struct Quest {
    uint id; //unique id for quest 
    address prizeTokenAddress; //address for the prize token
    uint prizeTokenId; // id if prize is ERC721
    uint prizeTokenAmount; // amount of prize tokens if prize is ERC20
    bool prizeIsNFT; // label the type of prize
    address creator; // creator of the quest 
    address[] requirementsList; // list of token to acquire to complete quest
  }

  mapping  (uint => Quest) public QUESTS; // all quests
  mapping (uint => bool) questExists; //keep track of open/non-canceled quests

  constructor() public {}


  function getId() public view returns(uint){
    return questId;
  }

  function createQuest (
    address _prizeTokenAddress, 
    uint _prizeTokenId,  
    uint _prizeTokenAmount, 
    bool _prizeIsNFT,
    address[] memory _requirementsList
    )  
    public returns(uint){
       
    if (_prizeIsNFT) {

      //check that the amount is 1 (no support for multiple nft prizes)
      require(_prizeTokenAmount == 1, "prize amount for NFT must be 1");

      ERC721 prizeToken = ERC721(_prizeTokenAddress);

      //check that the quest maker owns the NFT and has given us access 
      require(prizeToken.ownerOf(_prizeTokenId) == msg.sender, "quest creator does not own prize");
      require(prizeToken.getApproved(_prizeTokenId) == address(this), "creator has not given access to prize");
      
      // transfer prize to escrow 
      prizeToken.transferFrom(msg.sender, address(this), _prizeTokenId);
    
    } else {

      //check that the prize amount is valid
      require(_prizeTokenAmount > 0, "prize amount must be greater than 0");

      //check that they have a high enough balance
      ERC20 prizeToken = ERC20(_prizeTokenAddress);
      require(prizeToken.balanceOf(msg.sender) >= _prizeTokenAmount, "quest creator does not own enough of prize token");

      //get the allowance for our contract and make sure its high enough 
      uint256 allowance = prizeToken.allowance(msg.sender, address(this));
      require(allowance >= _prizeTokenAmount, "creator has not allowed us enough tokens");

      // transfer prize to escrow
      prizeToken.transferFrom(msg.sender, address(this), _prizeTokenAmount);
      
    }

    questId++; 

    //create the new quest
    Quest memory newQuest = Quest({
      id : questId,
      prizeTokenAddress : _prizeTokenAddress,
      prizeTokenId : _prizeTokenId,
      prizeTokenAmount : _prizeTokenAmount,
      prizeIsNFT : _prizeIsNFT,
      creator : msg.sender,
      requirementsList : _requirementsList
    });

    QUESTS[newQuest.id] = newQuest; // add to the global quest mapping
    questExists[newQuest.id] = true; // mark that this quest is open
    ids.push(newQuest.id); // add to global list of ids

    emit QuestCreated(newQuest.id, newQuest.creator);
  }

  /**
    Creator have the otpion to cancel a quest and regain ownership 
    of the prize that is held in escrow. 
   */
  function cancelQuest(uint _questId) public{
    
    //check that the quest is open 
    require(questExists[_questId], "quest is cancled or doesn't exist"); 
    
    Quest memory currentQuest = QUESTS[_questId]; 
    require(currentQuest.creator == msg.sender, "cant cancel quest if not owner");


    if(currentQuest.prizeIsNFT){
      //give token back to creator 
      ERC721 prizeToken = ERC721(currentQuest.prizeTokenAddress);
      prizeToken.transferFrom(address(this), currentQuest.creator, currentQuest.prizeTokenId);
    } else {
      //give tokens back to owner
      ERC20 prizeToken = ERC20(currentQuest.prizeTokenAddress);
      prizeToken.transfer(currentQuest.creator, currentQuest.prizeTokenAmount);
    }

    //mark the quest as closed
    questExists[currentQuest.id] = false;
  }

  function checkRequiremnetLockup(address _tokenAddress) public returns (uint) {
    ERC721 req = ERC721(_tokenAddress);
    uint balance = req.balanceOf(msg.sender);
    return balance;
  }

  function completeQuest(uint _questId, uint[] memory _submittedTokenIds) public {
    
    //check that the quest is open 
    require(questExists[_questId], "quest does no exist");

    Quest memory quest = QUESTS[_questId];

    //check that the length of submitted tokens is correct 
    require(_submittedTokenIds.length == quest.requirementsList.length, "amount of submitted tokens does not match lenght of requirmenets");
    
    //now check they have submitted transfer rights of all requirements to us
    for (uint i = 0; i<quest.requirementsList.length; i++) {

      //get the NFT that is required
      address requiredTokenAddress = quest.requirementsList[i];
      ERC721 requiredToken = ERC721(requiredTokenAddress);

      //check that the submitter actual owns the NFT they are trying to submit
      require(requiredToken.ownerOf(_submittedTokenIds[i]) == msg.sender, "submitter doesn't own requirement");

      //check that the user has given transfer rights to us
      require(requiredToken.getApproved(_submittedTokenIds[i]) == address(this), "user has not given us transfer rights");

    }

    //if you got this far the submitter owns all NFT requirements and has given us transfer rights

    // swap the prize to the submitter 
    if (quest.prizeIsNFT){
      ERC721 prizeToken = ERC721(quest.prizeTokenAddress);

      //give the prize NFT to the submitter
      prizeToken.transferFrom(address(this), msg.sender, quest.prizeTokenId);

      require(prizeToken.ownerOf(quest.prizeTokenId) == msg.sender, "Prize not transfered");
    }
    else {
      ERC20 prizeToken = ERC20(quest.prizeTokenAddress);

      //give the amount of tokens to the submitter
      prizeToken.transfer(msg.sender, quest.prizeTokenAmount);
    }
    

    //now swap submitted tokens to maker
    for (uint i = 0; i<quest.requirementsList.length; i++) {

      //get the NFT that is required
      address requiredTokenAddress = quest.requirementsList[i];
      ERC721 requiredToken = ERC721(requiredTokenAddress);

      //give new ownership to the maker
      requiredToken.safeTransferFrom(msg.sender, quest.creator, _submittedTokenIds[i]);
    }

    questExists[quest.id] = false;
  }


}

