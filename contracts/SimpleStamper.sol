// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract SimpleStamper {
    struct Stamp {
        bytes32 object;
        uint256 blockNo;
        uint256 timestamp;
    }

    Stamp[] private stampList;
    mapping(bytes32 => uint256[]) private hashObjects;

    event Stamped(
        bytes32 indexed object,
        uint256 blockNo,
        uint256 timestamp
    );

    constructor() {
        stampList.push(Stamp(0, block.number, block.timestamp));
    }

    // Stampear una lista de hashes recibidos como array
    function put(bytes32[] memory objectList) public {
        for (uint256 i = 0; i < objectList.length; i++) {
            bytes32 object = objectList[i];
            stampList.push(Stamp(object, block.number, block.timestamp));
            uint256 newObjectIndex = stampList.length - 1;
            hashObjects[object].push(newObjectIndex);

            emit Stamped(object, block.number, block.timestamp);
        }
    }

    // Devuelve true si el objeto está sellado, false en caso contrario
    function isStamped(bytes32 object) public view returns (bool) {
        return hashObjects[object].length > 0;
    }

    // Devuelve un sello completo (hash, block Num, timestamp) de la lista
    function getStamplistPos(uint256 pos) public view returns (bytes32, uint256, uint256) {
        require(pos < stampList.length, "Index out of bounds");
        Stamp storage stamp = stampList[pos];
        return (stamp.object, stamp.blockNo, stamp.timestamp);
    }

    // Devuelve la marca de tiempo del bloque en el que se guardó un objeto usando su hash
    function getTimestampByHash(bytes32 object) public view returns (uint256) {
        require(isStamped(object), "Object not stamped");
        uint256[] storage indices = hashObjects[object];
        uint256 latestIndex = indices[indices.length - 1];
        return stampList[latestIndex].timestamp;
    }

    // Devuelve la marca de tiempo del bloque en el que se guardó el sello en una posición específica
    function getTimestampByPos(uint256 pos) public view returns (uint256) {
        require(pos < stampList.length, "Index out of bounds");
        return stampList[pos].timestamp;
    }
}
