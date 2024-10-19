// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PowerAgentsOApp is OApp, OAppOptionsType3 {
    /// @notice Last received message data.
    string public data = "Nothing received yet";

    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3 (enforcedOptions).
    uint16 public constant SEND = 1;

    bool public initialized;

    address public factoryAdmin;

    /// @notice Emitted when a message is received from another chain.
    event MessageReceived(bytes message, uint32 senderEid, bytes32 sender);

    /// @notice Emitted when a message is sent to another chain (A -> B).
    event MessageSent(bytes message, uint32 dstEid);

    /// @dev Revert with this error when an invalid message type is used.
    error InvalidMsgType();

    error AlreadyInitialized();
    error OnlyFactoryAdmin();

    modifier onlyFactoryAdmin() {
        if (msg.sender != factoryAdmin) revert OnlyFactoryAdmin();
        _;
    }

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _endpoint The LayerZero endpoint for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     */
    constructor(address _endpoint, address _owner, address _factoryAdmin) OApp(_endpoint, _owner) Ownable(_owner) {
        factoryAdmin = _factoryAdmin;
    }

    function init(uint32 _eid, bytes32 _peer) external onlyFactoryAdmin {
        if (initialized) revert AlreadyInitialized();
        initialized = true;
        _setPeer(_eid, _peer);
    }

    receive() external payable {}

    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @notice Returns the estimated messaging fee for a given message.
     * @param _dstEids Destination endpoint ID array where the message will be batch sent.
     * @param _msgType The type of message being sent.
     * @param _messages The messages content.
     * @param _extraSendOptions Extra gas options for receiving the send call (A -> B).
     * Will be summed with enforcedOptions, even if no enforcedOptions are set.
     * @param _payInLzToken Boolean flag indicating whether to pay in LZ token.
     * @return totalFee The estimated messaging fee for sending to all pathways.
     */
    function quote(
        uint32[] memory _dstEids,
        uint16 _msgType,
        bytes[] memory _messages,
        bytes calldata _extraSendOptions,
        bool _payInLzToken
    ) public view returns (MessagingFee memory totalFee) {
        

        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory options = combineOptions(_dstEids[i], _msgType, _extraSendOptions);
            MessagingFee memory fee = _quote(_dstEids[i], _messages[i], options, _payInLzToken);
            totalFee.nativeFee += fee.nativeFee;
            totalFee.lzTokenFee += fee.lzTokenFee;
        }
    }

    function send(
        uint32[] memory _dstEids,
        uint16 _msgType,
        bytes[] memory _messages,
        bytes calldata _extraSendOptions 
    ) external payable {
        if (_msgType != SEND) {
            revert InvalidMsgType();
        }

        // Calculate the total messaging fee required.
        MessagingFee memory totalFee = quote(_dstEids, _msgType, _messages, _extraSendOptions, false);
        require(msg.value >= totalFee.nativeFee, "Insufficient fee provided");

        uint256 totalNativeFeeUsed = 0;
        uint256 remainingValue = msg.value;

        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory options = combineOptions(_dstEids[i], _msgType, _extraSendOptions);
            MessagingFee memory fee = _quote(_dstEids[i], _messages[i], options, false);

            totalNativeFeeUsed += fee.nativeFee;
            remainingValue -= fee.nativeFee;

            // Ensure the current call has enough allocated fee from msg.value.
            require(remainingValue >= 0, "Insufficient fee for this destination");

            _lzSend(
                _dstEids[i],
                _messages[i],
                options,
                fee,
                payable(msg.sender)
            );

            emit MessageSent(_messages[i], _dstEids[i]);
        }
    }

    /**
     * @notice Internal function to handle receiving messages from another chain.
     * @dev Decodes and processes the received message based on its type.
     * @param _origin Data about the origin of the received message.
     * @param message The received message content.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*guid*/,
        bytes calldata message,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {

        //decode the message and execute the call
        (address target, bytes memory callData, uint256 value) = abi.decode(message, (address, bytes, uint256));
        (bool success, ) = target.call{value: value}(callData);
        require(success, "Call failed");

        emit MessageReceived(message, _origin.srcEid, _origin.sender);
    }
}