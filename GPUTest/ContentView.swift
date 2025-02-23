//
//  ContentView.swift
//  GPUTest
//
//  Created by vo1dw4lker on 12/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var count = 0.0
    @State private var safeMemory = true
    
    @State private var editorHeight = 0
    @State private var text = ""
    @State private var atWork = false
    
    var body: some View {
        VStack {
            withAnimation {
                Slider(value: $count, in: 0...1_000_000_000, step: 5_000_000)
            }
            
            Text("Number of floats to multiply: \(Int(count))")
                .padding(.bottom)
            
            ZStack {
                HStack {
                    Toggle("Safe memory", isOn: $safeMemory)
                    Spacer()
                }
                
                if (atWork) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: start) {
                        Text("Start")
                    }
                }
            }
            
            TextEditor(text: $text)
                .frame(width: 800, height: CGFloat(editorHeight), alignment: .center)
            
        }
        .padding()
        
        
    }
    
    private func start() {
        withAnimation {
            editorHeight = 0
        }
        
        if count == 0.0 {
            return
        }
        
        let gpu = GPU(numberOfFloats: Int(count), safeMemory: safeMemory)
        
        withAnimation {
            atWork = true
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [Float] = []
            let clock = ContinuousClock()
            let elapsed = clock.measure {
                result = gpu.startCalculation()
            }
            
            DispatchQueue.main.async {
                var resultString = "Elapsed: \(elapsed)\n"
                for i in 0..<5000 {
                    resultString += "\(i): \(String(format: "%.4f", result[i]))\n"
                   }
                
                atWork = false
                withAnimation {
                    text = resultString
                    editorHeight = 300
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
