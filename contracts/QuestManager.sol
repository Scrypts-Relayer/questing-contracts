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
    bool open;// is the quest open for submissions
  }

  mapping (uint => Quest) QUESTS; // all quests
  mapping (uint => bool) questExists; //store boolen for existing quests
  
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
      require(nft.supportsInterface(0x80ac58cd));

      //check that the quest maker owns the NFT
      require(nft.ownerOf(_prizeTokenId) == msg.sender);


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

  }

  //need to get data for UIs
  //refercing the way crypto kitties does this 
  //https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code
  function getQuest(uint _questId) public returns (
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

      return true;
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

  function cancelOrder(uint _questId) public{
    //code to transfer ownership back to the maker
  }


  function completeQuest(uint _questId, uint[] _submittedTokenIds) public returns (bool metRequirements, bool prizeWasThere){
    
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

