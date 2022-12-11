// SPDX-License-Identifier: MIT

pragma solidity >=0.6.00;

// Importing the necessary sol files
import "../core/Ownable.sol";
import "../access/roles/ConsumerRole.sol";
import "../access/roles/TextileRole.sol";
import "../access/roles/ProducerRole.sol";
import "../access/roles/QualityCheckerRole.sol";

// Define a contract 'Supplychain'
contract SupplyChain is
    Ownable,
    TextileRole,
    QualityCheckerRole,
    ConsumerRole,
    ProducerRole
{
    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint256 sku_cnt;

    // yarn_upc -> yarnItem
    mapping(uint256 => YarnItem) yarnItems;
    // fabric_upc -> fabricItems
    mapping(uint256 => FabricItem) fabricItems;
    // fabric_upc -> yarn_upc[]
    mapping(uint256 => uint256[]) fabricYarns;

    // Define enum 'State' with the following values:
    enum YarnState {
		Planned,
		Acquired,
		Audited,
		Processed
	}
    YarnState constant defaultYarnState = YarnState.Planned;

    enum FabricState {
        Created,
        Cutted,
        Produced,
        Certified,
        Packed,
        ForSale,
        Purchased
    }
    FabricState constant defaultFabricState = FabricState.Created;

    // Define a struct 'YarnItem' with the following fields:
    struct YarnItem {
        uint256 sku; // Stock Keeping Unit (SKU)
        uint256 upc; // Universal Product Code (UPC), generated by the Textile, goes on the package, can be verified by the Consumer
        address ownerID; // Metamask-Ethereum address of the current owner as the product moves through stages
        address originTextileID; // Metamask-Ethereum address of the Textile
        string originTextileName; // Textile Name
        string originTextileInformation; // Textile Information
        string originTextileLatitude; // Textile Latitude
        string originTextileLongitude; // Textile Longitude
        string acquisitionNotes; // Acquisition Notes
        string auditNotes; // Autit Notes
        YarnState itemState; // Product State as represented in the enum above
    }

    // Define a struct 'FabricItem' with the following fields:
    struct FabricItem {
        uint256 sku; // Stock Keeping Unit (SKU)
        uint256 upc; // Universal Product Code (UPC), generated by the Procuder, goes on the package, can be verified by the Consumer
        address ownerID; // Metamask-Ethereum address of the current owner as the product moves through stages
        uint256 productID; // Product ID potentially a combination of upc + sku
        string productNotes; // Product Notes
        uint256 productPrice; // Product Price
        address producerID; // Metamask-Ethereum address of the Producer
        address consumerID; // Metamask-Ethereum address of the Consumer
        string certifyNotes; // Certify Notes
        FabricState itemState; // Product State as represented in the enum above
    }

    // Define events of Yarns
    event YarnPlanned(uint256 yarnUpc);
    event YarnAcquired(uint256 yarnUpc);
    event YarnAudited(uint256 yarnUpc);
    event YarnProcessed(uint256 yarnUpc);

    // Define events of Fabrics
    event FabricCreated(uint256 fabricUpc);
    event FabricCutted(uint256 fabricUpc, uint256 yarnUpc);
    event FabricProduced(uint256 fabricUpc);
    event FabricPacked(uint256 fabricUpc);
    event FabricCertified(uint256 fabricUpc);
    event FabricForSale(uint256 fabricUpc);
    event FabricPurchased(uint256 fabricUpc);

    // Define a modifer that verifies the Caller
    modifier verifyCaller(address _address) {
        require(msg.sender == _address, "verifyCaller: unexpected caller");
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price, "paidEnough");
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint256 _fabricUpc) {
        _;
        uint256 _price = fabricItems[_fabricUpc].productPrice;
        uint256 amountToReturn = msg.value - _price;
        payable(fabricItems[_fabricUpc].consumerID).transfer(amountToReturn);
    }

    // Define a modifier that checks if an yarnItem.state of a upc is Planned
    modifier isPlanned(uint256 _yarnUpc) {
        require(yarnItems[_yarnUpc].itemState == YarnState.Planned, "not Planned");
        _;
    }

    // Define a modifier that checks if an yarnItem.state of a upc is Acquired
    modifier isAcquired(uint256 _yarnUpc) {
        require(yarnItems[_yarnUpc].itemState == YarnState.Acquired, "not Acquired");
        _;
    }

    // Define a modifier that checks if an yarnItem.state of a upc is Audited
    modifier isAudited(uint256 _yarnUpc) {
        require(yarnItems[_yarnUpc].itemState == YarnState.Audited, "not Audited");
        _;
    }

    // Define a modifier that checks if an yarnItem.state of a upc is Processed
    modifier isProcessed(uint256 _yarnUpc) {
        require(yarnItems[_yarnUpc].itemState == YarnState.Processed, "not Processed");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Created
    modifier isCreated(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Created, "not Created");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Cutted
    modifier isCutted(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Cutted, "not Cutted");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Produced
    modifier isProduced(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Produced, "not Produced");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Packed
    modifier isPacked(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Packed, "not Packed");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Certified
    modifier isCertified(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Certified, "not Certified");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is ForSale
    modifier isForSale(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.ForSale, "not ForSale");
        _;
    }

    // Define a modifier that checks if an fabricItem.state of a upc is Purchased
    modifier isPurchased(uint256 _fabricUpc) {
        require(fabricItems[_fabricUpc].itemState == FabricState.Purchased, "not Purchased");
        _;
    }

    // In the constructor
    // set 'sku' to 1
    // set 'upc' to 1
    constructor() payable {
        sku_cnt = 1;
    }

    // Transfer Eth to owner and terminate contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    // Define a function 'yarnPlannedItem' that allows a Textile to mark an item 'Planned'
    function yarnPlannedItem(
        uint256 _yarnUpc,
        address _originTextileID,
        string calldata _originTextileName,
        string calldata _originTextileInformation,
        string calldata _originTextileLatitude,
        string calldata _originTextileLongitude
    ) public onlyTextile {
        // Add the new item as part of Acquisition
        yarnItems[_yarnUpc].sku = sku_cnt;
        yarnItems[_yarnUpc].upc = _yarnUpc;
        yarnItems[_yarnUpc].ownerID = msg.sender;
        yarnItems[_yarnUpc].originTextileID = _originTextileID;
        yarnItems[_yarnUpc].originTextileName = _originTextileName;
        yarnItems[_yarnUpc].originTextileInformation = _originTextileInformation;
        yarnItems[_yarnUpc].originTextileLatitude = _originTextileLatitude;
        yarnItems[_yarnUpc].originTextileLongitude = _originTextileLongitude;
        // Update state
        yarnItems[_yarnUpc].itemState = YarnState.Planned;
        // Increment sku
        sku_cnt = sku_cnt + 1;
        // Emit the appropriate event
        emit YarnPlanned(_yarnUpc);
    }

    // Define a function 'yarnAcquisitionItem' that allows a Textile to mark an item 'Acquired'
    function yarnAcquisitionItem(uint256 _yarnUpc, string calldata _acquisitionNotes)
        public
        onlyTextile
        isPlanned(_yarnUpc)
    {
        // Add the new item as part of Acquisition
        yarnItems[_yarnUpc].ownerID = msg.sender;
        yarnItems[_yarnUpc].acquisitionNotes = _acquisitionNotes;
        // Update state
        yarnItems[_yarnUpc].itemState = YarnState.Acquired;
        // Emit the appropriate event
        emit YarnAcquired(_yarnUpc);
    }

    // Define a function 'yarnAuditItem' that allows a QualityChecker to mark an item 'Audited'
    function yarnAuditItem(uint256 _yarnUpc, string calldata _auditNotes)
        public
        onlyQualityChecker
        isAcquired(_yarnUpc)
    {
        // Add the new item as part of Acquisition
        yarnItems[_yarnUpc].auditNotes = _auditNotes;
        // Update state
        yarnItems[_yarnUpc].itemState = YarnState.Audited;
        // Emit the appropriate event
        emit YarnAudited(_yarnUpc);
    }

    // Define a function 'yarnProcessItem' that allows a Textile to mark an item 'Processed'
    function yarnProcessItem(uint256 _yarnUpc)
        public
        onlyTextile
        isAudited(_yarnUpc)
        // verifyCaller(yarnItems[_yarnUpc].ownerID) // Call modifier to verify caller of this function
    {
        // Update the appropriate fields
        yarnItems[_yarnUpc].itemState = YarnState.Processed;
        // Emit the appropriate event
        emit YarnProcessed(_yarnUpc);
    }

    function fabricCreateItem(
        uint256 _yarnUpc,
        uint256 _productID
    ) public onlyProducer {
        // Add the new item as part of Acquisition
        fabricItems[_yarnUpc].sku = sku_cnt;
        fabricItems[_yarnUpc].upc = _yarnUpc;
        fabricItems[_yarnUpc].productID = _productID;
        fabricItems[_yarnUpc].ownerID = msg.sender;
		// Update state
        fabricItems[_yarnUpc].itemState = FabricState.Created;
        // Increment sku
        sku_cnt = sku_cnt + 1;
        // Emit the appropriate event
        emit FabricCreated(_yarnUpc);
    }

    function fabricCutItem(uint256 _fabricUpc, uint256 _yarnUpc)
        public
        onlyProducer
		verifyCaller(fabricItems[_fabricUpc].ownerID)
    {
		// Take ownership of yarn
		yarnItems[_fabricUpc].ownerID = msg.sender;
		// Cut the '_fabricUpc' fabric with '_yarnUpc' yarn
		fabricYarns[_fabricUpc].push(_yarnUpc);
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.Cutted;
        // Emit the appropriate event
        emit FabricCutted(_fabricUpc, _yarnUpc);
    }

	function fabricProduceItem(uint256 _fabricUpc, string calldata _productNotes, uint256 _productPrice)
        public
        onlyProducer
		verifyCaller(fabricItems[_fabricUpc].ownerID)
		isCutted(_fabricUpc)
    {
        fabricItems[_fabricUpc].producerID = msg.sender;
        fabricItems[_fabricUpc].productNotes = _productNotes;
        fabricItems[_fabricUpc].productPrice = _productPrice;
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.Produced;
        // Emit the appropriate event
        emit FabricProduced(_fabricUpc);
    }

	function fabricCertifyItem(uint256 _fabricUpc, string calldata _certifyNotes)
        public
        onlyQualityChecker
		isProduced(_fabricUpc)
    {
		fabricItems[_fabricUpc].certifyNotes = _certifyNotes;
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.Certified;
        // Emit the appropriate event
        emit FabricCertified(_fabricUpc);
    }

	function fabricPackItem(uint256 _fabricUpc)
        public
        onlyProducer
		verifyCaller(yarnItems[_fabricUpc].ownerID)
		isCertified(_fabricUpc)
    {
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.Packed;
        // Emit the appropriate event
        emit FabricPacked(_fabricUpc);
    }

	function fabricSellItem(uint256 _fabricUpc)
        public
        onlyConsumer
		isPacked(_fabricUpc)
    {
        fabricItems[_fabricUpc].consumerID = msg.sender;
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.ForSale;
        // Emit the appropriate event
        emit FabricForSale(_fabricUpc);
    }

	function fabricBuyItem(uint256 _fabricUpc)
        public
		payable
        onlyConsumer
		isForSale(_fabricUpc)
		paidEnough(fabricItems[_fabricUpc].productPrice)
		checkValue(_fabricUpc)
    {
		fabricItems[_fabricUpc].ownerID = msg.sender;
        fabricItems[_fabricUpc].consumerID = msg.sender;
		// Update state
        fabricItems[_fabricUpc].itemState = FabricState.Purchased;
        // Transfer money to producer
        uint256 price = fabricItems[_fabricUpc].productPrice;
        payable(fabricItems[_fabricUpc].producerID).transfer(price);
        // Emit the appropriate event
	    emit FabricPurchased(_fabricUpc);
    }

    // Functions to fetch data
    function fetchFabricItemBufferOne(uint256 _fabricUpc)
        external
        view
        returns (
			uint256 sku,
			uint256 upc,
			address ownerID,
			uint256 productID,
			string memory productNotes,
			uint256 productPrice,
			address producerID,
			address consumerID,
			string memory certifyNotes,
			uint256[] memory yarns,
			uint256 itemState
        )
    {
			sku			= fabricItems[_fabricUpc].sku;
			upc			= fabricItems[_fabricUpc].upc;
			ownerID		= fabricItems[_fabricUpc].ownerID;
			productID		= fabricItems[_fabricUpc].productID;
			productNotes	= fabricItems[_fabricUpc].productNotes;
			productPrice	= fabricItems[_fabricUpc].productPrice;
			producerID		= fabricItems[_fabricUpc].producerID;
			consumerID		= fabricItems[_fabricUpc].consumerID;
			certifyNotes	= fabricItems[_fabricUpc].certifyNotes;
			yarns			= fabricYarns[_fabricUpc];
			itemState		= uint256(fabricItems[_fabricUpc].itemState);
        return (
			sku,
			upc,
			ownerID,
			productID,
			productNotes,
			productPrice,
			producerID,
			consumerID,
			certifyNotes,
			yarns,
			itemState
        );
    }

    // Functions to fetch data
    function fetchYarnItemBufferOne(uint256 _yarnUpc)
        public
        view
        returns (
			uint256 sku,
			uint256 upc,
			address ownerID,
			address originTextileID,
			string memory originTextileName,
			string memory originTextileInformation,
			string memory originTextileLatitude,
			string memory originTextileLongitude
        )
    {
			sku			= yarnItems[_yarnUpc].sku;
			upc			= yarnItems[_yarnUpc].upc;
			ownerID			= yarnItems[_yarnUpc].ownerID;
			originTextileID	= yarnItems[_yarnUpc].originTextileID;
			originTextileName	= yarnItems[_yarnUpc].originTextileName;
			originTextileInformation	= yarnItems[_yarnUpc].originTextileInformation;
			originTextileLatitude		= yarnItems[_yarnUpc].originTextileLatitude;
			originTextileLongitude		= yarnItems[_yarnUpc].originTextileLongitude;
        return (
			sku,
			upc,
			ownerID,
			originTextileID,
			originTextileName,
			originTextileInformation,
			originTextileLatitude,
			originTextileLongitude
        );
    }


    // Functions to fetch data
    function fetchYarnItemBufferTwo(uint256 _yarnUpc)
        public
        view
        returns (
			string memory acquisitionNotes,
			string memory auditNotes,
			uint256 itemState
        )
    {
			acquisitionNotes	= yarnItems[_yarnUpc].acquisitionNotes;
			auditNotes		= yarnItems[_yarnUpc].auditNotes;
			itemState 		= uint256(yarnItems[_yarnUpc].itemState);
        return (
			acquisitionNotes,
			auditNotes,
			itemState
        );
    }

}