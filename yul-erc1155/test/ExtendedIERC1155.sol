pragma solidity 0.8.20;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ExtendedIERC1155 is IERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}
