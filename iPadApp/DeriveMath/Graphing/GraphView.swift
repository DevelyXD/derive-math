import SwiftUI

struct GraphView: View {
    @State private var functions = ["sin(x)", "0.1*x^2-2"]
    @State private var xScale = 25.0
    @State private var scaleAtGestureStart: Double?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(functions.indices, id: \.self) { index in
                    TextField("f(x)", text: $functions[index])
                        .textFieldStyle(.roundedBorder)
                }
                Button("Add Function") { functions.append("") }
                GeometryReader { proxy in
                    Canvas { context, size in
                        drawAxes(context: &context, size: size)
                        let colours: [Color] = [.indigo, .orange, .green, .pink]
                        for (index, expression) in functions.enumerated() {
                            draw(expression, colour: colours[index % colours.count], context: &context, size: size)
                        }
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let start = scaleAtGestureStart ?? xScale
                                scaleAtGestureStart = start
                                xScale = min(100, max(8, start * Double(value.magnification)))
                            }
                            .onEnded { _ in scaleAtGestureStart = nil }
                    )
                }
            }
            .padding()
            .navigationTitle("Graphing")
        }
    }

    private func drawAxes(context: inout GraphicsContext, size: CGSize) {
        var axes = Path()
        axes.move(to: CGPoint(x: 0, y: size.height / 2)); axes.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        axes.move(to: CGPoint(x: size.width / 2, y: 0)); axes.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        context.stroke(axes, with: .color(.secondary), lineWidth: 1)
    }

    private func draw(_ expression: String, colour: Color, context: inout GraphicsContext, size: CGSize) {
        guard !expression.isEmpty else { return }
        var path = Path()
        var started = false
        for pixel in stride(from: 0.0, through: size.width, by: 2) {
            let x = (pixel - size.width / 2) / xScale
            guard let value = MathExpression(expression).evaluate(x: x) else { continue }
            let y = size.height / 2 - value * xScale
            guard y.isFinite, abs(y) < size.height * 4 else { started = false; continue }
            if started { path.addLine(to: CGPoint(x: pixel, y: y)) }
            else { path.move(to: CGPoint(x: pixel, y: y)); started = true }
        }
        context.stroke(path, with: .color(colour), lineWidth: 2)
    }
}

private struct MathExpression {
    let source: String
    init(_ source: String) { self.source = source }

    func evaluate(x: Double) -> Double? {
        var parser = Parser(source, x: x)
        guard let value = parser.expression() else { return nil }
        parser.skipSpaces()
        return parser.isAtEnd ? value : nil
    }

    private struct Parser {
        let characters: [Character]
        let x: Double
        var position = 0
        var isAtEnd: Bool { position >= characters.count }

        init(_ source: String, x: Double) {
            characters = Array(source.lowercased())
            self.x = x
        }

        mutating func expression() -> Double? {
            guard var value = term() else { return nil }
            while true {
                if consume("+") { guard let rhs = term() else { return nil }; value += rhs }
                else if consume("-") { guard let rhs = term() else { return nil }; value -= rhs }
                else { return value }
            }
        }

        mutating func term() -> Double? {
            guard var value = power() else { return nil }
            while true {
                if consume("*") { guard let rhs = power() else { return nil }; value *= rhs }
                else if consume("/") { guard let rhs = power() else { return nil }; value /= rhs }
                else { return value }
            }
        }

        mutating func power() -> Double? {
            guard var value = unary() else { return nil }
            if consume("^") { guard let exponent = power() else { return nil }; value = pow(value, exponent) }
            return value
        }

        mutating func unary() -> Double? {
            if consume("-") { return primary().map { -$0 } }
            if consume("+") { return primary() }
            return primary()
        }

        mutating func primary() -> Double? {
            if consume("(") {
                let value = expression()
                return consume(")") ? value : nil
            }
            if let number = number() { return number }
            let name = identifier()
            if name == "x" { return x }
            if name == "pi" { return .pi }
            if name == "e" { return M_E }
            guard !name.isEmpty, consume("("), let argument = expression(), consume(")") else { return nil }
            switch name {
            case "sin": return sin(argument)
            case "cos": return cos(argument)
            case "tan": return tan(argument)
            case "sqrt": return sqrt(argument)
            case "log", "ln": return log(argument)
            case "exp": return exp(argument)
            case "abs": return abs(argument)
            default: return nil
            }
        }

        mutating func number() -> Double? {
            skipSpaces()
            let start = position
            while !isAtEnd && (characters[position].isNumber || characters[position] == ".") { position += 1 }
            guard position > start else { return nil }
            return Double(String(characters[start..<position]))
        }

        mutating func identifier() -> String {
            skipSpaces()
            let start = position
            while !isAtEnd && characters[position].isLetter { position += 1 }
            return String(characters[start..<position])
        }

        mutating func consume(_ character: Character) -> Bool {
            skipSpaces()
            guard !isAtEnd, characters[position] == character else { return false }
            position += 1
            return true
        }

        mutating func skipSpaces() {
            while !isAtEnd && characters[position].isWhitespace { position += 1 }
        }
    }
}
