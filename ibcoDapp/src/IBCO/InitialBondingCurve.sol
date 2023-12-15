// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// library `openzeppelin safeTransfer`
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IFInitialBondingCurve {
    /**
     * claim
     * - claim
     */
    function claim() external;

    /**
     * widhdrawProvidedETH
     * - widthdraw provided eth
     * - access controll
     * only contract owner
     */
    function withdrawProvidedETH() external;

    /**
     * withdrawHEGIC
     * - widthdraw Hegic
     * - access controll
     * only contract owner
     */
    function withdrawHEGIC() external;

    /**
     * withdrawUnclaimedHEGIC
     * - widthdraw unclaimed Hegic
     * - access controll
     * only contract owner
     */
    function withdrawUnclaimedHEGIC() external;
}

interface EventInitialBondingCurve {
    // event
    /**
     * ReceivedEvent
     * - receive ETH(payable) event
     * @param account_ address indexed
     * @param amount_ uint256
     * - using receive
     */
    event ReceivedEvent(address indexed account_, uint256 amount_);

    /**
     * ClaimedEvent
     * - Call Claimed event
     * @param account_ address indexed
     * @param userShare_ uint256
     * @param hegicAmount_ uint256 hegicAmount_
     * - using claim
     */
    event ClaimedEvent(
        address indexed account_,
        uint256 userShare_,
        uint256 hegicAmount_
    );
}

interface ErrorInitialBondingCurve {
    /**
     * OfferingHasNotStartedYet
     * - `START <= block.timestam`
     * - using receive
     */
    error OfferingHasNotStartedYet(address acount_, uint256 timestamp_);
    /**
     * OfferingHasAlreadyEnded
     * - `block.timestamp <= END`
     * - using receive
     */
    error OfferingHasAlreadyEnded(address acount_, uint256 timestamp_);

    /**
     * OfferingMustBeCompleted
     * - `block.timestamp > END`
     * - using claim
     * - using withdrawProvidedETH
     * - using withdrawHEGIC
     */
    error OfferingMustBeCompleted(address acount_, uint256 timestamp_);

    /**
     * ProvidedAmountIsEmpty
     * - `provided[msg.sender] > 0`
     * - using claim
     */
    error ProvidedAmountIsEmpty(address acount_, uint256 amount_);

    /**
     * TotalProvidedIsLessThanMinimalProvideAmount
     * - `totalProvided >= MINIMAL_PROVIDE_AMOUNT`
     * - using withdrawProvidedETH
     */
    error TotalProvidedIsLessThanMinimalProvideAmount(
        address acount_,
        uint256 amount_
    );

    /**
     * TotalProvidedIsMoreThanMinimalProvideAmount
     * - `totalProvided < MINIMAL_PROVIDE_AMOUNT`
     * - using withdrawHEGIC
     */
    error TotalProvidedIsMoreThanMinimalProvideAmount(
        address acount_,
        uint256 amount_
    );

    /**
     * WithdrawUnavailableYet
     * - `END + 30 days < block.timestam`
     * - using withdrawProvidedETH
     */
    error WithdrawUnavailableYet(address acount_, uint256 timestamp_);
}

library SafeMath {
    function add(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        c_ = a_ + b_;
        assert(c_ >= a_);
        return c_;
    }

    function mul(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        if (a_ == 0) {
            return 0;
        }
        c_ = a_ * b_;
        assert(c_ / a_ == b_);
        return c_;
    }

    function div(uint256 a_, uint256 b_) internal pure returns (uint256 c_) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        c_ = a_ / b_;
    }
}

/// Access control
contract Ownerable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() internal returns (address owner_) {
        owner_ = _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is only owner.");
        _;
    }
}

contract InitialBondingCurve is
    IFInitialBondingCurve,
    EventInitialBondingCurve,
    ErrorInitialBondingCurve,
    Ownerable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public constant START = 1700964050;
    uint256 public constant END = START + 3 days;
    uint256 public constant TOTAL_DISTRIBUTE_AMOUNT = 90_360_300e18;
    uint256 public constant MINIMAL_PROVIDE_AMOUNT = 700 ether;
    uint256 public _totalProvided = 0;
    mapping(address => uint) public _provided;
    IERC20 public immutable HEGIC;

    constructor(address dummyHegicERC20Token_) {
        HEGIC = IERC20(dummyHegicERC20Token_);
    }

    receive() external payable {
        uint256 _amount;
        if (START >= block.timestamp)
            revert OfferingHasNotStartedYet(msg.sender, block.timestamp);
        if (block.timestamp >= END)
            revert OfferingHasAlreadyEnded(msg.sender, block.timestamp);

        _amount = msg.value;
        _totalProvided = _totalProvided.add(_amount);
        _provided[msg.sender] = _provided[msg.sender].add(_amount);

        emit ReceivedEvent(msg.sender, _amount);
    }

    function claim() external override {
        uint256 _hegicAmount;
        uint256 _userShare;
        if (block.timestamp <= END)
            revert OfferingMustBeCompleted(msg.sender, block.timestamp);
        if (_provided[msg.sender] <= 0)
            revert ProvidedAmountIsEmpty(msg.sender, _provided[msg.sender]);

        _userShare = _provided[msg.sender];
        _provided[msg.sender] = 0;

        if (_totalProvided >= MINIMAL_PROVIDE_AMOUNT) {
            _hegicAmount = TOTAL_DISTRIBUTE_AMOUNT.mul(_userShare).div(
                _totalProvided
            );
            HEGIC.safeTransfer(msg.sender, _hegicAmount);
            emit ClaimedEvent(msg.sender, _userShare, _hegicAmount);
        } else {
            (bool isSendShare, ) = msg.sender.call{value: _userShare}("");

            if (isSendShare)
                emit ClaimedEvent(msg.sender, _userShare, _hegicAmount);
        }
    }

    function withdrawProvidedETH() external override onlyOwner {
        if (block.timestamp <= END)
            revert OfferingMustBeCompleted(msg.sender, block.timestamp);
        if (_totalProvided <= MINIMAL_PROVIDE_AMOUNT)
            revert TotalProvidedIsLessThanMinimalProvideAmount(
                msg.sender,
                _totalProvided
            );

        payable(owner()).transfer(address(this).balance);
    }

    function withdrawHEGIC() external override onlyOwner {
        if (block.timestamp <= END)
            revert OfferingMustBeCompleted(msg.sender, block.timestamp);
        if (_totalProvided > MINIMAL_PROVIDE_AMOUNT)
            revert TotalProvidedIsMoreThanMinimalProvideAmount(
                msg.sender,
                _totalProvided
            );

        HEGIC.safeTransfer(owner(), HEGIC.balanceOf(address(this)));
    }

    function withdrawUnclaimedHEGIC() external override onlyOwner {
        if (block.timestamp <= END + 30 days)
            revert WithdrawUnavailableYet(msg.sender, block.timestamp);

        HEGIC.safeTransfer(owner(), HEGIC.balanceOf(address(this)));
    }
}
