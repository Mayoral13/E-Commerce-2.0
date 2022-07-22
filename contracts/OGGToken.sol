pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";
contract OGG is Ownable,ERC20{
    constructor(uint _supply)
    ERC20("Mayoral","OGG"){
        _mint(msg.sender, _supply);
}
}