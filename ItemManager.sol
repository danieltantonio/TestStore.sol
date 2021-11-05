pragma solidity ^0.8.7;

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "You are not the owner");
        _;
    }
}

contract Item {
    uint index;
    uint quantity;
    uint priceInWei;
    address owner;
    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index, uint _quantity) {
        parentContract = _parentContract;
        priceInWei = _priceInWei;
        quantity = _quantity;
        owner = msg.sender;
        index = _index;
    }

    function subQuantity(uint _remove) public {
        quantity -= _remove;
    }
}

contract ItemManager is Ownable {
    uint itemIndex;

    enum ItemStatus{ Created, Paid, Delivered }

    struct S_Item {
        Item _item;
        uint _price; // In Wei
        uint _quantity;
        address _owner;
        string _identifier;
        ItemManager.ItemStatus _status;
    }

    mapping(uint => S_Item) public items; // Supply Item
    mapping(address => uint) public getItemIndex; // Find index in supply by Item Address

    event itemStatus(uint _index, uint _step, address _itemAddress);

    function createItem(string memory _identifier, uint _price, uint _quantity) public {
        require(_quantity >= 1, "You need to have 1 or more of this item to list it on store.");

        Item item = new Item(this, _price, itemIndex, _quantity);
        address itemAddr = address(items[itemIndex]._item);

        items[itemIndex]._item = item;
        items[itemIndex]._price = _price;
        items[itemIndex]._owner = msg.sender;
        items[itemIndex]._quantity = _quantity;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._status = ItemStatus.Created;

        getItemIndex[itemAddr] = itemIndex;

        itemIndex++;
        emit itemStatus(itemIndex, uint(items[itemIndex]._status), itemAddr);
    }

    function purchaseItem(uint _itemIndex, uint _quantity) public payable {
        require(_quantity >= 1, "You need 1 or more in quantity to buy item.");
        require(_quantity <= items[_itemIndex]._quantity, "Not enough in stock, please lower emount.");
        require(msg.value == (items[_itemIndex]._price * _quantity), "Must pay specified price only.");

        Item item = items[_itemIndex]._item;

        items[_itemIndex]._status = ItemStatus.Paid;
        items[_itemIndex]._quantity -= _quantity;
        item.subQuantity(_quantity);

        _owner.call{value: msg.value}("");
        emit itemStatus(_itemIndex, uint(items[_itemIndex]._status), address(item));
    }

    function editItem(uint _itemIndex, uint _price, uint _quantity) public {
        require(msg.sender == items[_itemIndex]._owner || msg.sender == _owner, "You are not the item owner");
        items[_itemIndex]._price = _price;
        items[_itemIndex]._quantity = _quantity;
    }

    function deliverItem(uint _itemIndex) public {
        require(msg.sender == items[_itemIndex]._owner, "You are not the message owner");
        items[_itemIndex]._status = ItemStatus.Delivered;

        emit itemStatus(_itemIndex, uint(items[_itemIndex]._status), address(items[_itemIndex]._item));
    }
}