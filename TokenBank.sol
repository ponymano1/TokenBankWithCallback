// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRecipient {
    function tokenRecived(address _from, address _to, uint256 _value) external;
}

contract TokenBank is IRecipient{
    using SafeERC20 for IERC20;
    address internal admin;
    IERC20 internal immutable token;
    mapping(address => uint256) internal balances;
    
    error InsufficientBalance(uint256 amount);
    error InvalidAmount(uint256 amount);
    error NotAdministrator();
    error NotTokenAddress();
    
    modifier OnlySufficientBalance(uint256 amount) {
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(amount);
        }
        _; 
    }

    modifier ValidAmount(uint256 amount) {
        if (amount <= 0) {
            revert InvalidAmount(amount);
        }
        _;
    }

    modifier OnlyAdmin(address addr) {
        if (addr != admin) {
            revert NotAdministrator();
        }
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        admin = msg.sender;
    }

    function deposit(uint256 amount) external ValidAmount(amount) {
        balances[msg.sender] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external ValidAmount(amount) OnlySufficientBalance(amount){
        balances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function withdrawAll() public OnlyAdmin(msg.sender) {
         uint256 total = token.balanceOf(address(this));
         token.safeTransfer(admin, total);
    }

    function changeAdmin(address newAdmin) public OnlyAdmin(msg.sender) {
        admin = newAdmin;
    }

    function tokenRecived(address _from,  address _to, uint256 _value) external override {
        if (msg.sender != address(token)) {
            revert NotTokenAddress();
        }
        balances[_from] += _value;
    }
}