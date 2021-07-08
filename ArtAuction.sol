pragma solidity >=0.4.22 <0.6.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol";

contract ArtAuction {
    using SafeMath for uint;
    address payable deployer = msg.sender;
    address payable public beneficiary;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        address payable _beneficiary
    ) public {
        deployer = msg.sender; // set as the ArtMarket
        beneficiary = _beneficiary;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(address payable sender) public payable {
        // If the bid is not higher, send the
        // money back.
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        require(!ended, "auctionEnd has already been called.");

        if (highestBid != 0) {

            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = sender;
        highestBid = msg.value;
        emit HighestBidIncreased(sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {

            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function pendingReturn(address sender) public view returns(uint) {
        return pendingReturns[sender];
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {

        require(!ended, "auctionEnd has already been called.");
        require(msg.sender == deployer, "You are not the auction deployer!");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    
        //uint auction_commission = highestBid * 3 / 100;
        //uint payment = highestBid.sub(auction_commission); 
        
        beneficiary.transfer(highestBid);
        //deployer.transfer(auction_commission);

    }

    function resetAuction () public {
        //Reset auction if buyer is unsatisfied
        highestBidder = address(0);
        highestBid = 0;
        ended = false;
    }
    
    function () external payable {
        //auctionEnded function is called in the fallback function
       auctionEnd();
    }
    
}