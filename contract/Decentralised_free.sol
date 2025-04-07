// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreelancePaymentSystem {
    enum JobStatus { Pending, InProgress, Completed, Paid }

    struct Freelancer {
        address payable wallet;
        uint256 balance;
    }

    struct Client {
        address payable wallet;
    }

    struct Job {
        uint256 jobId;
        string description;
        uint256 amount;
        uint256 dueDate;
        JobStatus status;
        address payable freelancer;
        address payable client;
    }

    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;
    mapping(address => Freelancer) public freelancers;
    mapping(address => Client) public clients;

    event JobPosted(uint256 jobId, address client, string description, uint256 amount);
    event JobStarted(uint256 jobId, address freelancer);
    event JobCompleted(uint256 jobId);
    event JobPaid(uint256 jobId, uint256 amount);

    modifier onlyClient(uint256 jobId) {
        require(msg.sender == jobs[jobId].client, "Only the client can call this function.");
        _;
    }

    modifier onlyFreelancer(uint256 jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only the freelancer can call this function.");
        _;
    }

    modifier jobExists(uint256 jobId) {
        require(jobs[jobId].jobId != 0, "Job does not exist.");
        _;
    }

    modifier jobNotPaid(uint256 jobId) {
        require(jobs[jobId].status != JobStatus.Paid, "Job has already been paid.");
        _;
    }

    modifier jobInProgress(uint256 jobId) {
        require(jobs[jobId].status == JobStatus.InProgress, "Job is not in progress.");
        _;
    }

    function registerFreelancer(address payable _wallet) public {
        freelancers[_wallet].wallet = _wallet;
        freelancers[_wallet].balance = 0;
    }

    function registerClient(address payable _wallet) public {
        clients[_wallet].wallet = _wallet;
    }

    function postJob(string memory _description, uint256 _amount, uint256 _dueDate) public returns (uint256) {
        jobCount++;
        uint256 jobId = jobCount;
        jobs[jobId] = Job({
            jobId: jobId,
            description: _description,
            amount: _amount,
            dueDate: _dueDate,
            status: JobStatus.Pending,
            freelancer: payable(address(0)),
            client: payable(msg.sender)
        });
        emit JobPosted(jobId, msg.sender, _description, _amount);
        return jobId;
    }

    function assignFreelancer(uint256 jobId, address payable _freelancer) public onlyClient(jobId) jobExists(jobId) {
        jobs[jobId].freelancer = _freelancer;
        jobs[jobId].status = JobStatus.InProgress;
        emit JobStarted(jobId, _freelancer);
    }

    function markJobAsCompleted(uint256 jobId) public onlyFreelancer(jobId) jobInProgress(jobId) {
        jobs[jobId].status = JobStatus.Completed;
        emit JobCompleted(jobId);
    }

    function releasePayment(uint256 jobId) public onlyClient(jobId) jobExists(jobId) jobNotPaid(jobId) {
        require(block.timestamp >= jobs[jobId].dueDate, "Job deadline not reached.");
        uint256 amount = jobs[jobId].amount;
        jobs[jobId].status = JobStatus.Paid;
        freelancers[jobs[jobId].freelancer].wallet.transfer(amount);
        emit JobPaid(jobId, amount);
    }

    function getFreelancerBalance(address freelancer) public view returns (uint256) {
        return freelancers[freelancer].balance;
    }

    receive() external payable {}
}
