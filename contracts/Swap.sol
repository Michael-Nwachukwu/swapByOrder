// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Swap is ReentrancyGuard {

    using SafeERC20 for IERC20;

    /**
     * @dev Custom Errors - covering invalid scenarios
     * `ZeroValueNotAllowed()`: Reverts if a zero value is passed.
     * `AddressZeroDetected()`: Reverts if an address zero is detected.
     * `InsufficientBalance()`: Reverts if the user's balance is insufficient.
     * `InvalidOrderId()`: Reverts if an invalid order ID is passed.
     * `TransactionCompleted()`: Reverts if a transaction is already completed.
     * `SellerisBuyer()`: Reverts if the seller is also the buyer.
     * `usernOTowner()`: Reverts if the user is not the owner of the order.
     * `OrderNotActive()`: Reverts if the order is not active.
     * `InvalidOrder()`: Reverts if the order is invalid.
    */
    error ZeroValueNotAllowed();
    error AddressZeroDetected();
    error InsufficientBalance();
    error InvalidOrderId();
    error TransactionCompleted();
    error SellerisBuyer();
    error usernOTowner();
    error OrderNotActive();
    error InvalidOrder();

    uint256 orderId;

    // Order properties
    struct Order {
        uint256 id;
        address maker;
        address sellToken;
        address buyToken;
        uint256 sellAmount;
        uint256 buyAmount;
        bool isOrderActive;
    }

    mapping (uint256 => Order) orders; // Tracks orders
    mapping (address => uint256[]) aUsersOrder; // Track a user's orders

    event OrderCreated(address user, uint256 amount, uint256 orderId);
    event OrderCancelled(uint256 orderId);
    event Orderfilled(uint256 orderId);

    /**
     * @dev Creates a new order by depositing the sell token and specifying the buy token and amount.
     *
     * @param _sellToken The token to be sold.
     * @param _buyToken The token to be bought.
     * @param _amount The amount of tokens to be sold.
    */
    function createOrder(address _sellToken, address _buyToken, uint256 _amount) external nonReentrant {

        if (msg.sender == address(0)) revert AddressZeroDetected();
        if (_amount <= 0) revert ZeroValueNotAllowed();
        if (_sellToken == address(0)) revert AddressZeroDetected();
        if (_buyToken == address(0)) revert AddressZeroDetected();
        uint256 _userBalance = IERC20(_sellToken).balanceOf(msg.sender);
        if (_userBalance < _amount) revert InsufficientBalance();

        IERC20(_sellToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _orderId = orderId + 1;
        Order storage order = orders[_orderId];

        order.id = _orderId;
        order.maker = msg.sender;
        order.sellToken = _sellToken;
        order.buyToken = _buyToken;
        order.sellAmount = _amount;
        order.buyAmount = _amount;
        order.isOrderActive = true;

        orderId++;

        emit OrderCreated(msg.sender, _amount, _orderId);
    }

    /**
     * @dev Fills an existing order by transferring the buy token to the seller and receiving the sell token.
     *
     * @param _orderId The ID of the order to be filled.
    */
    function fillOrder(uint256 _orderId) external nonReentrant {
        if (msg.sender == address(0)) revert AddressZeroDetected();
        Order storage order = orders[_orderId];
        if (msg.sender == order.maker) revert SellerisBuyer();
        if (_orderId > orderId) revert InvalidOrder();

        uint256 _userBalance = IERC20(order.buyToken).balanceOf(msg.sender);
        if (_userBalance < order.buyAmount) revert InsufficientBalance();

        // Transfer buy tokens from buyer to seller
        IERC20(order.buyToken).safeTransferFrom(msg.sender, order.maker, order.buyAmount);

        // Transfer sell tokens from contract to buyer
        IERC20(order.sellToken).safeTransfer(msg.sender, order.sellAmount);

        // Mark order as inactive
        order.isOrderActive = false;

        emit Orderfilled(_orderId);
        
    }

    /**
     * @dev Cancels an existing order by transferring the sell token back to the seller.
     *
     * @param _orderId The ID of the order to be cancelled.
    */
    function cancelOrder(uint256 _orderId) external nonReentrant {

        Order storage order = orders[_orderId];
      
        if (!order.isOrderActive)revert OrderNotActive();
        if (order.maker != msg.sender) revert usernOTowner();

        // Transfer sell tokens back to seller
        IERC20(order.sellToken).safeTransfer(order.maker, order.buyAmount);

        // Mark order as inactive
        order.isOrderActive = false;

        emit OrderCancelled(_orderId);
    }

    /**
     * @dev Returns an array of orders created by the current user.
     *
     * @return An array of orders.
    */
    function getUsersOrder() external view returns (Order[] memory) {

        uint256[] memory orderIds = aUsersOrder[msg.sender];
        Order[] memory userOrders = new Order[](orderIds.length);

        for (uint256 i = 0; i < orderIds.length; i++) {
            userOrders[i] = orders[orderIds[i]];
        }

        return userOrders;
    }

}