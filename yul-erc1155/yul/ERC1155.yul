object "Token" {
    code {
        // Store the creator in slot zero.
        sstore(0, caller())

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // Protection against sending Ether
            require(iszero(callvalue()))

            // Dispatcher
            switch selector()
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
                revert (0, 0) // TODO implement
            }
            case 0xb48ab8b6 /* "batchMint(address,uint256[],uint256[],bytes)" */ {
                revert (0, 0) // TODO implement
            }
            case 0xf5298aca /* "burn(address,uint256,uint256)" */ {
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                return (0, 0)
            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
                returnUint(isApproved(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x731133e9 /* "mint(address,uint256,uint256,bytes)" */ {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
                return(0, 0)
            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
                revert (0, 0) // TODO implement
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
                return (0, 0)
            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                approve(decodeAsAddress(0), decodeAsUint(1))
                return (0, 0)
            }
            case 0xdd62ed3e /* "supportsInterface(bytes4)" */ {
                revert (0, 0) // TODO implement
            }
            default {
                revert(0, 0)
            }

            function mint(account, tokenId, amount) {
                require(calledByOwner())

                addToBalance(account, tokenId, amount)
                emitTransferSingle(caller(), 0, account, tokenId, amount)
            }
            function burn(account, tokenId, amount) {
                require(calledByOwner())

                deductFromBalance(account, tokenId, amount)
                emitTransferSingle(caller(), account, 0, tokenId, amount)
            }
            function approve(spender, approved) {
                revertIfZeroAddress(spender)
                setApproval(caller(), spender, approved)
                emitApprovalForAll(caller(), spender, approved)
            }
            function transferFrom(from, to, tokenId, amount) {
                require(isApproved(from, caller()))
                executeTransfer(from, to, tokenId, amount)
            }

            function executeTransfer(from, to, tokenId, amount) {
                revertIfZeroAddress(to)
                deductFromBalance(from, tokenId, amount)
                addToBalance(to, tokenId, amount)
                emitTransferSingle(caller(), from, to, tokenId, amount)
            }


            /* ---------- calldata decoding functions ----------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }
            /* ---------- calldata encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            /* -------- events ---------- */
            function emitTransferSingle(operator, from, to, tokenId, amount) {
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0, tokenId)
                mstore(0x20, amount)
                log4(0, 0x40, signatureHash, operator, from, to)
            }
            function emitApprovalForAll(account, spender, approved) {
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0, approved)
                log3(0, 0x20, signatureHash, account, spender)
            }

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }
            function accountToStorageOffset(account, tokenId) -> offset {
                mstore(0, 0)
                mstore(0x20, account)
                mstore(0x40, tokenId)
                offset := keccak256(0, 0x60)
            }
            function allowanceStorageOffset(account, spender) -> offset {
                mstore(0, 1)
                mstore(0x20, account)
                mstore(0x40, spender)
                offset := keccak256(0, 0x60)
            }

            /* -------- storage access ---------- */
            function owner() -> o {
                o := sload(ownerPos())
            }
            function balanceOf(account, tokenId) -> bal {
                bal := sload(accountToStorageOffset(account, tokenId))
            }
            function addToBalance(account, tokenId, amount) {
                let offset := accountToStorageOffset(account, tokenId)
                sstore(offset, safeAdd(sload(offset), amount))
            }
            function deductFromBalance(account, tokenId, amount) {
                let offset := accountToStorageOffset(account, tokenId)
                let bal := sload(offset)
                require(lte(amount, bal))
                sstore(offset, sub(bal, amount))
            }
            function isApproved(account, spender) -> approved {
                approved := sload(allowanceStorageOffset(account, spender))
            }
            function setApproval(account, spender, approved) {
                sstore(allowanceStorageOffset(account, spender), approved)
            }

            /* ---------- utility functions ---------- */
            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }
            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }
            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }
            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }
            function revertIfZeroAddress(addr) {
                require(addr)
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}