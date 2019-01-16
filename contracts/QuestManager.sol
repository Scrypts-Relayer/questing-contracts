pragma solidity >=0.4.21 <0.6.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC165 {
            /// @notice Query if a contract implements an interface
            /// @param interfaceID The interface identifier, as specified in ERC-165
            /// @dev Interface identification is specified in ERC-165. This function
            ///  uses less than 30,000 gas.
            /// @return `true` if the contract implements `interfaceID` and
            ///  `interfaceID` is not 0xffffffff, `false` otherwise
            function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721 is ERC165{
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
  event toggleQuestOpem(uint indexed _questId, bool _open);

  uint questId = 0;

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
    bool prizeLocked; //state for checking if maker has given ownership of prize token yet
  }

  mapping (uint => Quest) QUESTS; // all quests
  mapping (uint => bool) questExists; //store boolen for existing quests
  uint NUM_QUESTS = 0; // current total number of quests


  constructor() public {
    // nothing here yet 
  }

  function createQuest(
    address _prizeTokenAddress, 
    uint _prizeTokenId,  
    uint _prizeTokenAmount, 
    bool _prizeIsNFT,
    address[] memory _requirementsList,
    address _IPFSdata
    ) 
    public returns (bool succesfullyCreated){
   
    //if an NFT, check that its valid
    if (_prizeIsNFT) {
      ERC721 nft = ERC721(_prizeTokenAddress);
      //use the 165 function to check it supports the ERC721 interface
      bool isValid = nft.supportsInterface(0x80ac58cd);
      //QUESTION
      require(isValid);
      return (isValid);
    } else {
      //
      //
      //code to check for valid ERC20 - probably will use hardcoded list
      //
      //
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
      prizeLocked : false
    });

    questId++; //increment the id counter
    NUM_QUESTS ++; 
    QUESTS[newQuest.id] = newQuest; //add to the global quest mapping
    questExists[newQuest.id] = true;

  }

  //we need a separate function to call to check if the 'maker'
  //has locked up the prize after quest creation, call this
  //function after 'maker' has given ownership of prize
  function checkPrizeLockup(uint _questId) public{
    
    //check that we have a quest with this id
    require(questExists[_questId]);

    //get the current quest
    Quest memory currentQuest = QUESTS[_questId];

    //if prize is an NFT, check that we have approval rights
    if (currentQuest.prizeIsNFT){
      ERC721 prizeToken = ERC721(currentQuest.prizeTokenAddress);
      //check that this NFT 
      require(prizeToken.getApproved(currentQuest.prizeTokenId) == address(this));

      //update the quest now that we know ownership transferred
      QUESTS[_questId].prizeLocked = true;

    }
    //else, the prize is an ERC20 
    else {
      ERC20 prizeToken = ERC20(currentQuest.prizeTokenAddress);

      //get the allowance for our contract 
      uint256 allowance = prizeToken.allowance(currentQuest.questMaker, address(this));

      //check that this allowance is at least the amount for the prize 
      require(allowance >= currentQuest.prizeTokenAmount);

    }

  }

  //function to close quest if a maker decides to
  function toggleQuestOpen(bool _open, uint _questId) public{
    
    //check that we have a quest with this id
    require(questExists[_questId]);

    //check that the sender owns the quest 
    require(QUESTS[_questId].questMaker == msg.sender);

    //set the quest open state to the input parameter
    QUESTS[_questId].openForSubmission = _open;

  }


  function completeQuest(uint _questId) public returns (bool completed){
    
    require(questExists[_questId]); //check if the quest with that id exists
    
    //Quest memory quest = QUESTS[_questId]; //get the quest 


  }



}

