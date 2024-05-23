// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract TravelVRFV2Plus is VRFConsumerBaseV2Plus {
    error TravelVRFV2Plus__WithdrawFailed(uint256 amount);
    error TravelVRFV2Plus__NoRequestFound(uint256 requestId);
    error TravelVRFV2Plus__OnlyOwnerOrCollateralOwner(address _opeartor);
    error TravelVRFV2Plus__InsufficientFunds(address sender, uint256 paid);

    error TravelVRFV2Plus__RequesterNotFoundById(uint256 _requestId);
    error TravelVRFV2Plus__RequestHasNotBeenFulfilled(address _requester, uint256 _requestId);

    event TravelVRFV2Plus__Withdraw(address _requester, uint256 _amount);
    event TravelVRFV2Plus__RequesterDeleted(address _requester);
    event RequestSent(address indexed requester, uint256 indexed requestId, uint256 paid, uint256 timestamp);
    event RequestFulfilled(
        address indexed requester,
        uint256 indexed requestId,
        uint8 indexed dice,
        uint256 randomWord,
        uint256 paid,
        uint256 timestamp
    );

    modifier OnlyOwnerOrCollaborators() {
        if (msg.sender != owner() && !s_collateralOwners[msg.sender]) {
            revert TravelVRFV2Plus__OnlyOwnerOrCollateralOwner(msg.sender);
        }
        _;
    }

    // 合作伙伴地址到布尔值的映射，表示是否为合作伙伴
    mapping(address => bool) internal s_collateralOwners;
    mapping(uint256 => RequestStatus) internal s_requestStatus; /* requestId => RequestStatus */
    mapping(address => uint256[]) internal s_VRFRequestMappings; /* requester => requestId[] */

    /**
     * @notice RequestStatus 结构体，用于存储请求状态。
     * @param requester 请求的发起者地址。
     * @param paid 已支付的 ETH 数量。
     * @param fulfilled 请求是否已被成功完成。
     * @param randomWord 链上随机数。
     * @param dice 随机数对应的骰子数。
     * @param timestamp 请求的时间戳。
     */
    struct RequestStatus {
        address requester;
        uint256 paid;
        bool fulfilled;
        uint256 randomWord;
        uint8 dice;
        uint256 timestamp;
    }

    /* Fields */

    IVRFCoordinatorV2Plus COORDINATOR;

    uint256 private immutable s_subscriptionId;

    // The Coordinators address.
    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
     */
    address private immutable s_coordinatorAddr;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2-5/supported-networks
    // 30 gwei keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
    bytes32 immutable s_keyhash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas.
    uint32 private s_callbackGasLimit = 100000;

    // Cannot exceed VRFCoordinatorV2_5.MAX_REQUEST_CONFIRMATIONS.  [3, 200].
    uint16 private constant s_requestConfirmations = 3;

    bool private s_nativePayment = false;
    uint256 private s_minRollPrice = 0.01 ether; // 0.01 ETH

    constructor(uint256 _subscriptionId, address _coordinatorAddr, bytes32 _keyhash, bool _nativePayment)
        VRFConsumerBaseV2Plus(_coordinatorAddr)
    {
        s_subscriptionId = _subscriptionId;
        s_coordinatorAddr = _coordinatorAddr;
        s_keyhash = _keyhash;
        s_nativePayment = _nativePayment;
        COORDINATOR = IVRFCoordinatorV2Plus(s_coordinatorAddr);
    }

    // Assumes the subscription is funded sufficiently.
    // ensure user send more than 0.01 ETH to contract.
    function requestRandomWords() external payable returns (uint256 requestId) {
        uint256 paid = msg.value;
        if (paid < s_minRollPrice) {
            revert TravelVRFV2Plus__InsufficientFunds(msg.sender, paid);
        }
        requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyhash,
                subId: s_subscriptionId,
                requestConfirmations: s_requestConfirmations,
                callbackGasLimit: s_callbackGasLimit,
                numWords: 1, // Only request one word at a time.
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: s_nativePayment}))
            })
        );
        uint256 timestamp = block.timestamp;
        mappingRequestStatus(msg.sender, requestId, paid, timestamp);
        emit RequestSent(msg.sender, requestId, paid, timestamp);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        RequestStatus storage requestStatus = s_requestStatus[_requestId];
        if (requestStatus.paid == 0) {
            revert TravelVRFV2Plus__NoRequestFound(_requestId);
        }
        requestStatus.fulfilled = true;
        requestStatus.randomWord = _randomWords[0];
        requestStatus.dice = uint8(_randomWords[0] % 6) + 1;
        emit RequestFulfilled(
            requestStatus.requester,
            _requestId,
            requestStatus.dice,
            _randomWords[0],
            requestStatus.paid,
            block.timestamp
        );
    }

    /* Functions */

    /**
     * @notice getRequestStatus 函数，允许外部查询特定 VRF 请求的状态。
     * @param _requestId VRF 请求的唯一标识符。
     * return 请求状态信息，包括请求者、是否已履行、随机数、骰子号码和已支付金额。
     */
    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (address requester, bool fulfilled, uint256 randomWord, uint8 dice, uint256 paid, uint256 timestamp)
    {
        RequestStatus memory requestStatus = s_requestStatus[_requestId];
        if (requestStatus.paid == 0) {
            revert TravelVRFV2Plus__NoRequestFound(_requestId);
        }
        return (
            requestStatus.requester,
            requestStatus.fulfilled,
            requestStatus.randomWord,
            requestStatus.dice,
            requestStatus.paid,
            requestStatus.timestamp
        );
    }

    /* SETTER */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external OnlyOwnerOrCollaborators {
        s_callbackGasLimit = _callbackGasLimit;
    }

    function setNativePayment(bool _nativePayment) external OnlyOwnerOrCollaborators {
        s_nativePayment = _nativePayment;
    }

    function setMinRollPrice(uint256 _minRollPrice) external OnlyOwnerOrCollaborators {
        s_minRollPrice = _minRollPrice;
    }

    /* GETTER */
    function getCallbackGasLimit() external view returns (uint32) {
        return s_callbackGasLimit;
    }

    function getNativePayment() external view returns (bool) {
        return s_nativePayment;
    }

    function getMinRollPrice() external view returns (uint256) {
        return s_minRollPrice;
    }

    /* Withdraw ETH */
    function withdraw() external OnlyOwnerOrCollaborators {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = payable(msg.sender).call{value: balance}("");
            if (!success) {
                revert TravelVRFV2Plus__WithdrawFailed(balance);
            }
            emit TravelVRFV2Plus__Withdraw(msg.sender, balance);
        }
    }

    /* For request data mapping */
    /**
     * @notice mappingRequestStatus 内部函数，用于初始化请求状态并将其与请求者关联。
     * @param _requester 请求的发起者地址。
     * @param _requestId 请求的 ID。
     * @param _paid 已支付的 LINK 数量。
     */
    function mappingRequestStatus(address _requester, uint256 _requestId, uint256 _paid, uint256 _timestamp) private {
        s_requestStatus[_requestId] = RequestStatus({
            requester: _requester,
            paid: _paid,
            fulfilled: false,
            randomWord: 0,
            dice: 0,
            timestamp: _timestamp
        });
        s_VRFRequestMappings[_requester].push(_requestId);
    }

    // 允许合约所有者添加合作伙伴
    function addCollaborator(address _collaborator) external onlyOwner {
        s_collateralOwners[_collaborator] = true;
    }

    // 允许合约所有者移除合作伙伴
    function removeCollaborator(address _collaborator) external onlyOwner {
        s_collateralOwners[_collaborator] = false;
    }

    /**
     * @notice deleteRequest 公共函数，用于删除特定请求及其相关信息。
     * @param _requestId 要删除的请求的 ID。
     */
    function deleteRequest(uint256 _requestId) public OnlyOwnerOrCollaborators {
        // Retrieve the request information
        RequestStatus storage request = s_requestStatus[_requestId];
        // If the request has not been fulfilled in 1 day yet, revert
        if (!request.fulfilled && block.timestamp < request.timestamp + 1 days) {
            revert TravelVRFV2Plus__RequestHasNotBeenFulfilled(request.requester, _requestId);
        }

        address requester = request.requester;
        uint256[] storage requesterIds = s_VRFRequestMappings[requester];

        // Traverse the array of request IDs for the requester, find and delete the specified request ID
        for (uint256 i = 0; i < requesterIds.length; i++) {
            if (requesterIds[i] == _requestId) {
                requesterIds[i] = requesterIds[requesterIds.length - 1];
                requesterIds.pop();
                break;
            }
        }

        // Delete the request information
        delete s_requestStatus[_requestId];
    }

    /**
     * @notice deleteRequest 公共函数，用于删除特定请求者的所有请求。
     * @param _requester 要删除其请求的请求者的地址。
     */
    function deleteRequest(address _requester) public OnlyOwnerOrCollaborators {
        uint256[] memory requestIds = s_VRFRequestMappings[_requester];
        for (uint256 i = 0; i < requestIds.length; i++) {
            delete s_requestStatus[requestIds[i]];
        }
        emit TravelVRFV2Plus__RequesterDeleted(_requester);
        delete s_VRFRequestMappings[_requester];
    }

    /**
     * @notice getRequester 公共函数，根据请求 ID 获取请求者地址。
     * @param _requestId 请求的 ID。
     * @return 请求者的地址。
     */
    function getRequester(uint256 _requestId) public view returns (address) {
        address requester = s_requestStatus[_requestId].requester;
        if (requester == address(0)) {
            revert TravelVRFV2Plus__RequesterNotFoundById(_requestId);
        }
        return requester;
    }

    /**
     * @notice getRequestIds 公共函数，根据请求者地址获取其所有请求 ID。
     * @param _requester 请求者的地址。
     * @return 请求者所有请求的 ID 数组。
     */
    function getRequestIds(address _requester) public view returns (uint256[] memory) {
        return s_VRFRequestMappings[_requester];
    }
}
