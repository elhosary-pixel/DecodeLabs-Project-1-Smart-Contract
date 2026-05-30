// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RobotFleet {
    
    // تعريف خصائص الروبوت
    struct Robot {
        bool isRegistered;
        bool isBusy;
        uint128 capabilities; // Capability Bitmask
    }

    mapping(address => Robot) public robots;
    mapping(uint256 => address) public activeTasks;

    // Multiplier Gate: للتعامل مع الأرقام العشرية
    uint256 constant SCALE_FACTOR = 10**7; 

    // تسجيل الأحداث على الشبكة
    event RobotRegistered(address indexed robotAddress, uint128 capabilities);
    event TaskAssigned(address indexed robotAddress, uint256 taskId);
    event TaskCompleted(address indexed robotAddress, uint256 taskId, uint256 scaledSensorData);

    // Checkpoint 1: Invalid Robot Validation (التأكد من تسجيل الروبوت)
    modifier onlyRegistered() {
        require(robots[msg.sender].isRegistered, "Checkpoint 1: Robot not registered.");
        _;
    }

    // Checkpoint 2: Concurrency Shield (منع التداخل وازدواجية المهام)
    modifier notBusy() {
        require(!robots[msg.sender].isBusy, "Checkpoint 2: Robot Busy.");
        _;
    }

    // دالة لتسجيل الروبوت في الأسطول
    function registerRobot(uint128 _capabilities) public {
        require(!robots[msg.sender].isRegistered, "Robot already registered.");
        robots[msg.sender] = Robot({
            isRegistered: true,
            isBusy: false,
            capabilities: _capabilities
        });
        emit RobotRegistered(msg.sender, _capabilities);
    }

    // دالة لتعيين مهمة للروبوت
    function assignTask(uint256 _taskId) public onlyRegistered notBusy {
        require(activeTasks[_taskId] == address(0), "Task already assigned to another robot.");
        robots[msg.sender].isBusy = true;
        activeTasks[_taskId] = msg.sender;
        emit TaskAssigned(msg.sender, _taskId);
    }

    // Checkpoint 3: Mismatched Completion (التأكد من هوية الروبوت المنهي للمهمة)
    function completeTask(uint256 _taskId, uint256 _rawSensorData) public onlyRegistered {
        require(robots[msg.sender].isBusy, "Robot is not currently executing a task.");
        require(activeTasks[_taskId] == msg.sender, "Checkpoint 3: Unauthorized. Mismatched Completion.");
        
        // تطبيق مضاعف الأرقام العشرية
        uint256 scaledData = _rawSensorData * SCALE_FACTOR;

        robots[msg.sender].isBusy = false;
        delete activeTasks[_taskId];
        emit TaskCompleted(msg.sender, _taskId, scaledData);
    }
}