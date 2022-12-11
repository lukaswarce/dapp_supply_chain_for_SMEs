const { before } = require("lodash");

const SupplyChain = artifacts.require("SupplyChain");
const truffleAssert = require('truffle-assertions');

var accounts;
var owner;

contract('SupplyChain', (accs) => {
	accounts = accs;
	owner = accounts[0];
});

// Accounts
let acc_owner = accounts[0];	// Contract Owner account
let acc_textile_0 = accounts[1];	// Textile account
let acc_prod_0 = accounts[2];	// Producer account
let acc_qc_0 = accounts[3];	// QualityChecker account
let acc_cons_0 = accounts[4];	// Consumer account

let instance = null;

describe('Programmatic usage suite', function () {

	describe('#index', function () {

		it('can the Textile plan the purchase of yarns', async function () {
			this.timeout(20000);

			instance = await SupplyChain.deployed();
			await instance.addTextile(acc_textile_0, { from: acc_owner });
			await instance.addProducer(acc_prod_0, { from: acc_owner });
			await instance.addQualityChecker(acc_qc_0, { from: acc_owner });
			await instance.addConsumer(acc_cons_0, { from: acc_owner });

			let upc = 1;
			let ownerID = acc_textile_0;
			let originTextileID = acc_textile_0;
			let originTextileName = "Aurora Textile";
			let originTextileInformation = "Bento Goncalves";
			let originTextileLatitude = "34.12345543";
			let originTextileLongitude = "34.12345543";
			let acquisitionNotes = "";
			let auditNotes = "";
			let itemState = 0;

			// Plant a Yarn
			let plan = await instance.yarnPlannedItem(upc,
				originTextileID,
				originTextileName,
				originTextileInformation,
				originTextileLatitude,
				originTextileLongitude,
				{ from: acc_textile_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchYarnItemBufferOne.call(upc);
			let res2 = await instance.fetchYarnItemBufferTwo.call(upc);
			// console.log(res1, 'result buffer 1');
			// console.log(res2, 'result buffer 2');

			// Check results
			assert.equal(res1.upc, upc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.originTextileID, originTextileID, 'Error: Missing or Invalid originTextileID');
			assert.equal(res1.originTextileName, originTextileName, 'Error: Missing or Invalid originTextileName');
			assert.equal(res1.originTextileInformation, originTextileInformation, 'Error: Missing or Invalid originTextileInformation');
			assert.equal(res1.originTextileLatitude, originTextileLatitude, 'Error: Missing or Invalid originTextileLatitude');
			assert.equal(res1.originTextileLongitude, originTextileLongitude, 'Error: Missing or Invalid originTextileLongitude');
			assert.equal(res2.acquisitionNotes, acquisitionNotes, 'Error: Missing or Invalid acquisitionNotes');
			assert.equal(res2.auditNotes, auditNotes, 'Error: Missing or Invalid auditNotes');
			assert.equal(res2.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(plan, 'YarnPlanned');
		});

		it('can the Textile Cutted a Yarn', async function () {
			this.timeout(20000);
			let upc = 1;
			let ownerID = acc_textile_0;
			let originTextileID = acc_textile_0;
			let acquisitionNotes = "bordo wine";
			let itemState = 1;
			let harvest = await instance.yarnAcquisitionItem(upc, acquisitionNotes, { from: acc_textile_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchYarnItemBufferOne.call(upc);
			let res2 = await instance.fetchYarnItemBufferTwo.call(upc);
			// console.log(res1, 'result buffer 1');
			// console.log(res2, 'result buffer 2');

			assert.equal(res1.upc, upc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.originTextileID, originTextileID, 'Error: Missing or Invalid originTextileID');
			assert.equal(res2.acquisitionNotes, acquisitionNotes, 'Error: Missing or Invalid acquisitionNotes');
			assert.equal(res2.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(harvest, 'YarnAcquired');
		});

		it('can the QualityChecker audit a Yarn', async function () {
			this.timeout(20000);
			let upc = 1;
			let ownerID = acc_textile_0;
			let originTextileID = acc_textile_0;
			let auditNotes = "ISO9002 audit passed";
			let itemState = 2;
			let audited = await instance.yarnAuditItem(upc, auditNotes, { from: acc_qc_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchYarnItemBufferOne.call(upc);
			let res2 = await instance.fetchYarnItemBufferTwo.call(upc);
			// console.log(res1, 'result buffer 1');
			// console.log(res2, 'result buffer 2');

			assert.equal(res1.upc, upc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.originTextileID, originTextileID, 'Error: Missing or Invalid originTextileID');
			assert.equal(res2.auditNotes, auditNotes, 'Error: Missing or Invalid auditNotes');
			assert.equal(res2.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(audited, 'YarnAudited');
		});

		it('can the Textile process a Yarn', async function () {
			this.timeout(20000);
			let upc = 1;
			let ownerID = acc_textile_0;
			let originTextileID = acc_textile_0;
			let itemState = 3;
			let processed = await instance.yarnProcessItem(upc, { from: acc_textile_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchYarnItemBufferOne.call(upc);
			let res2 = await instance.fetchYarnItemBufferTwo.call(upc);
			// console.log(res1, 'result buffer 1');
			// console.log(res2, 'result buffer 2');

			assert.equal(res1.upc, upc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.originTextileID, originTextileID, 'Error: Missing or Invalid originTextileID');
			assert.equal(res2.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(processed, 'YarnProcessed');
		});

		it('can the Producer create a Fabric', async function () {
			this.timeout(20000);
			let upc = 1;
			let productID = 1001;
			let ownerID = acc_prod_0;
			let itemState = 0;
			let created = await instance.fabricCreateItem(upc, productID, { from: acc_prod_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(upc);
			// console.log(res1, 'result buffer 1');

			assert.equal(res1.upc, upc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.productID, productID, 'Error: Missing or Invalid productID');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(created, 'FabricCreated');
		});

		it('can the Producer cut a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let yarnUpc = 1;
			let productID = 1001;
			let ownerID = acc_prod_0;
			let itemState = 1;
			let cutted = await instance.fabricCutItem(fabricUpc, yarnUpc, { from: acc_prod_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.productID, productID, 'Error: Missing or Invalid productID');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			assert.equal(res1.yarns[0], yarnUpc, 'Error: Invalid item yarnUpc');
			truffleAssert.eventEmitted(cutted, 'FabricCutted');
		});

		it('can the Producer produce a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let productNotes = "Organic Yarn Fabric";
			let productPrice = 26;
			let ownerID = acc_prod_0;
			let itemState = 2;
			let produced = await instance.fabricProduceItem(fabricUpc, productNotes, productPrice, { from: acc_prod_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.productNotes, productNotes, 'Error: Missing or Invalid productNotes');
			assert.equal(res1.productPrice, productPrice, 'Error: Missing or Invalid productPrice');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(produced, 'FabricProduced');
		});

		it('can the QualityChecker certify a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let certifyNotes = "ISO9002 Certified";
			let ownerID = acc_prod_0;
			let itemState = 3;
			let certified = await instance.fabricCertifyItem(fabricUpc, certifyNotes, { from: acc_qc_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.certifyNotes, certifyNotes, 'Error: Missing or Invalid certifyNotes');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(certified, 'FabricCertified');
		});

		it('can the Producer pack a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let ownerID = acc_prod_0;
			let itemState = 4;
			let packed = await instance.fabricPackItem(fabricUpc, { from: acc_prod_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(packed, 'FabricPacked');
		});

		it('can the Consumer sell a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let ownerID = acc_prod_0;
			let itemState = 5;
			let forsale = await instance.fabricSellItem(fabricUpc, { from: acc_cons_0 });

			// Read the result from blockchain
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(forsale, 'FabricForSale');
		});

		it('can the Consumer buy a Fabric', async function () {
			this.timeout(20000);
			let fabricUpc = 1;
			let ownerID = acc_cons_0;
			let itemState = 6;
			let res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			let purchased = await instance.fabricBuyItem(fabricUpc, { from: acc_cons_0, value: res1.productPrice });

			// Read the result from blockchain
			res1 = await instance.fetchFabricItemBufferOne.call(fabricUpc);
			// console.log(res1, 'result buffer 1');
			// console.log(res1.yarns, 'yarns');

			assert.equal(res1.upc, fabricUpc, 'Error: Invalid item UPC');
			assert.equal(res1.ownerID, ownerID, 'Error: Missing or Invalid ownerID');
			assert.equal(res1.itemState, itemState, 'Error: Invalid item State');
			truffleAssert.eventEmitted(purchased, 'FabricPurchased');
		});
	});
});