// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract InvestmentPools {
    address public owner;

    uint256 public poolCount;
    mapping(uint256 => Pool) public pools;

    event InvestmentMade(
        uint256 indexed poolId,
        address indexed investor,
        uint256 amount
    );
    event PoolClosedWithCoverage(
        uint256 indexed poolId,
        uint256 totalInvested,
        uint256 goal,
        uint256 coveragePercentage
    );
    event FundsReturned(
        uint256 indexed poolId,
        address indexed investor,
        uint256 amount
    );
    event FundsAddedToPool(
        uint256 indexed poolId,
        uint256 additionalAmount,
        uint256 newTotalInvested
    );

    struct Pool {
        string name;
        string codigoLote;
        uint256 goal;
        uint256 deadline;
        uint256 totalInvested;
        uint256 tokenAmount;
        address tokenAddress;
        bool isClosed;
        address[] investors;
        mapping(address => uint256) investments;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPool(
        string memory _name,
        string memory _codigoLote,
        uint256 _goal,
        uint256 _deadline,
        uint256 _tokenAmount
    ) public {
        require(msg.sender == owner, "Solo el propietario puede crear un pool");

        Pool storage newPool = pools[poolCount++];
        newPool.name = _name;
        newPool.codigoLote = _codigoLote;
        newPool.goal = _goal;
        newPool.deadline = _deadline;
        newPool.tokenAmount = _tokenAmount;
    }

    function invest(uint256 _poolId) public payable {
        require(_poolId < poolCount, "Pool no encontrado");
        require(!pools[_poolId].isClosed, "El pool ya esta cerrado");
        require(
            block.timestamp < pools[_poolId].deadline,
            "El pool ha expirado"
        );
        require(msg.value > 0, "La inversion debe ser mayor a 0");

        Pool storage pool = pools[_poolId];

        uint256 investmentInUSD = msg.value; // Inversión en USD

        pool.totalInvested += investmentInUSD;

        if (pool.investments[msg.sender] == 0) {
            pool.investors.push(msg.sender);
        }

        pool.investments[msg.sender] += investmentInUSD;

        emit InvestmentMade(_poolId, msg.sender, investmentInUSD);

        if (pool.totalInvested >= pool.goal) {
            _closePool(_poolId);
        }
    }

    function checkAndClosePool(uint256 _poolId) public {
        require(_poolId < poolCount, "Pool no encontrado");
        Pool storage pool = pools[_poolId];
        require(!pool.isClosed, "El pool ya esta cerrado");
        require(block.timestamp >= pool.deadline, "El pool aun no ha expirado");

        if (pool.totalInvested >= pool.goal) {
            _closePool(_poolId);
        } else {
            _refundInvestors(_poolId);
        }
    }

    function _closePool(uint256 _poolId) internal {
        Pool storage pool = pools[_poolId];
        pool.isClosed = true;

        string memory tokenName = string(
            abi.encodePacked(pool.name, "_AgroBlock")
        );
        string memory tokenSymbol = string(
            abi.encodePacked(pool.codigoLote, "AB")
        );

        AgroBlockToken newToken = new AgroBlockToken(
            tokenName,
            tokenSymbol,
            pool.tokenAmount
        );
        pool.tokenAddress = address(newToken);

        for (uint256 i = 0; i < pool.investors.length; i++) {
            address investor = pool.investors[i];
            uint256 investment = pool.investments[investor];
            uint256 share = (investment * pool.tokenAmount) /
                pool.totalInvested;
            newToken.transfer(investor, share);
        }

        uint256 coveragePercentage = (pool.totalInvested * 100) / pool.goal;
        emit PoolClosedWithCoverage(_poolId, pool.totalInvested, pool.goal, coveragePercentage);
    }

    function _refundInvestors(uint256 _poolId) internal {
        Pool storage pool = pools[_poolId];
        for (uint256 i = 0; i < pool.investors.length; i++) {
            address investor = pool.investors[i];
            uint256 investment = pool.investments[investor];
            if (investment > 0) {
                payable(investor).transfer(investment);
                pool.investments[investor] = 0;
                emit FundsReturned(_poolId, investor, investment);
            }
        }
        pool.isClosed = true;
        emit PoolClosedWithCoverage(_poolId, pool.totalInvested, pool.goal, 0); // Emitir con 0% si no se ha cubierto el objetivo
    }

    function addFundsToPool(uint256 _poolId) public payable {
        require(msg.sender == owner, "Solo el propietario puede agregar fondos");
        require(_poolId < poolCount, "Pool no encontrado");
        require(!pools[_poolId].isClosed, "El pool ya esta cerrado");

        Pool storage pool = pools[_poolId];
        uint256 additionalInvestment = msg.value; // No multiplicar por 300

        pool.totalInvested += additionalInvestment;

        if (pool.totalInvested > pool.goal) {
            pool.totalInvested = pool.goal; // No permitir que el total supere el objetivo
        }

        // Distribuir el dinero agregado proporcionalmente entre los inversores existentes
        if (pool.totalInvested > 0) {
            for (uint256 i = 0; i < pool.investors.length; i++) {
                address investor = pool.investors[i];
                uint256 investment = pool.investments[investor];
                uint256 share = (investment * additionalInvestment) / pool.totalInvested;
                pool.investments[investor] += share;
            }
        }

        emit FundsAddedToPool(_poolId, additionalInvestment, pool.totalInvested);
    }

    receive() external payable {}
}

contract AgroBlockToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}
