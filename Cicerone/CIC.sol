// SPDX-License-Identifier: MIT
// 指定Solidity的许可证类型为MIT

pragma solidity ^0.8.0;
// 声明使用的Solidity版本，要求至少为0.8.0

/**
 * @title Cicerone
 * @notice Cicerone ERC-20代币合约，代币符号为CIC，总供应量10亿，6个小数位，包含1%转账税费。
 */
contract Cicerone {
    // --- 状态变量 (State Variables) ---

    // 存储代币名称
    string public constant name = "Cicerone";
    // 存储代币符号
    string public constant symbol = "CIC";
    // 存储代币的小数位数，您要求使用6位
    uint8 public constant decimals = 6;
    // 存储总供应量，10亿 * (10^6)
    // 1,000,000,000 * 10^6 = 1,000,000,000,000,000
    uint256 public totalSupply;

    // 存储地址与余额的映射：地址 => 余额
    mapping(address => uint256) private _balances;
    // 存储授权转账的映射：所有者地址 => (被授权地址 => 额度)
    mapping(address => mapping(address => uint256)) private _allowances;

    // 合约创建者地址，用于接收税费
    address public immutable owner;
    // 税率常数：1% = 100。使用10000作为分母，100/10000 = 1%
    uint256 public constant TAX_RATE = 100;
    // 税率的分母，用于精度计算
    uint256 public constant TAX_DENOMINATOR = 10000; // 100%

    // --- 事件 (Events) ---

    // ERC-20标准定义的转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // ERC-20标准定义的授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- 构造函数 (Constructor) ---

    /**
     * @notice 合约部署时执行一次
     * @dev 设置合约创建者为owner，并铸造全部代币给owner
     */
    constructor() {
        // 将部署合约的地址设为owner，用于接收税费
        owner = msg.sender;
        // 计算总供应量：1,000,000,000 * 10^6
        uint256 initialSupply = 1_000_000_000 * (10 ** decimals);
        // 设置总供应量
        totalSupply = initialSupply;
        // 将全部代币铸造给合约创建者
        _balances[msg.sender] = initialSupply;
        // 发出Transfer事件，表示代币从0x0地址（铸造）转移到msg.sender
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    // --- 视图函数 (View Functions) ---

    /**
     * @notice 查询特定地址的代币余额
     * @param account 要查询余额的地址
     * @return 账户的代币余额
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice 查询授权额度
     * @param _owner 代币所有者的地址
     * @param spender 被授权方的地址
     * @return spender可以从_owner处转账的剩余额度
     */
    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    // --- 核心转账逻辑 (Internal Transfer Logic) ---

    /**
     * @notice 内部转账函数，包含税费逻辑
     * @param from 代币转出方地址
     * @param to 代币接收方地址
     * @param amount 要转账的代币原始数量 (含税)
     */
    function _transfer(address from, address to, uint256 amount) private {
        // 确保转出方和接收方地址都不是零地址
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // 确保转出方余额足够
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        // 1. 计算税费 (1% of amount)
        // 税费 = amount * TAX_RATE / TAX_DENOMINATOR
        uint256 taxAmount = amount * TAX_RATE / TAX_DENOMINATOR;
        // 2. 计算实际到账数量
        uint256 transferAmount = amount - taxAmount;

        // 3. 执行转账操作 (原子操作)

        // 从转出方扣除总额 (原始amount)
        _balances[from] -= amount;

        // 将税费转给合约创建者 (owner)
        // 注意：税费只在非owner转账给非owner时才计算，但为了简化逻辑，只要发生转账就计算税费
        if (taxAmount > 0) {
            _balances[owner] += taxAmount;
            // 发出税费转移事件
            emit Transfer(from, owner, taxAmount);
        }

        // 将实际到账数量转给接收方
        _balances[to] += transferAmount;
        // 发出实际转账事件
        emit Transfer(from, to, transferAmount);
    }

    // --- 外部函数 (External Functions) ---

    /**
     * @notice 标准转账函数
     * @param to 代币接收方地址
     * @param amount 要转账的代币数量 (包含将被扣除的1%税费)
     * @return 成功返回true
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        // 调用内部转账函数，转出方为消息发送者
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice 授权spender可以从msg.sender处转账一定数量的代币
     * @param spender 被授权方的地址
     * @param amount 授权的代币额度
     * @return 成功返回true
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        // 设置授权额度
        _allowances[msg.sender][spender] = amount;
        // 发出Approval事件
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice 授权转账函数，由被授权方调用
     * @param from 代币所有者的地址
     * @param to 代币接收方的地址
     * @param amount 要转账的代币数量 (包含将被扣除的1%税费)
     * @return 成功返回true
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // 检查被授权额度是否足够
        // 使用'unchecked'操作符来减少gas，因为它通常不会溢出，但在这里保持常规操作以确保安全。
        require(_allowances[from][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        // 调用内部转账函数，执行转账
        _transfer(from, to, amount);

        // 更新授权额度：从授权额度中减去已使用的数量
        _allowances[from][msg.sender] -= amount;

        return true;
    }
}