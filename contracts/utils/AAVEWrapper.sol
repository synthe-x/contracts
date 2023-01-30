// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AAVEWrapper
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice This contracts wraps self compounding tokens, as specified for aTokens in Aave protocol
 * @notice https://docs.aave.com/developers/tokens/atoken
 */
contract AAVEWrapper is ERC20 {
    IERC20 public underlying;

    constructor(string memory _name, string memory _symbol, IERC20 _underlying) ERC20(_name, _symbol) {
        underlying = _underlying;
    }

    function exchangeRate() public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : underlying.balanceOf(address(this)) * 1e18 / totalSupply();
    }

    function amountToShares(uint256 amount) public view returns (uint256) {
        return amount * 1e18 / exchangeRate();
    }

    function sharesToAmount(uint256 shares) public view returns (uint256) {
        return shares * exchangeRate() / 1e18;
    }

    function deposit(uint256 amount) public {
        underlying.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amountToShares(amount));
    }

    function withdraw(uint256 shares) public {
        uint256 amount = sharesToAmount(shares);
        _burn(msg.sender, shares);
        underlying.transfer(msg.sender, amount);
    }
}