pragma solidity ^0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import {UniswapV3Factory} from "contracts/core/UniswapV3Factory.sol";
import {UniswapV3Pool} from "contracts/core/UniswapV3Pool.sol";
import {NonfungibleTokenPositionDescriptor} from "contracts/periphery/NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManager} from "contracts/periphery/NonfungiblePositionManager.sol";
import {CLGaugeFactory} from "contracts/gauge/CLGaugeFactory.sol";
import {CLGauge} from "contracts/gauge/CLGauge.sol";
import {MockWETH} from "contracts/test/MockWETH.sol";
import {MockVoter} from "contracts/test/MockVoter.sol";
import {Constants} from "./utils/Constants.sol";
import {Events} from "./utils/Events.sol";
import {PoolUtils} from "./utils/PoolUtils.sol";
import {Users} from "./utils/Users.sol";

contract BaseFixture is Test, Constants, Events, PoolUtils {
    UniswapV3Factory public poolFactory;
    UniswapV3Pool public poolImplementation;
    NonfungibleTokenPositionDescriptor public nftDescriptor;
    NonfungiblePositionManager public nft;
    CLGaugeFactory public gaugeFactory;
    CLGauge public gaugeImplementation;

    MockVoter public voter;
    MockWETH public weth;

    Users internal users;

    function setUp() public virtual {
        users = Users({
            owner: createUser("Owner"),
            feeManager: createUser("FeeManager"),
            alice: createUser("Alice"),
            bob: createUser("Bob"),
            charlie: createUser("Charlie")
        });

        weth = new MockWETH();
        voter = new MockVoter();

        poolImplementation = new UniswapV3Pool();
        poolFactory = new UniswapV3Factory(address(voter), address(poolImplementation));

        nftDescriptor = new NonfungibleTokenPositionDescriptor({
            _WETH9: address(weth),
            _nativeCurrencyLabelBytes: 0x4554480000000000000000000000000000000000000000000000000000000000 // 'ETH' as bytes32 string
        });
        nft = new NonfungiblePositionManager({
            _factory: address(poolFactory),
            _WETH9: address(weth),
            _tokenDescriptor_: address(nftDescriptor)
        });

        gaugeImplementation = new CLGauge();
        gaugeFactory = new CLGaugeFactory(address(voter), address(gaugeImplementation));

        voter.setGaugeFactory(address(gaugeFactory));

        poolFactory.setOwner(users.owner);
        poolFactory.setFeeManager(users.feeManager);

        labelContracts();
    }

    function labelContracts() internal {
        vm.label({account: address(weth), newLabel: "WETH"});
        vm.label({account: address(voter), newLabel: "Voter"});
        vm.label({account: address(nftDescriptor), newLabel: "NFT Descriptor"});
        vm.label({account: address(nft), newLabel: "NFT Manager"});
        vm.label({account: address(poolImplementation), newLabel: "Pool Implementation"});
        vm.label({account: address(poolFactory), newLabel: "Pool Factory"});
    }

    function createUser(string memory name) internal returns (address payable user) {
        user = payable(makeAddr({name: name}));
        vm.deal({account: user, newBalance: TOKEN_1 * 1000});
    }
}
