// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Swap is ReentrancyGuard {

    using SafeERC20 for IERC20;

    error ZeroValueNotAllowed();
    error AddressZeroDetected();
    error InsufficientBalance();
    error InvalidOrderId();
    error TransactionCompleted();

    uint256 orderId;

    struct Order {
        address maker;
        address sellToken;
        address buyToken;
        uint256 sellAmount;
        uint256 buyAmount;
        bool isOrderActive;
    }

    mapping (uint256 => Order) orders;
    // Track a user's orders
    mapping (address => mapping (uint256 => Order)) userOrder; 

    event OrderCreated(address user, uint256 amount, uint256 orderId);

    function deposit(address _sellToken, address _buyToken, uint256 _amount) external nonReentrant {

        if (msg.sender == address(0)) revert AddressZeroDetected();
        if (_amount <= 0) revert ZeroValueNotAllowed();
        if (_sellToken == address(0)) revert AddressZeroDetected();
        if (_buyToken == address(0)) revert AddressZeroDetected();
        uint256 _userBalance = IERC20(_sellToken).balanceOf(msg.sender);
        if (_userBalance < _amount) revert InsufficientBalance();

        IERC20(_sellToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _orderId = orderId + 1;
        Order storage order = orders[_orderId];

        order.maker = msg.sender;
        order.sellToken = _sellToken;
        order.buyToken = _buyToken;
        order.sellAmount = _amount;
        order.buyAmount = _amount;
        order.isOrderActive = true;

        emit OrderCreated(msg.sender, _amount, _orderId);
    }

}