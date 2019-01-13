pragma solidity >=0.4.21 <0.6.0;

contract QuestManager {

  event QuestCreated(uint indexed _questId, address indexed _creator);
  event QuestCompleted(uint indexed _questId, address indexed _completer);

  struct Quest {
    uint num_reqs; // total number of types of requirements
    uint num_rews; // total number of types of rewards
    uint max; // number of times quest can be completed, 0 for infinity
    address ipfs; // ipfs address for associated data
    mapping (uint => mapping (address => uint)) reqs; // map requirement type to token factory address to quantity
    mapping (uint => address) rews; // reward assets held in escrow until quest completion
  }

  mapping (uint => Quest) QUESTS; // all quests
  uint NUM_QUESTS = 0; // current total number of quests

  constructor() public {
    //
    // we could get rid of this...?
    //
  }

  function createQuest(
    uint _max,
    uint[] _numEachReq, // amount assets required from same factory
    address[] _reqs, // points to factory
    address[] _rews, // each index points to a specific asset
    address _ipfs
    ) public {
    require(_reqs.length == _numEachReq.length);
    //
    // CODE HERE!
    // - check this conctract has ownership over reward assets
    // - fungible requirements and rewards should be held in escrow in a
    //    dummy contract (possibly meeting ERC721 standard) we can quickly
    //    whip up. Thus, each type (or all) fungible rewards count as 1 type
    //    of reward.
    // - current design does not allow creator to back out of posted quest
    //    and I'm fine with that!
    //
    QuestCreated(NUM_QUESTS, msg.sender);
    NUM_QUESTS = NUM_QUESTS + 1;
  }

  function completeQuest(uint _questId, address[] _reqs ) public {
    //
    // CODE HERE!
    // - decrement Quest.max
    // - transfer assets from escrow to msg.sender
    //
    QuestCompleted(_questId, msg.sender);
  }
}

