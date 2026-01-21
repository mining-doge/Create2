// test/CounterFactory.t.sol
import "forge-std/Test.sol";
import "../src/CounterFactory.sol";

contract CounterFactoryTest is Test {
    CounterFactory factory;

    function setUp() public {
        factory = new CounterFactory();
    }

    function testPredictAddress() public {
        bytes32 salt = bytes32(uint256(123456));
        address predicted = factory.predictCounterAddress(salt);
        console.log("Predicted Counter address:", predicted);

        // 实际部署验证
        address deployed = factory.deployCounter(salt);
        assertEq(deployed, predicted);
    }
}
