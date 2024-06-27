// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @notice Interface of the VRF Gateway contract. Must be imported.
interface ISecretVRF {
    function requestRandomness(
        uint32 _numWords,
        uint32 _callbackGasLimit
    ) external payable returns (uint256 requestId);
}

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

contract TravelVRFLinea {
    error TravelVRFV2Plus__WithdrawFailed(uint256 amount);
    error TravelVRFV2Plus__NoRequestFound(uint256 requestId);
    error TravelVRFV2Plus__OnlyOwnerOrCollateralOwner(address _opeartor);
    error TravelVRFV2Plus__InsufficientFunds(address sender, uint256 paid);

    error TravelVRFV2Plus__RequesterNotFoundById(uint256 _requestId);
    error TravelVRFV2Plus__RequestHasNotBeenFulfilled(
        address _requester,
        uint256 _requestId
    );

    event TravelVRFV2Plus__Withdraw(address _requester, uint256 _amount);
    event TravelVRFV2Plus__RequesterDeleted(address _requester);
    event RequestSent(
        address indexed requester,
        uint256 indexed requestId,
        uint256 paid,
        uint256 timestamp
    );
    event RequestFulfilled(
        address indexed requester,
        uint256 indexed requestId,
        uint8 indexed dice,
        uint256 randomWord,
        uint256 paid,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    modifier OnlyOwnerOrCollaborators() {
        if (msg.sender != owner && !s_collateralOwners[msg.sender]) {
            revert TravelVRFV2Plus__OnlyOwnerOrCollateralOwner(msg.sender);
        }
        _;
    }

    /// @notice VRFGateway stores address to the Gateway contract to call for VRF
    /// 0x8EaAB5e8551781F3E8eb745E7fcc7DAeEFd27b1f Linea Sepolia Testnet
    address public VRFGateway;

    address public immutable owner;

    uint32 private s_callbackGasLimit = 100000;
    uint256 private s_minRollPrice = 0.01 ether; // 0.01 ETH

    // 合作伙伴地址到布尔值的映射，表示是否为合作伙伴
    mapping(address => bool) internal s_collateralOwners;
    mapping(uint256 => RequestStatus)
        internal s_requestStatus; /* requestId => RequestStatus */
    mapping(address => uint256[])
        internal s_VRFRequestMappings; /* requester => requestId[] */

    constructor(address _VRFGateway) {
        VRFGateway = _VRFGateway;
        owner = msg.sender;
    }

    /// @notice Increase the task_id to check for problems
    /// @param _callbackGasLimit the Callback Gas Limit
    function estimateRequestPrice(
        uint32 _callbackGasLimit
    ) private view returns (uint256) {
        uint256 baseFee = _callbackGasLimit * block.basefee;
        return baseFee;
    }

    /// @notice Demo function on how to implement a VRF call using Secret VRF, here the values for numWords and callbackGasLimit are preset
    function requestRandomWords() external payable returns (uint256 requestId) {
        uint256 paid = msg.value;
        if (paid < s_minRollPrice) {
            revert TravelVRFV2Plus__InsufficientFunds(msg.sender, paid);
        }

        // Get the VRFGateway contract interface
        ISecretVRF vrfContract = ISecretVRF(VRFGateway);

        // Call the VRF contract to request random numbers.
        // Returns requestId of the VRF request. A  contract can track a VRF call that way.
        // number Words = 1
        // callbackGasLimit = 100000
        uint256 price = estimateRequestPrice(s_callbackGasLimit);
        requestId = vrfContract.requestRandomness{value: price}(
            1,
            s_callbackGasLimit
        );

        uint256 timestamp = block.timestamp;
        mappingRequestStatus(msg.sender, requestId, paid, timestamp);
        emit RequestSent(msg.sender, requestId, paid, timestamp);
        return requestId;
    }

    /*//////////////////////////////////////////////////////////////
                   fulfillRandomWords Callback
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback by the Secret VRF with the requested random numbers
    /// @param _requestId requestId of the VRF request that was initally called
    /// @param _randomWords Generated Random Numbers in uint256 array
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) external {
        // Checks if the callback was called by the VRFGateway and not by any other address
        require(
            msg.sender == address(VRFGateway),
            "only Secret Gateway can fulfill"
        );

        RequestStatus storage requestStatus = s_requestStatus[_requestId];
        if (requestStatus.paid == 0) {
            revert TravelVRFV2Plus__NoRequestFound(_requestId);
        }
        requestStatus.fulfilled = true;
        requestStatus.randomWord = _randomWords[0];
        requestStatus.dice = uint8(_randomWords[0] % 6) + 1;

        // Do your custom stuff here, for example:
        emit RequestFulfilled(
            requestStatus.requester,
            _requestId,
            requestStatus.dice,
            _randomWords[0],
            requestStatus.paid,
            block.timestamp
        );
    }

    /**
     * @notice getRequestStatus 函数，允许外部查询特定 VRF 请求的状态。
     * @param _requestId VRF 请求的唯一标识符。
     * return 请求状态信息，包括请求者、是否已履行、随机数、骰子号码和已支付金额。
     */
    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (
            address requester,
            bool fulfilled,
            uint256 randomWord,
            uint8 dice,
            uint256 paid,
            uint256 timestamp
        )
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

    /// @notice Sets the address to the Gateway contract
    /// @param _VRFGateway address of the gateway
    function setGatewayAddress(address _VRFGateway) external onlyOwner {
        VRFGateway = _VRFGateway;
    }

    function setMinRollPrice(
        uint256 _minRollPrice
    ) external OnlyOwnerOrCollaborators {
        s_minRollPrice = _minRollPrice;
    }

    function setCallbackGasLimit(
        uint32 _callbackGasLimit
    ) external OnlyOwnerOrCollaborators {
        s_callbackGasLimit = _callbackGasLimit;
    }

    /* GETTER */
    function getCallbackGasLimit() external view returns (uint32) {
        return s_callbackGasLimit;
    }

    function getMinRollPrice() external view returns (uint256) {
        return s_minRollPrice;
    }

    /* Withdraw ETH */
    function withdraw() external OnlyOwnerOrCollaborators {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
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
    function mappingRequestStatus(
        address _requester,
        uint256 _requestId,
        uint256 _paid,
        uint256 _timestamp
    ) private {
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
        if (
            !request.fulfilled && block.timestamp < request.timestamp + 1 days
        ) {
            revert TravelVRFV2Plus__RequestHasNotBeenFulfilled(
                request.requester,
                _requestId
            );
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
    function getRequestIds(
        address _requester
    ) public view returns (uint256[] memory) {
        return s_VRFRequestMappings[_requester];
    }
}
