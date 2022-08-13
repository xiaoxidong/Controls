import SwiftUI

struct PolarCoordinate {
    var radius: Double
    var angle: Angle
}

class DraggableModel: ObservableObject {
    var value1: Binding<Double> = .constant(0)
    var value2: Binding<Double> = .constant(0)

    var layout: DraggableLayout = .rectilinear
    var rect: CGRect = .zero

    var touchLocation: CGPoint = .zero {
        didSet {
            guard touchLocation != .zero else { return }

            switch layout {
            case .rectilinear:
                value1.wrappedValue = max(0.0, min(1.0, touchLocation.x / rect.size.width))
                value2.wrappedValue = 1.0 - max(0.0, min(1.0, touchLocation.y / rect.size.height))

            case .relativeRectilinear(xSensitivity: let xSensitivity, ySensitivity: let ySensitivity):
                guard oldValue != .zero else { return }
                let temp1 = value1.wrappedValue + (touchLocation.x - oldValue.x) * xSensitivity / rect.size.width
                let temp2 = value2.wrappedValue - (touchLocation.y - oldValue.y) * ySensitivity / rect.size.height

                value1.wrappedValue = max(0, min(1, temp1))
                value2.wrappedValue = max(0, min(1, temp2))

            case .polar:
                let polar = polarCoordinate(point: touchLocation)
                value1.wrappedValue = polar.radius
                value2.wrappedValue = max(0.0, min(1.0, polar.angle.radians / (2.0 * .pi)))

            case .relativePolar(radialSensitivity: let radialSensitivity):
                guard oldValue != .zero else { return }
                let oldPolar = polarCoordinate(point: oldValue)
                let newPolar = polarCoordinate(point: touchLocation)

                let temp1 = value1.wrappedValue + (newPolar.radius - oldPolar.radius) * radialSensitivity
                let temp2 = value2.wrappedValue + (newPolar.angle.radians - oldPolar.angle.radians) / (2.0 * .pi)

                value1.wrappedValue = max(0, min(1, temp1))
                value2.wrappedValue = max(0, min(1, temp2))
            }
        }
    }

    func polarCoordinate(point: CGPoint) -> PolarCoordinate {
        // Calculate the x and y distances from the center
        let deltaX = (point.x - rect.midX) / (rect.width / 2.0)
        let deltaY = (point.y - rect.midY) / (rect.height / 2.0)

        // Convert to polar
        let radius = max(0.0, min(1.0, sqrt(pow(deltaX, 2) + pow(deltaY, 2))))
        var theta = atan(deltaY / deltaX)

        // Math to rotate to traditional knob orientiation
        theta += .pi * (deltaX > 0 ? 1.5 : 0.5)

        return PolarCoordinate(radius: radius, angle: Angle(radians: theta))
    }
}
