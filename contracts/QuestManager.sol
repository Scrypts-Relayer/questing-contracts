pragma solidity >=0.4.21 <0.6.0;

contract ERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator) public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId) public;

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
contract QuestManager {

  event QuestCreated(uint indexed _questId, address indexed _creator);
  event QuestCompleted(uint indexed _questId, address indexed _completer);

  uint questId = 0;

  struct Quest {
    uint id;
    bool openForSubmission; 
    address prizeTokenAddress;
    uint prizeTokenId;
    address questMaker;
    //string questName;
    address[] requirementsList;
    address ipfs; // ipfs address for associated data
  }

  mapping (uint => Quest) QUESTS; // all quests
  uint NUM_QUESTS = 0; // current total number of quests

  constructor() public {
    // nothing here yet 
  }

  function createQuest(
    address _prizeTokenAddress, 
    uint _prizeTokenId,  
    address[] memory _requirementsList,
    address _IPFSdata
    ) 
    public {
    //allow this contract to have transfer rights to prize token
    ERC721 nftInstance = ERC721(_prizeTokenAddress);
    nftInstance.safeTransferFrom(msg.sender, this, _prizeTokenId); 

    //create the new quest
    Quest memory newQuest = Quest({
      id : questId,
      openForSubmission : true,
      prizeTokenAddress : _prizeTokenAddress,
      prizeTokenId : _prizeTokenId,
      questMaker : msg.sender,
      requirementsList : _requirementsList,
      ipfs : _IPFSdata
    });

    questId++; //increment the id counter
    NUM_QUESTS ++; 
    QUESTS.push(newQuest.id, newQuest); //add to the global quest mapping

  }

  function toggleQuestOpen(bool _open, uint _questId) public{
    
    //check that the sender owns the quest 
    require(QUESTS[_questId].questMaker == msg.sender);

    //set the quest open state to the input parameter
    QUESTS[_questId].openForSubmission = _open;

  }

  function completeQuest(uint _questId) public returns (bool completed){
    
  }
}

