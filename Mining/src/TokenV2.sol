// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


contract ReceiveHelper {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    constructor() {
        IERC20(USDT).approve(msg.sender, type(uint256).max);
    }
}

contract TokenV2 is ERC20, Ownable{
    IUniswapV2Router02 public immutable pancakeRouter;
    address public immutable pancakePair;
    address public immutable receiveHelper;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) public isExemptFromTax;
    mapping(address => bool) public subscribelist;
    mapping(address => address) public lpOriginalOwner;


    mapping(address => uint256) private holderIndex;
    address[] public holders;

    address public exceedTaxWallet;
    address public mining;
    uint256 public atTheOpeningOrder;
    uint256 public txFee;
    uint256 private currentIndex;
    
    uint256 public constant MAX_BUY_USDT = 500e18;

    uint256 public MIN_PROCESS_AWARD = 1300e18;
    uint256 public MIN_LIQUIDITY = 50e18;
    uint256 public MIN_ADD_LIQUIDITY = 100e18;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet
    ) ERC20(_name, _symbol) {
        _mint(_initialRecipient, 100_000_000e18);
        pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakePair = IUniswapV2Factory(pancakeRouter.factory()).createPair(address(this), USDT);

        exceedTaxWallet = _exceedTaxWallet;
        receiveHelper = _deployHelper();

        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[address(this)] = true;
        isExemptFromTax[msg.sender] = true;
    }

    modifier onlyMining() {
        require(msg.sender == mining, "NOT PERMITTED");
        _;
    }

    function mint(address to, uint256 amount) external onlyMining {
        _mint(to, amount);
    }

    function _deployHelper() internal returns (address helper) {
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        bytes memory bytecode = type(ReceiveHelper).creationCode;
        assembly {
            helper := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }

    function setAtTheOpeningOrder() external onlyOwner {
        atTheOpeningOrder = block.timestamp;
    }

    function setLimitConfig(uint256 _minLiquidity,uint256 _minProcessAward, uint256 _minAddLiquidity) external onlyOwner {
        MIN_LIQUIDITY = _minLiquidity;
        MIN_PROCESS_AWARD = _minProcessAward;
        MIN_ADD_LIQUIDITY = _minAddLiquidity;
    }

    function setMining(address _mining) external onlyOwner {
        require(_mining != address(0), "Mining address cannot be zero");
        mining = _mining;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            require(_addrs[i] != address(0), "ZERO ADDRESS");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }

    function setExceedTaxWallet(address _exceedTaxWallet) external onlyOwner {
        require(_exceedTaxWallet != address(0), "Exceed tax wallet cannot be zero");
        exceedTaxWallet = _exceedTaxWallet;
    }

    function setSubscribeList(address[] calldata _addrs, bool _sub) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            require(_addrs[i] != address(0), "ZERO ADDRESS");
            subscribelist[_addrs[i]] = _sub;
        }
    }

    function calculateTaxes(address from, uint256 amount) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - atTheOpeningOrder;

        // If atTheOpeningOrder is not set (i.e., is 0), normal users are not allowed to buy
        if (atTheOpeningOrder == 0) {
            require(isExemptFromTax[from], "Opening not set, only exempt addresses can buy.");
        }

        // Limit purchase to 500 USDT for non-exempt addresses in the first 5 minutes
        if (elapsed < 5 minutes && !isExemptFromTax[from]) {
            if(IERC20(pancakePair).totalSupply()>0){
                uint256 usdtAmount = getAmountOutUSDT(amount);
                require(usdtAmount <= MAX_BUY_USDT, "Purchase exceeds 500 USDT limit.");
            }  
        }

        // After 30 minutes, switch to 3.5% tax
        if (elapsed >= 30 minutes) {
            return 35;  // 3.5% tax
        }

        // During the first 30 minutes, apply 10% tax
        return 100;  // 10% tax
    }



    function _isAddLiquidityV2() internal  view returns (bool, uint256) {
        (uint r0, uint r1,) = IUniswapV2Pair(pancakePair).getReserves();
        address token0 = IUniswapV2Pair(pancakePair).token0();
        address token1 = IUniswapV2Pair(pancakePair).token1();
        uint bal0 = IERC20(token0).balanceOf(pancakePair);
        uint bal1 = IERC20(token1).balanceOf(pancakePair);
        
        bool ldxAdd;
        uint256 otherAmount;
        if (token0 == address(this)) {
            // 当前代币是 token0，对比余额与储备
            if (bal1 > r1) {
                otherAmount = bal1 - r1;
                ldxAdd = otherAmount >= 1e18;
            }
        } else {
            // 当前代币是 token1
            if (bal0 > r0) {
                otherAmount = bal0 - r0;
                ldxAdd = otherAmount >= 1e18;
            }
        }
        return (ldxAdd, otherAmount);
    }


    function _isDelLiquidityV2()internal view returns(bool ldxDel, bool bot, uint256 otherAmount){

        address token0 = IUniswapV2Pair(address(pancakePair)).token0();
        (uint reserves0,,) = IUniswapV2Pair(address(pancakePair)).getReserves();
        uint amount = IERC20(token0).balanceOf(address(pancakePair));
		if(token0 != address(this)){
			if(reserves0 > amount){
				otherAmount = reserves0 - amount;
				ldxDel = otherAmount >= 10**13;
			}else{
				bot = reserves0 == amount;
			}
		}
    }


    event DebugAddLiquidity(address from, address to, uint256 amount, bool isAdd);
    event DebugDelLiquidity(address from, address to, uint256 amount, bool isDel);

    function _transfer(address from, address to, uint256 value) internal override{

        if (from == address(0) || to == address(0)) {
            super._transfer(from, to, value);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];
        
        // === 检测添加流动性 ===
        (bool isAdd, ) = _isAddLiquidityV2();
        if (isAdd && to == pancakePair) {
            if (isAdd && to == pancakePair) {
                if (lpOriginalOwner[from] == address(0)) {
                    lpOriginalOwner[from] = from;   
                }
            }

        }

        emit DebugAddLiquidity(from, to, value, isAdd);
        
        // === 检测移除流动性 ===
        (bool isDel,,) = _isDelLiquidityV2();
        if (isDel && from == pancakePair) {

            if (subscribelist[to]) {
                // 订阅地址：移除 LP 时 100% 销毁
                super._transfer(to, DEAD, value);
                return;
            } else {
                // 非订阅地址：必须是初始添加者
                require(lpOriginalOwner[to] == to, "Not original LP provider");
            }
        }
        emit DebugDelLiquidity(from, to, value, isDel);

        uint256 taxAmount = 0;
        if(isExchange && !takeTax) taxAmount = value * calculateTaxes(from, value) / 1000;

        if(taxAmount > 0){
            uint256 baseSwapFee = value * 35 / 1000;
            if(taxAmount > baseSwapFee) super._transfer(from, exceedTaxWallet, taxAmount - baseSwapFee);
            super._transfer(from, DEAD, value * 5 / 1000);
            super._transfer(from, address(this), value * 3 / 100);
            super._transfer(from, to, value - taxAmount);
            txFee += value * 1 / 100;
        }else{
            super._transfer(from, to, value);
        }

        if (!isExchange) _swapAndAdd();

        updateHolder(from);
        updateHolder(to);
        try this.process(isExchange, 50000) {} catch {}
    }


    function _swapAndAdd() private {
        if (txFee < MIN_ADD_LIQUIDITY) return;

        try this._safeSwapAndAdd() {
            txFee = 0; 
        } catch {

        }
    }

    function _safeSwapAndAdd() external {
        require(msg.sender == address(this), "FORBIDDEN"); // 只允许内部调用
        uint256 oneHalf = txFee / 2;
        _swapTokensForUSDT(oneHalf);
        uint256 usdtAmount = IERC20(USDT).balanceOf(receiveHelper);
        if (usdtAmount > 0) {
            IERC20(USDT).transferFrom(receiveHelper, address(this), usdtAmount);
            _addLiquidity(txFee - oneHalf, usdtAmount);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);
        IERC20(USDT).approve(address(pancakeRouter), usdtAmount);
        pancakeRouter.addLiquidity(address(this), USDT, tokenAmount, usdtAmount, 0, 0, DEAD, block.timestamp);
    }

    function _swapTokensForUSDT(uint256 amount) private {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        _approve(address(this), address(pancakeRouter), amount);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, receiveHelper, block.timestamp);
    }

    function getLpUsdtValue(uint256 lpAmount) public view returns(uint256){
		uint256 pairTotalAmount = IUniswapV2Pair(pancakePair).totalSupply();
        if(pairTotalAmount == 0) return 0;
		(uint256 pairUSDTAmount,,) = IUniswapV2Pair(pancakePair).getReserves();
		uint256 lpUsdtValue = lpAmount * pairUSDTAmount / pairTotalAmount;
		return lpUsdtValue;
	}

    function updateHolder(address user) private {
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        if (size > 0 || user == DEAD) {
            return;
        }

        uint256 idx = holderIndex[user];
        bool isHolder = (holders.length > 0 && holders[idx] == user);
        uint256 lpUsdtValue = getLpUsdtValue(IERC20(pancakePair).balanceOf(user));
        if (lpUsdtValue >= MIN_LIQUIDITY) { 
            if (!isHolder) {
                holderIndex[user] = holders.length;
                holders.push(user);
            }
        } else { 
            if (isHolder) {
                address lastHolder = holders[holders.length - 1];
                holders[idx] = lastHolder;
                holderIndex[lastHolder] = idx;
                holders.pop();
                delete holderIndex[user];
            }
        }
    }


    function updateMyStatus() external {
        updateHolder(msg.sender);
    }

    function process(bool isExchange, uint256 gas) external {
        require(msg.sender == address(this), "FORBIDDEN"); // 只允许内部调用
        if (isExchange) return;
        uint256 totalLP = IERC20(pancakePair).totalSupply();
        uint256 dividendFee = balanceOf(address(this)) - txFee;

        if (totalLP == 0 || dividendFee < MIN_PROCESS_AWARD) return;

        uint256 shareholderCount = holders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) currentIndex = 0;
            address shareholder = holders[currentIndex];
            uint256 lpBalance = IERC20(pancakePair).balanceOf(shareholder);

            if (lpBalance > 0) {
                uint256 amount = (dividendFee * lpBalance) / totalLP;
                if (amount > 0 && balanceOf(address(this)) - txFee > amount) {
                    super._transfer(address(this), shareholder, amount);
                }
            }

            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function getAmountOutUSDT(uint256 tokenAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);
        uint[] memory amounts = pancakeRouter.getAmountsIn(tokenAmount, path);
        return amounts[0];
    }

    function getHolders() external view returns (address[] memory) {
        return holders;
    }

}
