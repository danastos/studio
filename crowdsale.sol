pragma solidity ^ 0.4.8;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";

import "./TheStudioToken.sol";

contract Studio_crowdsale is usingOraclize
{
    TheStudioToken token_contract;
    
    using strings for *;
    
    uint256 token_price = 50; //assumed preoffering price token price is 0.50 dollars per token, 5 cents = .05 dollars

    bool pre_Sale = true;
    
    //ico startdate enddate;
    uint256 startdate;
    uint256 enddate;
    
    uint decimals = 4;
    
    uint public lastprice;
    string public lastpriceString;
    
    address public SaleToken;

    
    //flag to indicate whether crowdsale is paused or not
    bool public stopped = false;
    
    address  owner;
    
    uint public totalEtherRaised;
    
     // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    event Transfer(address indexed to, uint value);
    
    event No_Of_Token(uint tokens);

    uint public counter = 0;

    mapping(bytes32 => address) userAddress; // mapping to store user address
    mapping(address => uint) uservalue; // mapping to store user value
    mapping(bytes32 => bytes32) userqueryID; // mapping to store user oracalize query id

  
    // called by the owner on emergency, pause crowdsale
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

    // called by the owner on end of emergency, resumes crowdsale
    function release() external onlyOwner {
        stopped = false;
    }

    function Studio_crowdsale()
    {
        
        address _token = 0xcb4690bf89d60Afc2BA181afd2782BFA2f55cCB2;
        owner = msg.sender;
        token_contract = TheStudioToken(_token);
        SaleToken = _token;
        
    }
    
     // start crowdsale/ico by calling this function
    function start_crowdsale() public onlyOwner {
        pre_Sale = false;
        counter = 0;
        token_price = 100;
        startdate = now;
        enddate = startdate + 180 days;

    }
    
     // unnamed function whenever any one sends ether to this smart contract address it wil fall in this function which is payable
    function() payable {
      if (!stopped) {
          if (pre_Sale && msg.sender != owner) {
               bytes32 ID2 = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD",500000);
               userAddress[ID2] = msg.sender;
                uservalue[msg.sender] = msg.value;
                
                userqueryID[ID2] = ID2;
            } else if (!pre_Sale) {
               if (msg.sender != owner && now >= startdate && now < enddate) {
                  bytes32 ID = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD",500000);
                  userAddress[ID] = msg.sender;
                    uservalue[msg.sender] = msg.value;
                    userqueryID[ID] = ID;
             } else if (msg.sender != owner && now >= enddate) {
                    revert();
                }

            }


        }
        else
        {
            revert();
        }


    }
    
    // end crowdsale sholud be called by owner after ico end date
    function end_crowdsale() public onlyOwner {
        stopped = true;
     }
     
     function totalEtherRaised() returns ( uint ){
         
         return totalEtherRaised;
         
     }
     
     // callback function of oracalize which is called when oracalize query return result
    function __callback(bytes32 myid, string result)  {
        if (msg.sender != oraclize_cbAddress()) {
            // just to be sure the calling address is the Oraclize authorized one
            throw;
        }

        lastpriceString  = result;
        if (userqueryID[myid] == myid) {
       
         var s = result.toSlice();
         strings.slice memory part;
         uint finanl_price_=stringToUint(s.split(".".toSlice()).toString()); 
         lastprice = finanl_price_;
      //  uint finanl_price_ = stringToUint(usd_price_a.toString()); 
        if (counter > (10000000000)) {
                token_price = ((counter / (10000000000)) * 5) + token_price; // increase token price for every million purchase by 5 cents

                counter = 0;
            }
          
           uint no_of_token = ((finanl_price_ * uservalue[userAddress[myid]]) * 10**decimals) / (token_price * 10**16); 
           No_Of_Token(no_of_token);
           if(token_contract.balanceOf( address(this) ) > no_of_token)
           {
      
            token_contract.transfer(msg.sender ,no_of_token);
            Transfer( userAddress[myid] , no_of_token);
          
            counter = counter + no_of_token;
            
         
        }
       }


    }
    
     //Below function will convert string to integer removing decimal
   function stringToUint(string s) private constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
               // usd_price=result;
                
            }
        }
   }
   
   
     function drain() public onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
    
    function drainStudio() public onlyOwner {
        
        if ( pre_Sale ){
            token_contract.transfer( owner , token_contract.balanceOf( address(this) ) );
        }
        
    }
    
    
     function transferOwnership ( address newOwner) public onlyOwner {
        
        owner = newOwner;
        
        
    }
    

    
}