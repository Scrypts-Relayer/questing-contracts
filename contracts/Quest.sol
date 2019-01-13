pragma solidity >=0.4.21 <0.6.0;

contract Quest {

  struct Quest {
    address[] tokensRequired;
    bool openForSubmission;
    address prizeTokenAddress;
    uint prizeTokenId;
    address makerAddress;
  }

  constructor() public{

  }



}


