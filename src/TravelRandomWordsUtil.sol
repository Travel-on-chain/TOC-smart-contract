// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract TravelRandomWordsUtil {
    error TravelRandomWords__InvalidRange(uint8 _minNum, uint8 _maxNum);
    // 线性同余法生成随机数

    uint32 private constant A = 1664525;
    uint32 private constant C = 1013904223;
    uint256 private constant M = 2 ** 32; // 模数，保持不变

    // 生成 size 个随机数的函数
    function generateNumbers(
        uint256 size,
        uint256 _seed,
        uint8 _minNum,
        uint8 _maxNum
    ) public pure returns (uint256 init_state, uint8[] memory randomNumbers) {
        if (_maxNum > 256 || _minNum >= _maxNum) {
            revert TravelRandomWords__InvalidRange(_minNum, _maxNum);
        }

        randomNumbers = new uint8[](size);

        uint256 state = _seed % (10 ** 38);
        init_state = state;
        for (uint256 i = 0; i < size; i++) {
            // 使用uint256进行计算以避免溢出
            state = (A * state + C) % M;
            // 缩小范围到[_minNum, _maxNum]内，并转换为uint8
            uint256 range = _maxNum - _minNum + 1;
            uint8 randomValue = uint8((state % range) + _minNum);
            randomNumbers[i] = randomValue;
        }

        return (init_state, randomNumbers);
    }

    // !TODO: Shuffle function maybe deprecated, need to be removed in the future.
    /**
     * @dev Shuffle an array using the Fisher-Yates algorithm.
     * @param start The starting index of the shuffled array. The minimum value of words is set by the s_minValueOfWord variable.
     * @param size The size of the shuffled array. The maximum value of words is set by the s_maxValueOfWord variable.
     * @param entropy The entropy to use for the shuffle.
     */
    function shuffle(
        uint256 start,
        uint256 size,
        uint256 entropy
    ) public pure returns (uint256[] memory) {
        uint256[] memory shuffled = new uint256[](size);

        // Initialize the shuffled array with the indices of the array.
        for (uint256 i = 0; i < size; i++) {
            shuffled[i] = i + start;
        }

        // Shuffle the array using the Fisher-Yates algorithm.
        bytes32 randomness = keccak256(abi.encodePacked(entropy));
        for (uint256 i = size - 1; i > 0; i--) {
            uint256 selected_item = uint256(randomness) % (i + 1);

            // Swap the selected item with the last item of the array.
            uint256 temp = shuffled[i];
            shuffled[i] = shuffled[selected_item];
            shuffled[selected_item] = temp;

            // generate a new randomness for the next iteration.
            randomness = keccak256(abi.encodePacked(randomness));
        }
        return shuffled;
    }
}
