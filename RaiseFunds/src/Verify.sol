// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
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

interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}


abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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


interface IUniswapV2Pair {
    function sync() external;
}


interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}



contract Token is ERC20, Ownable{
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public exceedTaxWallet;
    address public nodeDividend;
    address public pancakePair;

    uint256 public openingPoint;
    uint256 public lastBurnTime;
    mapping(address => bool) public isExemptFromTax;
    uint256 public constant MIN_POOL_SUPPLY = 100000000 * 10 ** 18;
    uint256 public MIN_DIVIDEND_LIMIT = 100 * 10 **18;

    address[] public holders;
    mapping(address => uint256) holderIndex;
    uint256 currentIndex;

    constructor(
        string memory _name, 
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        address _nodeDividend
    )ERC20(_name, _symbol)Ownable(msg.sender){
        uint256 initialSupply = 13500000000 * 10 ** decimals();
        _mint(_initialRecipient, initialSupply);
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        exceedTaxWallet = _exceedTaxWallet;
        nodeDividend = _nodeDividend;
        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[_nodeDividend] = true;
        isExemptFromTax[address(this)] = true;
        isExemptFromTax[msg.sender] = true;
    }

    function setAddrConfig(
        address _exceedTaxWallet,
        address _nodeDividend
    ) external onlyOwner {
        require(_exceedTaxWallet != address(0) && _nodeDividend != address(0), "Zero address.");
        exceedTaxWallet = _exceedTaxWallet;
        nodeDividend = _nodeDividend;
    }

    function setMinDividendLimit(uint256 _minDividendLimit) external onlyOwner{
        MIN_DIVIDEND_LIMIT = _minDividendLimit;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        if(pancakePair != address(0) && openingPoint == 0){
            if(IERC20(pancakePair).totalSupply() > 0 ) openingPoint = block.timestamp;
        }

        if(from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];
        uint256 taxAmount = 0;
        if(!takeTax && isExchange) {
            (uint256 _buyTax, uint256 _sellTax) = calculateTaxes();
            require(_buyTax <= 30 && _sellTax <= 30, "Tax too high");
            uint256 taxRate = from == pancakePair ? _buyTax : _sellTax;
            taxAmount = (amount * taxRate) / 100;
        }

        if(taxAmount > 0){
            uint256 baseTaxAmount = (amount * 3) / 100;
            uint256 extraTaxAmount = taxAmount > baseTaxAmount ? taxAmount - baseTaxAmount : 0;
            super._update(from, address(this), baseTaxAmount * 70 / 100);
            super._update(from, nodeDividend, baseTaxAmount * 20 / 100);
            super._update(from, DEAD, baseTaxAmount * 10 / 100);

            if (extraTaxAmount > 0) super._update(from, exceedTaxWallet, extraTaxAmount);
            super._update(from, to, amount - taxAmount);
        }else{
            super._update(from, to, amount);
        }

        safeBurn(isExchange);
        process(isExchange, 50000);

        uint256 senderLpBalance = IERC20(pancakePair).balanceOf(from);
        if (senderLpBalance >= MIN_DIVIDEND_LIMIT) addHolder(from);
        else removeHolder(from);

        uint256 recipientLpBalance = IERC20(pancakePair).balanceOf(to);
        if (recipientLpBalance >= MIN_DIVIDEND_LIMIT) addHolder(to);
        else removeHolder(to);
        
    }


    function safeBurn(bool _isExchange) internal {

        if(pancakePair != address(0) && lastBurnTime == 0){
            if(IERC20(pancakePair).totalSupply() > 0 ) lastBurnTime = block.timestamp;
        }

        if (!_isExchange) {
            uint256 epoch = (block.timestamp - lastBurnTime) / 6 hours;
            if (epoch == 0) return;

            uint256 currentSupply = balanceOf(pancakePair);
            uint256 targetBurnAmount = (currentSupply * epoch) / 100; 
            if(currentSupply > targetBurnAmount && currentSupply - targetBurnAmount >= MIN_POOL_SUPPLY){
                _burn(pancakePair, targetBurnAmount);
                lastBurnTime = block.timestamp;
                IUniswapV2Pair(pancakePair).sync();
            }
        }
    }

    function calculateTaxes() internal view returns (uint256 _buyTax, uint256 _sellTax) {
        uint256 elapsed = block.timestamp - openingPoint;
        if (elapsed < 12 hours) return (5, 15);
        else if (elapsed < 24 hours) return (5, 10);
        else return (3, 3);
    }

    function process(bool isExchange, uint256 gas) private {
        if(isExchange) return;
        if(balanceOf(address(this)) < 1e18) return;
        
        uint256 totalLP = IERC20(pancakePair).totalSupply();
        uint256 dividendFee = balanceOf(address(this));

        if(totalLP == 0 || dividendFee == 0) return;

        address shareHolder;
        uint256 lpBalance;
        uint256 amount;
        uint256 shareholderCount = holders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];

            lpBalance = IERC20(pancakePair).balanceOf(shareHolder);

            if (lpBalance > 0) {
                amount = (dividendFee * lpBalance) / totalLP;
                uint256 currentFee = balanceOf(address(this));
                if (amount > 0 && currentFee > amount) super._update(address(this), shareHolder, amount);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }    

    function addHolder(address user) private  {
        uint256 size;

        assembly {
            size := extcodesize(user)
        }

        if (size > 0) {
            return;
        }

        if (holderIndex[user] == 0) {
            if (holders.length ==0 || holders[0] != user) {
                holderIndex[user] = holders.length;
                holders.push(user);
            }
        }
    }

    function removeHolder(address user) private {
        uint256 indexToRemove = holderIndex[user];
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        if (indexToRemove == 0 || size > 0) {
            return;
        }
        address lastHolder = holders[holders.length - 1];
        holders[indexToRemove] = lastHolder;
        holderIndex[lastHolder] = indexToRemove;
        holders.pop();
        delete holderIndex[user];
    }

    function updateMyStatus() external {
        uint256 lpBalance = IERC20(pancakePair).balanceOf(msg.sender);
        if (lpBalance >= MIN_DIVIDEND_LIMIT) {
            addHolder(msg.sender);
        } else {
            removeHolder(msg.sender);
        }
    }

    function getHolders() public view returns(address[] memory){
        return holders;
    }

    function claim(address recipient) external onlyOwner(){
        require(recipient != address(0), "Zero address.");
        super._transfer(address(this), recipient, balanceOf(address(this)));
    } 

}