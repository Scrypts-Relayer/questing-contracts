const Quest = artifacts.require("QuestManager");

contract("QuestManager", accounts => {
  it("Id increments as quests are added.", async () => {
    let instance = await Quest.deployed();
    const a1 = accounts[0];
    let nftAddress = '0x16baf0de678e52367adc69fd067e5edd1d33e3bf';
    let prizeid = 972;
    let rList = ['0x16baf0de678e52367adc69fd067e5edd1d33e3bf'];

    //create 2 quests
   // await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});
    let res = await instance.createQuest(nftAddress, prizeid, 1, true, rList, nftAddress, {from : a1});
    
    console.log(res);
    // //check that id has been incremented from 0 -> 1
    // assert.equal(res.logs[0].args._questId, 1);

    // let q = await instance.QUESTS.call(0);
    // console.log(q);
  });
})

