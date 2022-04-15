// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DSocietyChat is AccessControl {

    event NewUser(string name, address sender);
    event NewMessage(string name, address sender, uint timestamp, string msg, uint roomId);
    event RoomJoin(address sender, uint roomId);

    uint public messageCost;
    uint public createRoomCost;
    
    // stores the default name of an user
    struct User {
        string name;
    }

    // message construct stores the single chat message and its metadata
    struct Message {
        string name;
        address sender;
        uint timestamp;
        string msg;
    }

    //room construct storing room info
    struct Room {
        string name;
        address createdBy;
    }

    // Collection of users registered on the application
    mapping(address => User) public userList;
    // Rooms
    Room[] public rooms;
    // Mapping messages to rooms
    mapping(uint => Message[]) public roomMessages;
    // Mapping users to their current room
    mapping(address => uint) public userRoom;

    // Token Contract
    IERC20 public DSocial;

    constructor() {
        // Give admin role to deploying address
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Initialize rooms
        rooms.push(Room("General", msg.sender));
    }

    // Sets the contract for the ERC20 token used
    function setDSocialContract(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        DSocial = IERC20(_address);
    }

    // Set cost per message    
    function setMessageCost(uint _cost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        messageCost = _cost;
    }

    // Set cost for creating a room    
    function setCreateRoomCost(uint _cost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        createRoomCost = _cost;
    }

    // Delete registered user
    function deleteUser() public {
        require(checkUserExists(msg.sender), "User is not registered!");
        delete userRoom[msg.sender];
        delete userList[msg.sender];
    }
    
    // It checks whether a user(identified by its public key)
    // has created an account on this application or not
    function checkUserExists(address pubkey) public view returns(bool) {
        return bytes(userList[pubkey].name).length > 0;
    }

    // It checks whether a room(identified by its id)
    // has created an account on this application or not
    function checkRoomExists(uint _roomId) public view returns(bool) {
        return rooms.length > _roomId;
    }
    
    // Registers the caller(msg.sender) to our app with a non-empty username
    function createAccount(string calldata name) external {
        require(checkUserExists(msg.sender)==false, "User already exists!");
        require(bytes(name).length>0, "Username cannot be empty!"); 
        userList[msg.sender].name = name;
        userRoom[msg.sender] = 0;
        emit NewUser(name, msg.sender);
    }

    // Create a new room
    function createRoom(string calldata _name) external returns(uint) {
        require(checkUserExists(msg.sender), "User is not registered!");
        require(bytes(_name).length>0, "Room name cannot be empty!");
        require(getAllowance() >= createRoomCost, "Please deposit more tokens before transferring");
        DSocial.transferFrom(msg.sender, address(this), createRoomCost);
        rooms.push(Room(_name, msg.sender));
        uint _roomId = rooms.length - 1;
        userRoom[msg.sender] = _roomId;
        emit RoomJoin(msg.sender, _roomId);
        return _roomId;
    }

    // Join a room
    function joinRoom(uint _roomId) external returns(uint){
        require(checkUserExists(msg.sender), "User is not registered!");
        require(checkRoomExists(_roomId), "Room doesn't exist!");
        require(userRoom[msg.sender] != _roomId, "User already in room!");
        userRoom[msg.sender] = _roomId;
        emit RoomJoin(msg.sender, _roomId);
        return _roomId;
    }
    
    // Returns the default name provided by an user
    function getUsername(address pubkey) public view returns(string memory) {
        require(checkUserExists(pubkey), "User is not registered!");
        return userList[pubkey].name;
    }

    // Returns the room for a user
    function getUserRoom(address _pubkey) public view returns(uint) {
        return userRoom[_pubkey];
    }

    function getContractTokenBalance() public view onlyRole(DEFAULT_ADMIN_ROLE) returns(uint){
        return DSocial.balanceOf(address(this));
    }

    function getAllowance() public view returns(uint){
        return DSocial.allowance(msg.sender, address(this));
    }
    
    // Sends a new message to the room
    function sendMessage(string calldata _msg) external {
        require(checkUserExists(msg.sender), "User is not registered!");
        require(bytes(_msg).length>0, "Message cannot be empty!");
        require(getAllowance() >= messageCost, "Please deposit more tokens before transferring");
        DSocial.transferFrom(msg.sender, address(this), messageCost);
        string memory name = getUsername(msg.sender);
        Message memory newMsg = Message(name, msg.sender, block.timestamp, _msg);
        uint _userRoomId = userRoom[msg.sender];
        roomMessages[_userRoomId].push(newMsg);
        emit NewMessage(name, msg.sender, block.timestamp, _msg, _userRoomId);
    }

    // Returns all the chat messages communicated in a channel
    function readMessage(uint _maxChatDisplay) external view returns(Message[] memory) {
        uint _userRoomId = userRoom[msg.sender];
        uint _roomLength = roomMessages[_userRoomId].length;
        if ( _maxChatDisplay >= _roomLength) {
            return roomMessages[_userRoomId];
        }
        uint _startIndex = _roomLength - _maxChatDisplay;
        Message[] memory _slicedMessages = new Message[](_maxChatDisplay);
        for (uint idx = _startIndex; idx < _roomLength; idx++) {
            uint _i = idx - _startIndex;
            _slicedMessages[_i] = roomMessages[_userRoomId][idx];
        }
        return _slicedMessages;
    }

}