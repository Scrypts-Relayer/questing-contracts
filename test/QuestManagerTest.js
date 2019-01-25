const Quest = artifacts.require("QuestManager");
const NFT = artifacts.require("Mintable");

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
    let res1 = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});

    await instance.cancelQuest(0);

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
    let res1 = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});

    try {
      await instance.cancelQuest(0, {from : a2});
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
      let res1 = await instance.createQuest(nftAddress, prizeid, 0, true, rList, nftAddress, {from : a1});
    } catch(error){
      assert.include(error.message, "prize amount must be greater than 0")
    }
  });

  it("creator needs to own prize", async () => {
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
      let res1 = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});
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
      let res = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});
    } catch(error){
        assert.include(error.message, 'creator has not given access to prize')
    }
  });

  it("check that prize gets transfered after quest", async () => {
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
    let res1 = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});

    //check that quest contract now owns prize
    let owner = await nft.ownerOf(prizeid);
    assert.equal(questAddress,owner);

  });





  



})




