// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ITokenVesting.sol";
import "./libraries/SafeERC20.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract OptimizedTokenVesting is Ownable, ITokenVesting {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private immutable _cliff;
    uint256 private immutable _start;
    uint256 private immutable _end;
    uint256 private immutable _duration;

    bool private immutable _revocable;

    mapping(address => uint256) private _released;
    mapping(address => bool) private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration_ duration in seconds of the cliff in which tokens will begin to vest
     * @param start_ the time (as Unix time) at which point vesting starts
     * @param duration_ duration in seconds of the period in which the tokens will vest
     * @param revocable_ whether the vesting is revocable or not
     */
    constructor(
        address beneficiary_,
        uint256 start_,
        uint256 cliffDuration_,
        uint256 duration_,
        bool revocable_
    ) Ownable(msg.sender) {
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(cliffDuration_ <= duration_, "TokenVesting: cliff is longer than duration");
        require(duration_ > 0, "TokenVesting: duration is 0");
        require(start_ >= block.timestamp, "TokenVesting: start is before current time");
        // solhint-disable-next-line max-line-length
        require(start_ + duration_ > block.timestamp, "TokenVesting: final time is before current time");

        _beneficiary = beneficiary_;
        _revocable = revocable_;
        _duration = duration_;
        _cliff = start_ + cliffDuration_;
        _start = start_;
        _end = start_ + duration_;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return _released[token];
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked(address token) public view returns (bool) {
        return _revoked[token];
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(IERC20 token) public {
        uint256 releasedForToken = _released[address(token)]; // cache variable
        uint256 unreleased = _releasableAmount(token, releasedForToken);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        unchecked { // Cannot exceed ERC20 supply
            _released[address(token)] = releasedForToken + unreleased;
        }

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token, _released[address(token)]);
        uint256 refund = balance - unreleased;

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @notice Allows owner to emergency revoke and refund entire balance,
     * including the vested amount. To be used when beneficiary cannot claim
     * anymore, e.g. when he/she has lots its private key.
     * @param token ERC20 which is being vested
     */
    function emergencyRevoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), balance);

        emit TokenVestingRevoked(address(token));
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function _releasableAmount(IERC20 token, uint256 releasedForToken) private view returns (uint256) {
        return _vestedAmount(token, releasedForToken) - releasedForToken;
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function _vestedAmount(IERC20 token, uint256 releasedForToken) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance;
        unchecked { // Cannot exceed ERC20 supply
            totalBalance = currentBalance + releasedForToken;
        }

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _end || _revoked[address(token)]) {
            return totalBalance;
        } else {
            uint256 elapsed;
            unchecked { // block.timestamp is monotonically increasing
                elapsed = block.timestamp - _start;
            }
            uint256 numerator = totalBalance * elapsed;

            unchecked { // duration is non-zero
                return numerator / _duration;
            }
        }
    }
}