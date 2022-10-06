/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
@testable import nRFMeshProvision

class AssigningGroupAddresses: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAssigningGroupAddress_empty() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC008) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC000)
    }
    
    func testAssigningGroupAddress_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xD015...0xD0FF) ],
                                      allocatedSceneRange: [])
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xD015)
    }
    
    func testAssigningGroupAddress_some() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC00F)
    }
    
    func testAssigningGroupAddress_no_more() {
        let meshNetwork = MeshNetwork(name: "Test network")
        
        let provisioner = Provisioner(name: "Test provisioner",
                                      allocatedUnicastRange: [ AddressRange(1...0x7FFF) ],
                                      allocatedGroupRange: [ AddressRange(0xC000...0xC001), AddressRange(0xC00F...0xC00F) ],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 3", address: 0xC00F)))
        
        let address = meshNetwork.nextAvailableGroupAddress(for: provisioner)
        
        XCTAssertNil(address)
    }

    func testGroupAddressInRange_invalid_range() {
        let meshNetwork = MeshNetwork(name: "Test network")
        // Not a group range
        let addressRange = AddressRange(0x0000...0x0001)

        let address = meshNetwork.nextAvailableGroupAddress(in: addressRange)

        XCTAssertNil(address)
    }

    func testGroupAddressInRange_empty() {
        let meshNetwork = MeshNetwork(name: "Test network")
        let addressRange = AddressRange(0xC000...0xC008)

        let address = meshNetwork.nextAvailableGroupAddress(in: addressRange)

        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC000)
    }

    func testGroupAddressInRange_basic() {
        let meshNetwork = MeshNetwork(name: "Test network")

        let addressRange = AddressRange(0xD015...0xD0FF)

        let address = meshNetwork.nextAvailableGroupAddress(in: addressRange)

        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xD015)
    }

    func testGroupAddressInRange_some() {
        let meshNetwork = MeshNetwork(name: "Test network")
        let addressRange = AddressRange(0xC000...0xC008)
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))

        let address = meshNetwork.nextAvailableGroupAddress(in: addressRange)

        XCTAssertNotNil(address)
        XCTAssertEqual(address!, 0xC002)
    }

    func testGroupAddressInRange_no_more() {
        let meshNetwork = MeshNetwork(name: "Test network")
        let addressRange = AddressRange(0xC000...0xC001)
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 1", address: 0xC000)))
        XCTAssertNoThrow(try meshNetwork.add(group: Group(name: "Group 2", address: 0xC001)))

        let address = meshNetwork.nextAvailableGroupAddress(in: addressRange)

        XCTAssertNil(address)
    }
    
    func testAssigningGroupAddressRanges_boundaries() {
        let meshNetwork = MeshNetwork(name: "Test network")
        let provisioner = Provisioner(name: "P0",
                                      allocatedUnicastRange: [AddressRange(0x0001...0x0001)],
                                      allocatedGroupRange: [AddressRange(0xC000...0xC000)],
                                      allocatedSceneRange: [])
        XCTAssertNoThrow(try meshNetwork.add(provisioner: provisioner, withAddress: nil))
        
        let newRangeNil = meshNetwork.nextAvailableGroupAddressRange(ofSize: 0)
        XCTAssertNil(newRangeNil)
        
        let newRange0 = meshNetwork.nextAvailableGroupAddressRange(ofSize: 1)
        XCTAssertNotNil(newRange0)
        XCTAssertEqual(newRange0?.lowerBound, 0xC001)
        XCTAssertEqual(newRange0?.upperBound, 0xC001)
        
        let newRange1 = meshNetwork.nextAvailableGroupAddressRange(ofSize: 2)
        XCTAssertNotNil(newRange1)
        XCTAssertEqual(newRange1?.lowerBound, 0xC001)
        XCTAssertEqual(newRange1?.upperBound, 0xC002)
        
        let newRange2 = meshNetwork.nextAvailableGroupAddressRange()
        XCTAssertNotNil(newRange2)
        XCTAssertEqual(newRange2?.lowerBound, 0xC001)
        XCTAssertEqual(newRange2?.upperBound, Address.maxGroupAddress)
        
        let newRange3 = meshNetwork.nextAvailableGroupAddressRange(ofSize: 0xFFFF)
        XCTAssertNotNil(newRange3)
        XCTAssertEqual(newRange3?.lowerBound, 0xC001)
        XCTAssertEqual(newRange3?.upperBound, Address.maxGroupAddress)
    }

}
