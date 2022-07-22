pragma solidity ^0.8.11;
import"@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
 contract ECommerce is ERC20,Ownable{

    constructor()
    ERC20("E-COMMERCE Inu","EINU")
    {     
     
    }
    // USING SAFEMATH FOR ARITHMETIC OPERATIONS
    using SafeMath for uint;
    //STRUCT TO CONTAIN VALUES FOR ITEMS
    struct Item{
        address owner;
        string name;
        uint256 listingprice;
        uint256 listingduration; 
        string description;
        bool sold;
    }
    struct Profile{
        address owner;
        string nickname;
        uint256 TokensRecieved;
        uint256 ETHRecieved;
        uint8 ItemsListed;
        uint8 ItemsSold;
        uint8 ItemsNotSold; 
    }
    //VARIABLES NAMES SHOULD EXPLAIN WHAT THEY MEAN
    uint private Itemcount = 1;
    uint private Itemsold;
    uint private Itemsforsale;
    uint private numberofItems;
    uint private rate = 40000000000000;
    uint private Etherfees;
    uint private Tokenfees;
    uint private listingEtherPrice = 0.01 ether;
    uint private listingTokenAmount = 250;
    
    //MAPPING TO KEEP TRACK OF USERS PROFILE
    mapping(address => Profile)profile;
    //MAPPING TO KKEP TRACK OF ITEMS ID LISTED BY USERS
    mapping(address => uint[])UserItemsListed;
    //MAPPING TO KEEP TRACK OF ITEMLIST
    mapping(uint => Item)ItemList;
    //MAPPING TO KEEP TRACK OF ADDRESS OF ITEM LISTER FOR PAYMENT 
    mapping(uint => address)Lister;
    //MAPPING TO KEEP TRACK OF ITEMS OWNED
    mapping(address => uint)ItemsOwned;
    //MAPPING TO KEEP TRACK OF PAID FEES IN ETH
    mapping(address => uint)PaidEtherFee;
    //MAPPING TO KEEP TRACK OF PAID FEES IN TOKENS
    mapping(address => uint)PaidTokenFee;
    //MAPPING TO KEEP TRACK OF FEES PAID FOR EVERY ITEM 
    mapping(uint => mapping(address =>bool))feePaid;
    //MAPPING TO KEEP TRACK OF ITEMS PAID FOR BY USER
    mapping(uint => mapping(address =>bool))PaidItem;
     
     //FUNCTION TO LIST AN ITEM IT REQUIRES FOUR ARGUMENTS NECESSARY TO LIST THE ITEM
    function ListItem(string memory _name,uint _price,uint _duration,string memory _description,string memory _nickname)external returns(bool success){
        require(feePaid[Itemcount][msg.sender] == true,"You have not paid the listing fee");
        require(_price != 0,"Price cannot be set to 0");
        require(_duration.add(block.timestamp) > block.timestamp,"Duration must be greater than current time");
        ItemList[Itemcount].owner = msg.sender;
        ItemList[Itemcount].name = _name;
        ItemList[Itemcount].listingprice = _price;
        ItemList[Itemcount].listingduration = _duration .add(block.timestamp);
        ItemList[Itemcount].description = _description;
        Lister[Itemcount] = msg.sender;
        profile[msg.sender].owner = msg.sender;
        profile[msg.sender].nickname = _nickname;
        profile[msg.sender].ItemsListed++;
        UserItemsListed[msg.sender].push(Itemcount);
        Itemsforsale++;
        numberofItems++;
        Itemcount++;
        return true;
    }
    
    //FUNCTION TO PAY FEE IN ETH
    function PayFeeETH()external payable returns(bool success){
        require(msg.value == listingEtherPrice,"You must pay exactly 0.01 Ether");
        require(feePaid[Itemcount][msg.sender] == false,"You have already paid a fee");
        Etherfees = Etherfees.add(msg.value);
        PaidEtherFee[msg.sender] = PaidEtherFee[msg.sender].add(msg.value);
        feePaid[Itemcount][msg.sender] = true;
        return true;
    }
      
      //FUNCTION TO PAY FEE IN TOKENS
     function PayFeeToken()external returns(bool success){
        require(TokensBalance() >= listingTokenAmount,"You must have 250 Tokens or more");
        require(feePaid[Itemcount][msg.sender] == false,"You have already paid a fee");
        _mint(address(this),listingTokenAmount);
        _burn(msg.sender,listingTokenAmount);
        Tokenfees = Tokenfees.add(listingTokenAmount);
        PaidTokenFee[msg.sender] = PaidTokenFee[msg.sender].add(listingTokenAmount);
        feePaid[Itemcount][msg.sender] = true;
        return true;
    }
     
     //FUNCTION TO SEARCH ITEMS
    function SearchItem(uint id)external view returns(address owner_,string memory name_,uint price_,uint duration_,string memory description_,bool sold_){
       require(ItemList[id].owner != address(0),"Item does not exist");
       owner_ = ItemList[id].owner;
       name_ = ItemList[id].name; 
       price_ = ItemList[id].listingprice;
       duration_ = ItemList[id].listingduration;
       description_ = ItemList[id].description;
       sold_ = ItemList[id].sold;
    }
      
      //INTERNAL FUNCTION TO KEEP TRACK OF EXPIRED ITEMS AND REMOVE THEM FROM ITEMSFOR SALE
     function Checker(uint id)internal returns(bool success){
        if(ItemList[id].listingduration >= block.timestamp){
            profile[Lister[id]].ItemsNotSold++;
            Itemsforsale--;
            return true;
        }
    }
     
     //FUNCTION TO BUY ITEM IN ETH
     function BuyItemETH(uint id)external payable returns(bool success){
     Checker(id);
     require(ItemList[id].listingduration >= block.timestamp,"Listing Time exceeded");
     require(id != 0 ,"No such Item exists");
     require(ItemList[id].sold == false,"Item has been bought");
     require((msg.sender).balance >= ItemList[id].listingprice,"Insufficient Balance");
     require(msg.value == ItemList[id].listingprice,"Input the Exact Amount");
     payable(Lister[id]).transfer(msg.value);
     profile[Lister[id]].ETHRecieved = profile[Lister[id]].ETHRecieved.add(msg.value);
     profile[Lister[id]].ItemsSold++;
     ItemsOwned[msg.sender]++;
     ItemList[id].owner = msg.sender;
     PaidItem[id][msg.sender] = true;
     ItemList[id].sold = true;
     Itemsold++;
     Itemsforsale--;
     return true;
    }
     function BuyTokens()external payable returns(bool success){
        require(rate != 0,"Rate has not been set");
        require(msg.value != 0,"You cannot send nothing");
        uint bought = msg.value.div(rate);
        uint fee = (bought.mul(10)).div(100);
        uint recieve = bought.sub(fee);
        bought = msg.value.div(rate);
        _mint(msg.sender,recieve);
        _mint(address(this),fee);
        return true;
    }

     function SellTokens(uint amount)external returns(bool success){
        uint sold = amount.mul(rate);
        uint fee = (amount.mul(10)).div(100);
        uint recieve = sold.sub(fee);
        uint UserBalance = balanceOf(msg.sender);
        require(amount != 0,"You cannot sell nothing");
        require(UserBalance >= amount,"Insufficient Amount Of Tokens");
        require(rate != 0,"Rate has not been set");
        require(address(this).balance >= sold,"Insufficient Cash");
        _burn(msg.sender,amount);
        _mint(address(this),fee);
        payable(msg.sender).transfer(recieve);
        return true;
    }
  

    //FUNCTION TO BUY ITEM IN TOKENS
      function BuyItemToken(uint id)external returns(bool success){
     Checker(id);
     uint price = ItemList[id].listingprice.div(rate);
     require(ItemList[id].listingduration >= block.timestamp,"Listing Time exceeded");
     require(id != 0 ,"No such Item exists");
     require(ItemList[id].sold == false,"Item has been bought");
     require(TokensBalance() >= price,"Insufficient Token Balance");
     _mint(Lister[id],price);
     _burn(msg.sender,price);
     profile[Lister[id]].TokensRecieved= profile[Lister[id]].TokensRecieved.add(price);
     profile[Lister[id]].ItemsSold++;
     ItemsOwned[msg.sender]++;
     ItemList[id].owner = msg.sender;
     PaidItem[id][msg.sender] = true;
     ItemList[id].sold = true;
     Itemsold++;
     Itemsforsale--;
     return true;
    }
         //FUNCTION TO VIEW PROFILE OF USER
    function ViewProfile(address _user)external view returns(address _owner,string memory _nickname,uint256 _TokensRecieved,uint256 _ETHRecieved,uint8 _ItemsListed,uint8 _ItemsSold,uint8 _ItemsNotSold)
    {   
        require(profile[_user].owner != address(0),"User does not exist");
        _owner = profile[_user].owner;
        _nickname = profile[_user].nickname;
        _TokensRecieved = profile[_user].TokensRecieved;
        _ETHRecieved = profile[_user].ETHRecieved;
        _ItemsListed = profile[_user].ItemsListed;
        _ItemsSold = profile[_user].ItemsSold;
        _ItemsNotSold = profile[_user].ItemsNotSold;  
    }
    //FUNCTION TO VIEW ITEM PRICE IN ETH
    function ViewItemPriceETH(uint id)external view returns(uint){
    return ItemList[id].listingprice;
    }
      //FUNCTION TO VIEW ITEM PRICE IN TOKENS
    function ViewItemPriceTokens(uint id)external view returns(uint){
    return ItemList[id].listingprice.div(rate);
    }
     
     //FUNCTION TO REVEAL ITEMLISTING FEE IN ETH
    function ReturnListingETHFee()external view returns(uint){
        return listingEtherPrice;
    }
     //FUNCTION TO REVEAL ITEMLISTING FEE IN TOKENS
    function ReturnListingTokenFee()external view returns(uint){
        return listingTokenAmount;
    }
    
    //FUNCTION TO REVEAL NUMBER OF ITEMS OWNED
    function ReturnNumofItemsOwned()external view returns(uint){
        return ItemsOwned[msg.sender];
    }
     
     //FUNCTION TO WITHDRAW ETH ONLY OWNER CAN USE
    function Withdraw(address payable _to,uint amount)external returns(bool success){
        require(msg.sender == owner,"Unauthorized Access");
        require(amount <= address(this).balance,"Insufficient Ether");
        _to.transfer(amount);
        return true;
    }
     //FUNCTION TO TRANSFER TOKENS ONLY OWNER CAN USE
    function TokenTransfer(address _to,uint amount)external returns(bool success){
         require(msg.sender == owner,"Unauthorized Access");
         require(EcommerceTokenBalance() >= amount,"Insufficient Token Balance");
         _burn(address(this),amount);
         _mint(_to,amount);
         return true;
    }
    
    //FUNCTION TO REVEAL THE ITEM ID LISTED BY USERS
    /********* REVEAL THIS SHITTY CODE */
    function UserItems(address user)public view returns(uint[]memory){
        return UserItemsListed[user];
    }
  
    //FUNCTION TO CHECK ECOMMERCE ETH BALANCE
    function EcommerceETHBalance()public view returns(uint){
        return address(this).balance;
    }
    //FUNCTION TO CHECK TOKEN BALANCE OF USER
    function TokensBalance()public view returns(uint){
        return balanceOf(msg.sender);
    }
    //FUNCTION TO CHECK ECOMMERCE TOKEN BALANCE
    function EcommerceTokenBalance()public view returns(uint){
        return balanceOf(address(this));
    }
    //FUNCTION TO CHECK NUMBER OF ITEMS LISTED
    function ReturnNumberOfItems()public view returns(uint){
        return numberofItems;
    }
    //FUNCTION TO CHECK NUMBER OF ITEMS SOLD
    function ReturnNumberOfItemsSold()public view returns(uint){
        return Itemsold;
    }
    //FUNCTION TO CHECK NUMBER OF ITEMS ON SALE
    function ReturnNumberOfItemsOnSale()public view returns(uint){
        return Itemsforsale;
    } 

    /*********TODO*
    TODO
    ITEMS SOLD AND NOT SOLD ISSUE 
    WHEN USER LISTES 2 ITEM ONE ITEM IS SOLD THE OTHER IS MARKED AS NOT SOLD/

    

    }

// 1 ETH = 1000000000000000000

// 0.01 ETH = 10000000000000000