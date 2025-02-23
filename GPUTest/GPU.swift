//
//  GPU.swift
//  GPUTest
//
//  Created by vo1dw4lker on 12/02/2025.
// two arrays of 100000000 random elements times out on the CPU

import Metal
import MetalKit

class GPU {
    private var device: MTLDevice
    private var library: MTLLibrary
    private var commandQueue: MTLCommandQueue
    
    private var functions: [String:MTLFunction] = [:]
    private var pipelines: [String:MTLComputePipelineState] = [:]
    
    let count: Int
    var bufferA: MTLBuffer
    var bufferB: MTLBuffer
    var bufferResult: MTLBuffer
    var batchSize: Int
    
    
    init(numberOfFloats number: Int, safeMemory: Bool) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to make command queue")
        }
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Cannot make library")
        }
        self.library = library
        
        for function in library.functionNames {
            functions[function] = library.makeFunction(name: function)!
            pipelines[function] = try! device.makeComputePipelineState(function: functions[function]!)
        }
        assert(functions.isEmpty == false)
        assert(pipelines.isEmpty == false)
        
        count = number
        
        var maxMemory = device.recommendedMaxWorkingSetSize // for example 1000
        if (safeMemory) {
            maxMemory /= 4
        }
        
        let bytesPerElement = MemoryLayout<Float>.stride // for example 8
        let elementsPerBuffer = maxMemory / UInt64(3 * bytesPerElement) // for example 41
        // batchSize will be 123 elements per batch using 984 bytes of GPU memory at once
        // (out of 1000 free/recommended)
        batchSize = min(count, Int(elementsPerBuffer))
        
        let bufferSize = batchSize * bytesPerElement
        bufferA = device.makeBuffer(length: bufferSize, options: [])!
        bufferB = device.makeBuffer(length: bufferSize, options: [])!
        bufferResult = device.makeBuffer(length: bufferSize, options: [])!

    }
    
    public func startCalculation() -> [Float] {
        var results = [Float](repeating: 0, count: count)
       
        for i in stride(from: 0, to: count, by: batchSize) {
            generateRandomFloats(into: bufferA)
            generateRandomFloats(into: bufferB)
            
            runMultiplication()
            
            let resultPointer = bufferResult.contents()
            memcpy(&results[i], resultPointer, 10000 * MemoryLayout<Float>.stride)
        }
        
        return results
    }
    
    private func runMultiplication() {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipelines["multiplyArrays"]!)
        commandEncoder.setBuffer(bufferA, offset: 0, index: 0)
        commandEncoder.setBuffer(bufferB, offset: 0, index: 1)
        commandEncoder.setBuffer(bufferResult, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: batchSize, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: pipelines["multiplyArrays"]!.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func generateRandomFloats(into buffer: MTLBuffer) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        var seed = UInt32.random(in: 0...UInt32.max)
        let seedBuffer = device.makeBuffer(bytes: &seed, length: MemoryLayout<UInt32>.size)
        
        commandEncoder.setComputePipelineState(pipelines["rand"]!)
        commandEncoder.setBuffer(buffer, offset: 0, index: 0)
        commandEncoder.setBuffer(seedBuffer, offset: 0, index: 1)
        
        let threadsPerGrid = MTLSize(width: batchSize, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: pipelines["rand"]!.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
