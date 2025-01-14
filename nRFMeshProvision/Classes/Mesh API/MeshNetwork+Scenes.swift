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
    
    /// Adds a new Scene to the network.
    ///
    /// If the mesh network already contains a Scene with the same number,
    /// this method throws an error.
    ///
    /// - parameters:
    ///   - scene: The Scene number to be added.
    ///   - name: The human-readable name of the Scene.
    /// - throws: This method throws an error if a Scene with the same number
    ///           already exists in the mesh network.
    func add(scene: SceneNumber, name: String) throws {
        guard scenes[scene] == nil else {
            throw MeshNetworkError.sceneAlreadyExists
        }
        add(scene: Scene(scene, name: name))
    }
    
    /// Removes the given Scene from the network.
    ///
    /// The Scene must not be in use, i.e. no Node must have it in its Scene Register.
    ///
    /// - parameter scene: The Scene to be removed.
    /// - throws: This method throws ``MeshNetworkError/sceneInUse`` when the
    ///           Scene is in use in this mesh network.
    func remove(scene: SceneNumber) throws {
        if let index = scenes.firstIndex(where: { $0.number == scene }) {
            if scenes[index].isUsed {
                throw MeshNetworkError.sceneInUse
            }
            scenes.remove(at: index).meshNetwork = nil
            timestamp = Date()
        }
    }
    
    /// Returns known Nodes containing at least one Element with Scene Register
    /// storing the given Scene.
    ///
    /// Starting from version 3.3.0, this method returns also Nodes with more than one
    /// Scene Register, of which at least one has the given Scene stored.
    ///
    /// - parameter scene: The scene to look for.
    /// - returns: List of Nodes with at least one Scene Register storing the given Scene.
    func nodes(registeredTo scene: SceneNumber) -> [Node] {
        return scenes[scene]?.nodes ?? []
    }

    /// Returns the next available Scene number in given range for local provisioner
    /// that can be assigned to a new Scene.
    ///
    /// - parameter range: Scene number range.
    /// - returns: The next available Scene number that can be assigned to a new Scene,
    ///            or `nil`, if there are no more available numbers in the allocated range.
    func nextAvailableScene(in range: SceneRange) -> Address? {
        guard range.isValid else {
            return nil
        }

        let assignedSceneNumbers = scenes.map { $0.number }
        for number in range.range where !assignedSceneNumbers.contains(number) {
            return number
        }
        // No scene number was found :(
        return nil
    }

    /// Returns the next available Scene number from the Provisioner's range
    /// that can be assigned to a new Scene.
    ///
    /// - parameter provisioner: The Provisioner, which range is to be used for address
    ///                          generation.
    /// - returns: The next available Scene number that can be assigned to a new Scene,
    ///            or `nil`, if there are no more available numbers in the allocated range.
    func nextAvailableScene(for provisioner: Provisioner) -> SceneNumber? {
        for range in provisioner.allocatedSceneRange {
            if let number = nextAvailableScene(in: range) {
                return number
            }
        }
        // No scene number was found :(
        return nil
    }
    
    /// Returns the next available Scene number from the local Provisioner's range
    /// that can be assigned to a new Scene.
    ///
    /// - returns: The next available Scene number that can be assigned to a new Scene,
    ///            or `nil`, if there are no more available numbers in the allocated range.
    func nextAvailableScene() -> SceneNumber? {
        return localProvisioner.map { nextAvailableScene(for: $0) } ?? nil
    }
    
}
