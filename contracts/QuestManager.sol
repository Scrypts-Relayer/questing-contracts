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

  constructor() public {}

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
   
    if (_prizeIsNFT) {
      ERC721 prizeToken = ERC721(_prizeTokenAddress);
      //check that the quest maker owns the NFT
      require(prizeToken.ownerOf(_prizeTokenId) == msg.sender, "quest creator does not own prize");
      require(prizeToken.getApproved(_prizeTokenId) == address(this), "creator has not given access to prize");
      
      //now transfer ownership to this contract 
      prizeToken.transferFrom(msg.sender, address(this), _prizeTokenId);
    
    } else {
      //check that they have a high enough balance
      ERC20 prizeToken = ERC20(_prizeTokenAddress);
      require(prizeToken.balanceOf(msg.sender) >= _prizeTokenAmount, "quest creator does not own enough of prize token");

      //get the balance for our contract 
      uint256 allowance = prizeToken.allowance(msg.sender, address(this));
      
      require(allowance >= _prizeTokenAmount, "creator has not allowed us enough tokens");

      //give this contract the tokens
      prizeToken.transfer(address(this), _prizeTokenAmount);
      
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

    ids.push(questId);

    emit QuestCreated(newQuest.id, newQuest.questMaker);
  }

  function cancelQuest(uint _questId) public{

    require(questExists[_questId], "quest is cancled or doesn't exist"); //check if the quest with that id exists
    
    Quest memory currentQuest = QUESTS[_questId]; 

    require(currentQuest.questMaker == msg.sender, "cant cancel quest if not owner");

    if(currentQuest.prizeIsNFT){
      //give nft back to creator 
      ERC721 prizeToken = ERC721(currentQuest.prizeTokenAddress);
      prizeToken.transferFrom(address(this), currentQuest.questMaker, currentQuest.prizeTokenId);
    } else {
      ERC20 prizeToken = ERC20(currentQuest.prizeTokenAddress);
      prizeToken.transfer(currentQuest.questMaker, currentQuest.prizeTokenAmount);
    }
    questExists[currentQuest.id] = false;
    QUESTS[currentQuest.id].open = false;

  }

  function completeQuest(uint _questId, uint[] memory _submittedTokenIds) public {
    
    //check if the quest with that id exists
    require(questExists[_questId]); 

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

