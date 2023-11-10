// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ERC20Fallback {
    string private constant _name = "ERC20Fallback";
    string private constant _symbol = "ERC20FB";
    uint8 private constant _decimals = 0;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    bytes4 private constant NAME_SELECTOR = bytes4(keccak256("name()"));
    bytes4 private constant SYMBOL_SELECTOR = bytes4(keccak256("symbol()"));
    bytes4 private constant DECIMALS_SELECTOR = bytes4(keccak256("decimals()"));

    bytes4 private constant TOTAL_SUPPLY_SELECTOR =
        bytes4(keccak256("totalSupply()"));
    bytes4 private constant BALANCE_OF_SELECTOR =
        bytes4(keccak256("balanceOf(address)"));
    bytes4 private constant ALLOWANCE_SELECTOR =
        bytes4(keccak256("allowance(address, address)"));

    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256("transfer(address, uint256)"));
    bytes4 private constant TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("transferFrom(address, address, uint256)"));
    bytes4 private constant APPROVE_SELECTOR =
        bytes4(keccak256("approve(address, uint256)"));

    constructor() {
        _totalSupply = 1000000;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() internal pure returns (string memory) {
        return _name;
    }

    function symbol() internal pure returns (string memory) {
        return _symbol;
    }

    function decimals() internal pure returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() internal view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) internal view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender
    ) internal view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) internal returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) internal returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        uint256 _allowance = _allowed[from][msg.sender];

        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] -= value;
        _balances[to] += value;

        if (_allowance < type(uint256).max) {
            _allowed[from][msg.sender] -= value;
        }
        emit Transfer(from, to, value);
        return true;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        bytes4 selector;
        assembly {
            selector := calldataload(0)
        }

        if (selector == TOTAL_SUPPLY_SELECTOR) {
            return abi.encode(_totalSupply);
        } else if (selector == BALANCE_OF_SELECTOR) {
            address owner = abi.decode(data[4:], (address));
            return abi.encode(_balances[owner]);
        } else if (selector == ALLOWANCE_SELECTOR) {
            (address owner, address spender) = abi.decode(
                data[4:],
                (address, address)
            );
            return abi.encode(_allowed[owner][spender]);
        } else if (selector == TRANSFER_SELECTOR) {
            (address to, uint256 value) = abi.decode(
                data[4:],
                (address, uint256)
            );
            return abi.encode(transfer(to, value));
        } else if (selector == TRANSFER_FROM_SELECTOR) {
            (address from, address to, uint256 value) = abi.decode(
                data[4:],
                (address, address, uint256)
            );
            return abi.encode(transferFrom(from, to, value));
        } else if (selector == APPROVE_SELECTOR) {
            (address spender, uint256 value) = abi.decode(
                data[4:],
                (address, uint256)
            );
            return abi.encode(approve(spender, value));
        } else if (selector == NAME_SELECTOR) {
            return abi.encode(name());
        } else if (selector == SYMBOL_SELECTOR) {
            return abi.encode(symbol());
        } else if (selector == DECIMALS_SELECTOR) {
            return abi.encode(decimals());
        } else {
            revert("Invalid function selector");
        }
    }
}
