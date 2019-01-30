const Quest = artifacts.require("QuestManager");
const NFT = artifacts.require("Mintable");
const NFT2 = artifacts.require("Mintable2");
const ERC20 = artifacts.require("ERC20Mintable")

contract("QuestManager", accounts => {

  //TESTS FOR NFT QUESTS

  let prizeTokenId = 1;

  it("Check that owner can cancel quest", async () => {
    
    const a1 = accounts[0];
    
    let prizeid = prizeTokenId;
    prizeTokenId ++;

    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a1, prizeid);
    
    instance = await Quest.deployed();
    let rList = [nftAddress];

    //give the token to quest contract 
    questAddress = instance.address;
    await nft.approve(questAddress, prizeid, {from : a1});
    await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : a1});

    await instance.cancelQuest(1);

    //check that owner is the creator again
    let owner = await nft.ownerOf(prizeid);
    assert.equal(a1, owner);
  });

  it("Check that non-owner can't cancel quest", async () => {
    const a1 = accounts[0];
    const a2 = accounts[1];
    let prizeid = prizeTokenId;
    prizeTokenId ++;
    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a1, prizeid);
    instance = await Quest.deployed();
    let rList = [nftAddress];

    //give the token to quest contract 
    questAddress = instance.address;
    await nft.approve(questAddress, prizeid, {from : a1});
    await instance.createQuest(nftAddress, prizeid, 1, true, rList,  {from : a1});

    //get the id of the latest 
    let curId = await instance.getId();
    curId = parseInt(curId.toString());

    try {
      await instance.cancelQuest(curId, {from : a2});
    } catch(error){
      assert.include(error.message,'cant cancel quest if not owner');
    }
  });

  it("check that amount of 0 fails", async () => {
    const a1 = accounts[0];
    let prizeid = prizeTokenId;
    prizeTokenId ++;
    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a1, prizeid);
    instance = await Quest.deployed();
    let rList = [nftAddress];

    //give the token to quest contract 
    questAddress = instance.address;
    await nft.approve(questAddress, prizeid, {from : a1});
    try {
      let res1 = await instance.createQuest(nftAddress, prizeid, 0, false, rList, {from : a1});
    } catch(error){
      assert.include(error.message, "prize amount must be greater than 0")
    }
  });

  it("creator needs to own prize for EC721", async () => {
    const a1 = accounts[0];
    const a2 = accounts[1]
    let prizeid = prizeTokenId;
    prizeTokenId ++;
    //setup NFT contract
    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a2, prizeid);
    instance = await Quest.deployed();
    let rList = [nftAddress];
    try {
      let res1 = await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : a1});
    } catch(error){
      assert.include(error.message, "quest creator does not own prize")
    }
  });


  it("check that prize lockup fails when prize isnt locked up", async () => {
    const a1 = accounts[0];
    instance = await Quest.deployed();
    questAddress = instance.address;
    let prizeid = prizeTokenId;
    prizeTokenId ++;
    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a1, prizeid);
    let rList = [nftAddress];
    try {
      let res = await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : a1});
    } catch(error){
        assert.include(error.message, 'creator has not given access to prize')
    }
  });

  it("check that prize gets transfered during creation for ERC721", async () => {
    const a1 = accounts[0];
    let prizeid = prizeTokenId;
    prizeTokenId ++;
    nft = await NFT.deployed();
    let nftAddress = nft.address;
    await nft.mint(a1, prizeid);
    instance = await Quest.deployed();
    let rList = [nftAddress];

    //give the token to quest contract 
    questAddress = instance.address;
    await nft.approve(questAddress, prizeid, {from : a1});
    await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : a1});

    //check that quest contract now owns prize
    let owner = await nft.ownerOf(prizeid);
    assert.equal(questAddress,owner);

  });


//test that an NFT prize can be completed 
it("check that ERC721 prize gets transfered after quest", async () => {
    
    // create the maker and the taker
    const creator = accounts[0];
    const submitter = accounts[1];

    let prizeid = prizeTokenId;
    prizeTokenId ++;

    //create the id for the requirement
    let requirementId = prizeTokenId;
    prizeTokenId ++;

    nft = await NFT.deployed();
    let nftAddress = nft.address;

    //give the prize to the creator
    await nft.mint(creator, prizeid);

    //give the requirmenet to submitter 
    await nft.mint(submitter, requirementId);

    instance = await Quest.deployed();

    //create a requirment of this NFT
    let rList = [nftAddress];

    questAddress = instance.address;
    await nft.approve(questAddress, prizeid, {from : creator});
    await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : creator});

    //have the submitter give our contract transfer rights 
    await nft.approve(questAddress, requirementId, {from : submitter});

    //get the id of the latest 
    let curId = await instance.getId();
    curId = parseInt(curId.toString());

    //now try and submit 
    await instance.completeQuest(curId, [requirementId], {from : submitter});

    //check that the prize has been transferred
    let owner = await nft.ownerOf(prizeid);

    //check that submitter owns prize
    assert.equal(owner, submitter)

  });


//test that an NFT prize can be completed 
it("check that submitted tokens get transfered", async () => {
    
  // create the maker and the taker
  const creator = accounts[0];
  const submitter = accounts[1];

  let prizeid = prizeTokenId;
  prizeTokenId ++;

  //create the id for the requirement
  let requirementId = prizeTokenId;
  prizeTokenId ++;

  nft = await NFT.deployed();
  let nftAddress = nft.address;

  //give the prize to the creator
  await nft.mint(creator, prizeid);

  //give the requirmenet to submitter 
  await nft.mint(submitter, requirementId);

  instance = await Quest.deployed();

  //create a requirment of this NFT
  let rList = [nftAddress];

  questAddress = instance.address;
  await nft.approve(questAddress, prizeid, {from : creator});
  await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : creator});

  //have the submitter give our contract transfer rights 
  await nft.approve(questAddress, requirementId, {from : submitter});

  //get the id of the latest 
  let curId = await instance.getId();
  curId = parseInt(curId.toString());

  //now try and submit 
  await instance.completeQuest(curId, [requirementId], {from : submitter});

  //check that the prize has been transferred
  let owner = await nft.ownerOf(requirementId);

  //check that submitter owns prize
  assert.equal(owner, creator)

});



//test that an NFT prize can be completed 
it("check that submit works with multiple", async () => {
    
  // create the maker and the taker
  const creator = accounts[0];
  const submitter = accounts[1];

  let prizeid = prizeTokenId;
  prizeTokenId ++;

  //create the id for the requirement
  let requirementId = prizeTokenId;
  prizeTokenId ++;

  let requirementId2 = prizeTokenId;
  prizeTokenId ++;

  nft = await NFT.deployed();
  let nftAddress = nft.address;

  nft2 = await NFT2.deployed();
  let nft2Address = nft2.address;

  //give the prize to the creator
  await nft.mint(creator, prizeid);

  //give the requirmenet to submitter and mint the extra
  await nft.mint(submitter, requirementId);
  await nft2.mint(submitter, requirementId2);

  instance = await Quest.deployed();

  //create a requirment of this NFT
  let rList = [nftAddress, nft2Address];

  questAddress = instance.address;
  await nft.approve(questAddress, prizeid, {from : creator});
  await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : creator});

  //have the submitter give our contract transfer rights 
  await nft.approve(questAddress, requirementId, {from : submitter});
  await nft2.approve(questAddress, requirementId2, {from : submitter});

  //get the id of the latest 
  let curId = await instance.getId();
  curId = parseInt(curId.toString());

  //now try and submit 
  await instance.completeQuest(curId, [requirementId, requirementId2], {from : submitter});

});


//test that an NFT prize can be completed 
it("test that it fails if not owner of both", async () => {
    
  // create the maker and the taker
  const creator = accounts[0];
  const submitter = accounts[1];

  let prizeid = prizeTokenId;
  prizeTokenId ++;

  //create the id for the requirement
  let requirementId = prizeTokenId;
  prizeTokenId ++;

  let requirementId2 = prizeTokenId;
  prizeTokenId ++;

  nft = await NFT.deployed();
  let nftAddress = nft.address;

  nft2 = await NFT2.deployed();
  let nft2Address = nft2.address;

  //give the prize to the creator
  await nft.mint(creator, prizeid);

  //give the requirmenet to submitter and mint the extra
  await nft.mint(submitter, requirementId);
  await nft2.mint(submitter, requirementId2);

  instance = await Quest.deployed();

  //create a requirment of this NFT
  let rList = [nftAddress, nft2Address];

  questAddress = instance.address;
  await nft.approve(questAddress, prizeid, {from : creator});
  await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : creator});

  //have the submitter give our contract transfer rights 
  await nft.approve(questAddress, requirementId, {from : submitter});
  await nft2.approve(questAddress, requirementId2, {from : submitter});

  //get the id of the latest 
  let curId = await instance.getId();
  curId = parseInt(curId.toString());

  //create an incorrect id
  let wrongId = requirementId2+1;

  //now try and submit 
  try {
    await instance.completeQuest(curId, [requirementId, wrongId], {from : submitter});
    assert(false) //should have caught error
  } catch(error){
    
  }
});


//test that an NFT prize can be completed 
it("check that submit fails if submit length is incorrect", async () => {
    
  // create the maker and the taker
  const creator = accounts[0];
  const submitter = accounts[1];

  let prizeid = prizeTokenId;
  prizeTokenId ++;

  //create the id for the requirement
  let requirementId = prizeTokenId;
  prizeTokenId ++;

  nft = await NFT.deployed();
  let nftAddress = nft.address;

  nft2 = await NFT2.deployed();
  let nft2Address = nft2.address;

  //give the prize to the creator
  await nft.mint(creator, prizeid);

  //give the requirmenet to submitter 
  await nft.mint(submitter, requirementId);

  instance = await Quest.deployed();

  //create a requirment of this NFT
  let rList = [nftAddress, nft2Address];

  questAddress = instance.address;
  await nft.approve(questAddress, prizeid, {from : creator});
  await instance.createQuest(nftAddress, prizeid, 1, true, rList, {from : creator});

  //get the id of the latest 
  let curId = await instance.getId();
  curId = parseInt(curId.toString());

  //now try and submit 
  try {
    await instance.completeQuest(curId, [requirementId], {from : submitter});
  } catch (error){
    assert.include(error.message, "amount of submitted tokens does not match lenght of requirmenets")
  }
});


  //-----------ERC20 TESTS----------------//

  it("creator needs to own prize for EC20", async () => {
    const a1 = accounts[0];
    let prizeid = prizeTokenId;
    prizeTokenId ++;

    //setup token contract and gives tokens
    erc20 = await ERC20.deployed();
    let erc20Address = erc20.address;
    await erc20.mint(a1, 10);

    instance = await Quest.deployed();
    let rList = [erc20Address];

    try {
      let res1 = await instance.createQuest(erc20Address, 0, 40, false, rList, {from : a1});
    } catch(error){
      assert.include(error.message, "quest creator does not own enough of prize token")
    }
  });

  it("ERC20 prize is transferred to contract after creation", async () => {
    const a1 = accounts[0];
    let prizeid = prizeTokenId;
    prizeTokenId ++;

    //setup token contract and gives tokens
    erc20 = await ERC20.deployed();
    let erc20Address = erc20.address;
    await erc20.mint(a1, 60);

    instance = await Quest.deployed();
    let rList = [erc20Address];

    await erc20.approve(instance.address, 60, {from : a1});

    await instance.createQuest(erc20Address, 0, 60, false, rList, {from : a1});

    let balance = await erc20.balanceOf(instance.address)
    assert.equal(balance, 60)

  });

  it("Tokens back to creator when cancleing erc20", async () => {
    const a1 = accounts[3];
    let prizeid = prizeTokenId;
    prizeTokenId ++;

    //setup token contract and gives tokens
    erc20 = await ERC20.deployed();
    let erc20Address = erc20.address;
    await erc20.mint(a1, 60);

    instance = await Quest.deployed();
    let rList = [erc20Address];

    await erc20.approve(instance.address, 60, {from : a1});

    await instance.createQuest(erc20Address, 0, 60, false, rList, {from : a1});

    //get the id of the latest 
    let curId = await instance.getId();
    curId = parseInt(curId.toString());

    await instance.cancelQuest(curId, {from : a1})

    let balance = await erc20.balanceOf(a1)

    assert.equal(balance, 60)
  });


  it("Tokens get transfered to creator", async () => {
    const a1 = accounts[3];
    let prizeid = prizeTokenId;
    prizeTokenId ++;

    //setup token contract and gives tokens
    erc20 = await ERC20.deployed();
    let erc20Address = erc20.address;
    await erc20.mint(a1, 60);

    instance = await Quest.deployed();
    let rList = [erc20Address];

    await erc20.approve(instance.address, 60, {from : a1});

    await instance.createQuest(erc20Address, 0, 60, false, rList, {from : a1});

  });


//test that an NFT prize can be completed 
it("check that ERC721 prize gets transfered after quest", async () => {
    
  // create the maker and the taker
  const creator = accounts[5];
  const submitter = accounts[6];

  //create the id for the requirement
  let requirementId = prizeTokenId;
  prizeTokenId ++;

  nft = await NFT.deployed();
  let nftAddress = nft.address;
  //give the requirmenet to submitter 
  await nft.mint(submitter, requirementId);

  instance = await Quest.deployed();

  questAddress = instance.address;

  //setup token contract and gives tokens
  erc20 = await ERC20.deployed();
  let erc20Address = erc20.address;
  await erc20.mint(creator, 60);

  instance = await Quest.deployed();
  let rList = [nftAddress];

  await erc20.approve(instance.address, 60, {from : creator});

  await instance.createQuest(erc20Address, 0, 60, false, rList, {from : creator});

  //have the submitter give our contract transfer rights 
  await nft.approve(questAddress, requirementId, {from : submitter});

  //get the id of the latest 
  let curId = await instance.getId();
  curId = parseInt(curId.toString());

  //now try and submit 
  await instance.completeQuest(curId, [requirementId], {from : submitter});

  let balance = await erc20.balanceOf(submitter);
  assert.equal(balance, 60);

});

 
  

})




