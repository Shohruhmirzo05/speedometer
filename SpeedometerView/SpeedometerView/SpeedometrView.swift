//
//  SpeedometrView.swift
//  testscan
//
//  Created by Alijonov Shohruhmirzo on 02/08/25.
//

import SwiftUI

struct Tick: Identifiable {
    let id = UUID()
    let label: String
    let angle: Double
    let value: Double
}

class SpeedometrViewModel: ObservableObject {
    @Published var animatedProgress: Double = 0
    @Published var inputValue: String = ""
    let animationDuration: Double = 2
    let maxNeedleValue: Double = 100_000
    let radius: CGFloat = 140
    
    let tickValues: [Tick] = [
        Tick(label: "0", angle: -225, value: 0),
        Tick(label: "1k", angle: -180, value: 1_000),
        Tick(label: "5k", angle: -135, value: 5_000),
        Tick(label: "10k", angle: -90, value: 10_000),
        Tick(label: "25k", angle: -45, value: 25_000),
        Tick(label: "50k", angle: 0, value: 50_000),
        Tick(label: "100k+", angle: 45, value: 100_000)
    ]
    
    func needleAngle(for value: Double) -> Double {
        let clamped = max(0, min(value, 100_000))
        
        for i in 0..<tickValues.count - 1 {
            let start = tickValues[i]
            let end = tickValues[i + 1]
            
            if clamped >= start.value && clamped <= end.value {
                let t = (clamped - start.value) / (end.value - start.value)
                let angleSpacing = 45.0
                return 225 + Double(i) * angleSpacing + t * angleSpacing
            }
        }
        
        if clamped <= tickValues.first!.value {
            return 225
        }
        
        return 225 + Double(tickValues.count - 2) * 45.0
    }
    
    func formattedNumber(from input: String) -> String {
        guard let value = Double(input) else { return "0" }
        if value >= 1_000_000 {
            return "\(String(format: "%.1fM", value / 1_000_000))"
        } else if value >= 1_000 {
            return "\(String(format: "%.1fk", value / 1_000))"
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    func progressAmount(for value: Double) -> CGFloat {
        let clamped = max(0, min(value, 100_000))
        
        let angle = needleAngle(for: clamped)
        
        let startAngle = 225.0
        let endAngle = startAngle + Double(tickValues.count - 1) * 45.0
        
        let normalized = (angle - startAngle) / (endAngle - startAngle)
        return CGFloat(normalized * 0.75)
    }
}

struct SpeedometerView: View {
    
    @StateObject var viewModel = SpeedometrViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                BackgorundCircle()
                RotateCircle()
                TickleValues()
                ProgressNeedle()
                Text("\(viewModel.formattedNumber(from: viewModel.inputValue))")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .offset(y: 90)
            }
            SubmitButton()
        }
        .onAppear { viewModel.animatedProgress = 0 }
    }
    
    @ViewBuilder func ProgressNeedle() -> some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 4, height: 100)
            .cornerRadius(2)
            .offset(y: -50)
            .rotationEffect(.degrees(viewModel.needleAngle(for: viewModel.animatedProgress)))
            .animation(.easeInOut(duration: viewModel.animationDuration), value: viewModel.animatedProgress)
        Circle()
            .fill(Color.black)
            .frame(width: 50, height: 50)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder func TickleValues() -> some View {
        GeometryReader { geometry in
            ForEach(viewModel.tickValues) { tick in
                let angle = Angle(degrees: tick.angle)
                let tickX = geometry.size.width / 2 + viewModel.radius * cos(CGFloat(angle.radians))
                let tickY = geometry.size.height / 2 + viewModel.radius * sin(CGFloat(angle.radians))
                
                Text(tick.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .position(x: tickX, y: tickY)
            }
        }
        .frame(width: 290, height: 290)
    }
    
    @ViewBuilder func BackgorundCircle() -> some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.16, green: 0.21, blue: 0.26), Color(red: 0.06, green: 0.1, blue: 0.13)]),
                startPoint: .top,
                endPoint: .bottom))
            .frame(width: 320, height: 320)
            .overlay(
                Circle()
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 6)
            )
    }
    
    @ViewBuilder func RotateCircle() -> some View {
        Circle()
            .trim(from: 0, to: viewModel.progressAmount(for: viewModel.animatedProgress))
            .stroke(
                AngularGradient(gradient: Gradient(colors: [Color(red: 0.36, green: 0.78, blue: 1.0), Color(red: 0.24, green: 0.61, blue: 0.96)]), center: .center),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
            .rotationEffect(.degrees(viewModel.tickValues.first!.angle))
            .frame(width: 315, height: 315)
    }
    
    @ViewBuilder func SubmitButton() -> some View {
        VStack(spacing: 16) {
            TextField("Enter value (0-999999)", text: $viewModel.inputValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Submit") {
                guard let value = Double(viewModel.inputValue) else { return }
                
                let capped = min(value, viewModel.maxNeedleValue)
                viewModel.animatedProgress = 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: viewModel.animationDuration)) {
                        viewModel.animatedProgress = capped
                    }
                }
            }
            .disabled(viewModel.inputValue.isEmpty)
            .padding()
            .frame(maxWidth: .infinity)
            .background(viewModel.inputValue.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            if !viewModel.inputValue.isEmpty {
                if Double(viewModel.inputValue) == nil {
                    Text("Please enter a valid number")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    SpeedometerView()
        .preferredColorScheme(.dark)
}
