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

import Foundation

public extension MeshNetwork {
    
    /// Returns whether the given number of Unicast Addresses starting
    /// from the given one are valid, that is they are all in Unicast
    /// Address range.
    ///
    /// - parameters:
    ///   - address: The first address to check.
    ///   - count:   Number of addresses to check.
    /// - returns: `True`, if the address range is valid, `false` otherwise.
    func isAddressRangeValid(_ address: Address, elementsCount count: UInt8) -> Bool {
        return AddressRange(from: address, elementsCount: count).isUnicastRange
    }
    
    /// Returns whether the given address range can be assigned to a new Node.
    ///
    /// This method does not check if the range is allocated to the current Provisioner.
    /// For that, use ``Provisioner/isAddressInAllocatedRange(_:elementCount:)``.
    ///
    /// - parameters:
    ///   - range: The address range to check.
    /// - returns: `True`, if the address is available, `false` otherwise.
    func isAddressRangeAvailable(_ range: AddressRange) -> Bool {
        return range.isUnicastRange &&
               !nodes.contains { $0.contains(elementsWithAddressesOverlapping: range) } &&
               !(networkExclusions?.contains(range, forIvIndex: ivIndex) ?? false)
    }
    
    /// Returns whether the given address can be assigned to a Node with given number of
    /// Elements.
    ///
    /// - parameters:
    ///   - address: The first address to check.
    ///   - count:   Number of addresses to check.
    /// - returns: `True`, if the address is available, `false` otherwise.
    func isAddress(_ address: Address, availableForElementsCount count: UInt8) -> Bool {
        let range = AddressRange(from: address, elementsCount: count)
        return isAddressRangeAvailable(range)
    }
    
    /// Returns whether the given address can be reassigned to the given Node.
    ///
    /// The Unicast Addresses assigned to the given Node are excluded from checking
    /// address collisions.
    ///
    /// - parameters:
    ///   - address: The first address to check.
    ///   - node:    The Node, which address is to change. It will be excluded
    ///              from checking address collisions.
    /// - returns: `True`, if the address is available, `false` otherwise.
    func isAddress(_ address: Address, availableFor node: Node) -> Bool {
        let range = AddressRange(from: address, elementsCount: node.elementsCount)
        let otherNodes = nodes.filter { $0 != node }
        return range.isUnicastRange &&
               !otherNodes.contains { $0.contains(elementsWithAddressesOverlapping: range) } &&
               !(networkExclusions?.contains(range, forIvIndex: ivIndex) ?? false)
    }
    
    /// Returns whether the given address can be assigned to a new Node
    /// with given number of Elements.
    ///
    /// - parameters:
    ///   - address: The first address to check.
    ///   - count:   Number of addresses to check.
    ///   - node:    The Node, which address is to change. It will be excluded
    ///              from checking address collisions.
    /// - returns: `True`, if the address range is available, `false` otherwise.
    @available(*, deprecated, message: "Use isAddress(_:availableFor:) or isAddress(_:availableForElementsCount:) instead")
    func isAddressRangeAvailable(_ address: Address, elementsCount count: UInt8, for node: Node? = nil) -> Bool {
        let range = AddressRange(from: address, elementsCount: count)
        let otherNodes = nodes.filter { $0 != node }
        return range.isUnicastRange &&
               !otherNodes.contains { $0.contains(elementsWithAddressesOverlapping: range) } &&
               !(networkExclusions?.contains(range, forIvIndex: ivIndex) ?? false)
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new node with 1 element. The element will be
    /// identified by the returned address.
    ///
    /// - parameters:
    ///   - offset: Minimum Unicast Address to be assigned.
    ///   - provisioner:   The Provisioner that is creating the node.
    ///                    The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(startingFrom offset: Address = Address.minUnicastAddress,
                                     using provisioner: Provisioner) -> Address? {
        return nextAvailableUnicastAddress(startingFrom: offset, for: 1,
                                           elementsUsing: provisioner)
    }
    
    /// Returns the next available Unicast Address from the local Provisioner's range
    /// that can be assigned to a new node with given number of elements.
    /// The 0'th element is identified by the node's Unicast Address.
    /// Each following element is identified by a subsequent Unicast Address.
    ///
    /// - parameters:
    ///   - offset: Minimum Unicast Address to be assigned.
    ///   - elementsCount: The number of Node's elements. Each element will be
    ///                    identified by a subsequent Unicast Address.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(startingFrom offset: Address = Address.minUnicastAddress,
                                     forElementsCount elementsCount: UInt8) -> Address? {
        return localProvisioner.map {
            nextAvailableUnicastAddress(startingFrom: offset, for: elementsCount, elementsUsing: $0)
        } ?? nil
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new node with given number of elements.
    /// The 0'th element is identified by the node's Unicast Address.
    /// Each following element is identified by a subsequent Unicast Address.
    ///
    /// - parameters:
    ///   - offset: Minimum Unicast Address to be assigned.
    ///   - elementsCount: The number of Node's elements. Each element will be
    ///                    identified by a subsequent Unicast Address.
    ///   - provisioner:   The Provisioner that is creating the node.
    ///                    The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(startingFrom offset: Address = Address.minUnicastAddress,
                                     for elementsCount: UInt8,
                                     elementsUsing provisioner: Provisioner) -> Address? {
        let exclusions = networkExclusions?.excludedAddresses(forIvIndex: ivIndex).sorted() ?? []
        let usedAddresses = (exclusions + nodes
            .flatMap { node in node.elements }
            .map { element in element.unicastAddress })
            .sorted()
        
        // Iterate through all addresses just once, while iterating over ranges.
        for range in provisioner.allocatedUnicastRange {
            // Start from the beginning of the current range.
            var address = range.lowAddress
            
            if range.contains(offset) && address < offset {
                address = offset
            }
            
            // Iterate through addresses that weren't checked yet.
            for index in 0..<usedAddresses.count {
                let usedAddress = usedAddresses[index]
                
                // Skip addresses below the range.
                if address > usedAddress {
                    continue
                }
                
                if address + UInt16(elementsCount) - 1 < usedAddress {
                    return address
                }
                
                address = usedAddress + 1
                
                // If the new address is outside of the range, go to the next one.
                if address + UInt16(elementsCount) - 1 > range.highAddress {
                    break
                }
            }
            
            // If the range has available space, return the address.
            if address + UInt16(elementsCount) - 1 <= range.highAddress {
                return address
            }
        }
        // No address was found :(
        return nil
    }
    
    /// Returns the next available Unicast Address from the Provisioner's range
    /// that can be assigned to a new Provisioner's node.
    ///
    /// This method is assuming that the Provisioner has only 1 element.
    ///
    /// - parameter provisioner: The Provisioner that is creating the Node for itself.
    ///                          The address will be taken from it's allocated range.
    /// - returns: The next available Unicast Address that can be assigned to a node,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableUnicastAddress(for provisioner: Provisioner) -> Address? {
        return nextAvailableUnicastAddress(for: 1, elementsUsing: provisioner)
    }

    /// Returns the next available Group Address in given address range for local provisioner
    /// that can be assigned to a new Group.
    ///
    /// - parameter range: Group address range.
    /// - returns: The next available Group Address that can be assigned to a new Group,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableGroupAddress(in range: AddressRange) -> Address? {
        guard range.isGroupRange else {
            return nil
        }

        let assignedGroupAddresses = groups.map { $0.address.address }
        for address in range.range where !assignedGroupAddresses.contains(address) {
            return address
        }
        // No group address was found :(
        return nil
    }

    
    /// Returns the next available Group Address from the Provisioner's range
    /// that can be assigned to a new Group.
    ///
    /// - parameter provisioner: The Provisioner, which range is to be used for address
    ///                          generation.
    /// - returns: The next available Group Address that can be assigned to a new Group,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableGroupAddress(for provisioner: Provisioner) -> Address? {
        for range in provisioner.allocatedGroupRange {
            if let address = nextAvailableGroupAddress(in: range) {
                return address
            }
        }
        // No address was found :(
        return nil
    }
    
    /// Returns the next available Group Address from the local Provisioner's range
    /// that can be assigned to a new Group.
    ///
    /// - returns: The next available Group Address that can be assigned to a new Group,
    ///            or `nil`, if there are no more available addresses in the allocated range.
    func nextAvailableGroupAddress() -> Address? {
        return localProvisioner.map { nextAvailableGroupAddress(for: $0) } ?? nil
    }
    
}
