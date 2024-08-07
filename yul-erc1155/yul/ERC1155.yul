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
                let accountsPos, accountsLength := decodeArray(0)
                let tokenIdsPos, tokenIdsLength := decodeArray(1)
                require(eq(accountsLength, tokenIdsLength))
                returnBalanceOfBatch(accountsPos, tokenIdsPos, tokenIdsLength)
            }
            case 0xf6eb127a /* "batchBurn(address,uint256[],uint256[])" */ {
                require(calledByOwner())
                let idsPos, idsLength := decodeArray(1)
                let amountsPos, amountsLength := decodeArray(2)
                require(eq(idsLength, amountsLength))
                let account := decodeAsAddress(0)
                batchBurn(account, idsPos, amountsPos, idsLength)
            }
            case 0xb48ab8b6 /* "batchMint(address,uint256[],uint256[],bytes)" */ {
                require(calledByOwner())
                let idsPos, idsLength := decodeArray(1)
                let amountsPos, amountsLength := decodeArray(2)
                require(eq(idsLength, amountsLength))
                let account := decodeAsAddress(0)
                revertIfZeroAddress(account)
                batchMint(account, idsPos, amountsPos, idsLength)
                if isContract(account) {
                    let dataPos, dataLength := decodeArray(3)
                    checkBatchAcceptance(account, 0, idsPos, amountsPos, idsLength, dataPos, dataLength)
                }
            }
            case 0xf5298aca /* "burn(address,uint256,uint256)" */ {
                require(calledByOwner())
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
                returnUint(isApprovedOrOwner(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x731133e9 /* "mint(address,uint256,uint256,bytes)" */ {
                require(calledByOwner())
                let account := decodeAsAddress(0)
                revertIfZeroAddress(account)
                let tokenId := decodeAsUint(1)
                let amount := decodeAsUint(2)
                mint(account, tokenId, amount)
                if isContract(account) {
                    let dataPos, dataLength := decodeArray(3)
                    checkAcceptance(account, 0, tokenId, amount, dataPos, dataLength)
                }
            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
                let from := decodeAsAddress(0)
                let to := decodeAsAddress(1)
                revertIfZeroAddress(to)
                let idsPos, idsLength := decodeArray(2)
                let amountsPos, amountsLength := decodeArray(3)
                require(eq(idsLength, amountsLength))
                batchTransfer(from, to, idsPos, amountsPos, idsLength)
                if isContract(to) {
                    let dataPos, dataLength := decodeArray(4)
                    checkBatchAcceptance(to, from, idsPos, amountsPos, idsLength, dataPos, dataLength)
                }
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                let from := decodeAsAddress(0)
                let to := decodeAsAddress(1)
                revertIfZeroAddress(to)
                let tokenId := decodeAsUint(2)
                let amount := decodeAsUint(3)
                transferFrom(from, to, tokenId, amount)
                if isContract(to) {
                    let dataPos, dataSize := decodeArray(4)
                    checkAcceptance(to, from, tokenId, amount, dataPos, dataSize)
                }
            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                approve(decodeAsAddress(0), decodeAsUint(1))
            }
            case 0xdd62ed3e /* "supportsInterface(bytes4)" */ {
                revert (0, 0) // TODO implement
            }
            default {
                revert(0, 0)
            }

            function mint(account, tokenId, amount) {
                addToBalance(account, tokenId, amount)
                emitTransferSingle(caller(), 0, account, tokenId, amount)
            }

            function burn(account, tokenId, amount) {
                deductFromBalance(account, tokenId, amount)
                emitTransferSingle(caller(), account, 0, tokenId, amount)
            }

            function approve(spender, approved) {
                setApproval(caller(), spender, approved)
                emitApprovalForAll(caller(), spender, approved)
            }

            function transferFrom(from, to, tokenId, amount) {
                require(isApprovedOrOwner(from, caller()))
                executeTransfer(from, to, tokenId, amount)
                emitTransferSingle(caller(), from, to, tokenId, amount)
            }

            function executeTransfer(from, to, tokenId, amount) {
                deductFromBalance(from, tokenId, amount)
                addToBalance(to, tokenId, amount)
            }

            function batchTransfer(from, to, idsPos, amountsPos, tokensLength) {
                require(isApprovedOrOwner(from, caller()))
                let bytesLength := mul(tokensLength, 0x20)
                for { let offset := 0 } lt(offset, bytesLength) { offset := add(offset, 0x20) } {
                    let tokenId := calldataload(add(idsPos, offset))
                    let amount := calldataload(add(amountsPos, offset))

                    executeTransfer(from, to, tokenId, amount)
                }

                // TODO emit transfer batch
            }

            function batchMint(account, idsPos, amountsPos, length) {
                let bytesLength := mul(length, 0x20)
                for { let offset := 0 } lt(offset, bytesLength) { offset := add(offset, 0x20) } {
                    let tokenId := calldataload(add(idsPos, offset))
                    let amount := calldataload(add(amountsPos, offset))

                    addToBalance(account, tokenId, amount)
                }

                // TODO emit transfer batch
            }

            function batchBurn(account, idsPos, amountsPos, length) {
                let bytesLength := mul(length, 0x20)
                for { let offset := 0 } lt(offset, bytesLength) { offset := add(offset, 0x20) } {
                    let tokenId := calldataload(add(idsPos, offset))
                    let amount := calldataload(add(amountsPos, offset))

                    deductFromBalance(account, tokenId, amount)
                }

                // TODO emit transfer batch
            }

            function returnBalanceOfBatch(accountsPos, idsPos, length) {
                mstore(0x60, 0x20)
                mstore(0x80, length)

                let bytesLength := mul(0x20, length)
                for { let offset := 0 } lt(offset, bytesLength) { offset := add(offset, 0x20) } {
                    let account := calldataload(add(accountsPos, offset))
                    let tokenId := calldataload(add(idsPos, offset))

                    mstore(add(0xA0, offset), balanceOf(account, tokenId))
                }

                return (0x60, add(0x40, bytesLength))
            }

            function checkAcceptance(account, from, id, value, dataPos, dataLength) {
                let sel := 0xf23a6e6100000000000000000000000000000000000000000000000000000000 // onERC1155Received(address,address,uint256,uint256,bytes)
                mstore(0, sel)
                mstore(0x04, caller())
                mstore(0x24, from)
                mstore(0x44, id)
                mstore(0x64, value)
                mstore(0x84, 0xa0) // pointer to start of `data`
                copyDataToMemoryFromPos(dataPos, dataLength, 1, 0xa4)
                let inputSize := add(dataLength, 0xc4) // Space for 4 bytes for selector, 4 static arguments, and one dynamic argument
                require(call(gas(), account, 0, 0, inputSize, inputSize, 4))
                require(eq(mload(inputSize), sel))
            }

            function checkBatchAcceptance(account, from, idsPos, amountsPos, tokensLength, dataPos, dataLength) {
                let sel := 0xbc197c8100000000000000000000000000000000000000000000000000000000 // onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)
                mstore(0, sel)
                mstore(0x04, caller())
                mstore(0x24, from)
                let tokensByteSize := mul(tokensLength, 0x20)
                let idsLoc := 0xa4
                let amountsLoc := add(0xc4, tokensByteSize)
                let dataLoc := add(0xe4, mul(tokensByteSize, 2))
                mstore(0x44, sub(idsLoc, 4)) // pointer to start of `ids`
                mstore(0x64, sub(amountsLoc, 4)) // pointer to start of `values`
                mstore(0x84, sub(dataLoc, 4)) // pointer to start of `data`

                copyDataToMemoryFromPos(idsPos, tokensLength, 0x20, idsLoc) // copy `ids`
                copyDataToMemoryFromPos(amountsPos, tokensLength, 0x20, amountsLoc) // copy `amounts`
                copyDataToMemoryFromPos(dataPos, dataLength, 1, dataLoc) // copy `bytes`

                let inputSize := add(0x20, add(dataLoc, dataLength))
                require(call(gas(), account, 0, 0, inputSize, inputSize, 4))
                require(eq(mload(inputSize), sel))
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
            function decodeArray(offset) -> beginPos, length {
                let pos := add(4, decodeAsUint(offset))
                length := calldataload(pos)
                beginPos := add(0x20, pos)
            }

            // Copy array-like data to memory
            function copyDataToMemoryFromPos(beginPos, length, elementSize, destOffset) {
                let dataStart := add(destOffset, 0x20)
                calldatacopy(dataStart, beginPos, mul(length, elementSize))
                mstore(destOffset, length)
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
            function isApprovedOrOwner(account, spender) -> approved {
                switch eq(account, spender)
                case 1 {
                    approved := 1
                }
                default {
                    approved := sload(allowanceStorageOffset(account, spender))
                }
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
            function isContract(addr) -> ic {
                ic := gt(extcodesize(addr), 0)
            }
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
        }
    }
}