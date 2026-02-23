import Foundation

// MARK: - Config Validator

/// Validates widget configs for correctness and safety before rendering.
public struct ConfigValidator: Sendable {

    public init() {}

    // MARK: - Validation Limits

    public static let maxNestingDepth = 5
    public static let maxNodeCount = 50

    // MARK: - Validation

    public struct ValidationResult: Sendable {
        public let isValid: Bool
        public let errors: [ValidationError]
        public let warnings: [String]

        public static let valid = ValidationResult(isValid: true, errors: [], warnings: [])
    }

    public enum ValidationError: Error, Sendable, CustomStringConvertible {
        case emptyRoot
        case nestingTooDeep(depth: Int, max: Int)
        case tooManyNodes(count: Int, max: Int)
        case invalidSchemaVersion(String)
        case emptyTextContent
        case invalidHexColor(String)
        case invalidGaugeValue(Double)
        case emptyStackChildren
        case invalidImageSource

        public var description: String {
            switch self {
            case .emptyRoot:
                return "Widget config has no root node"
            case .nestingTooDeep(let depth, let max):
                return "Nesting depth \(depth) exceeds maximum of \(max)"
            case .tooManyNodes(let count, let max):
                return "Node count \(count) exceeds maximum of \(max)"
            case .invalidSchemaVersion(let version):
                return "Unsupported schema version: \(version)"
            case .emptyTextContent:
                return "Text node has empty content"
            case .invalidHexColor(let hex):
                return "Invalid hex color: \(hex)"
            case .invalidGaugeValue(let value):
                return "Gauge value \(value) must be between 0.0 and 1.0"
            case .emptyStackChildren:
                return "Stack has no children"
            case .invalidImageSource:
                return "Image has invalid source"
            }
        }
    }

    /// Validate a complete widget config
    public func validate(_ config: WidgetConfig) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []

        // Check schema version
        if config.schemaVersion != SchemaVersion.current {
            warnings.append("Schema version \(config.schemaVersion) differs from current \(SchemaVersion.current)")
        }

        // Count nodes and check depth
        var nodeCount = 0
        var maxDepth = 0
        countNodes(config.root, depth: 1, nodeCount: &nodeCount, maxDepth: &maxDepth)

        if maxDepth > Self.maxNestingDepth {
            errors.append(.nestingTooDeep(depth: maxDepth, max: Self.maxNestingDepth))
        }
        if nodeCount > Self.maxNodeCount {
            errors.append(.tooManyNodes(count: nodeCount, max: Self.maxNodeCount))
        }

        // Validate nodes recursively
        validateNode(config.root, errors: &errors, warnings: &warnings)

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Private Helpers

    private func countNodes(_ node: WidgetNode, depth: Int, nodeCount: inout Int, maxDepth: inout Int) {
        nodeCount += 1
        maxDepth = max(maxDepth, depth)

        for child in node.children {
            countNodes(child, depth: depth + 1, nodeCount: &nodeCount, maxDepth: &maxDepth)
        }
    }

    private func validateNode(_ node: WidgetNode, errors: inout [ValidationError], warnings: inout [String]) {
        switch node {
        case .text(let props):
            if props.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !props.content.contains("{{") {
                errors.append(.emptyTextContent)
            }
            if let color = props.color {
                validateColor(color, errors: &errors)
            }

        case .gauge(let props):
            if props.value < 0.0 || props.value > 1.0 {
                errors.append(.invalidGaugeValue(props.value))
            }

        case .vStack(let props), .hStack(let props):
            if props.children.isEmpty {
                warnings.append("Stack has no children — it will render as empty space")
            }
            for child in props.children {
                validateNode(child, errors: &errors, warnings: &warnings)
            }

        case .zStack(let props):
            if props.children.isEmpty {
                warnings.append("ZStack has no children — it will render as empty space")
            }
            for child in props.children {
                validateNode(child, errors: &errors, warnings: &warnings)
            }

        case .frame(let props):
            validateNode(props.child, errors: &errors, warnings: &warnings)

        case .padding(let props):
            validateNode(props.child, errors: &errors, warnings: &warnings)

        case .sfSymbol(let props):
            if props.systemName.isEmpty {
                warnings.append("SF Symbol has empty system name")
            }

        case .image, .spacer, .divider, .containerRelativeShape:
            break
        }
    }

    private func validateColor(_ color: ColorValue, errors: inout [ValidationError]) {
        if case .hex(let hex) = color {
            let stripped = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
            let validLengths = [3, 4, 6, 8]
            if !validLengths.contains(stripped.count) ||
               stripped.range(of: "^[0-9A-Fa-f]+$", options: .regularExpression) == nil {
                errors.append(.invalidHexColor(hex))
            }
        }
    }
}

// MARK: - WidgetNode Children Helper

extension WidgetNode {
    /// Returns the immediate children of this node
    public var children: [WidgetNode] {
        switch self {
        case .vStack(let props): return props.children
        case .hStack(let props): return props.children
        case .zStack(let props): return props.children
        case .frame(let props): return [props.child]
        case .padding(let props): return [props.child]
        case .text, .sfSymbol, .image, .spacer, .divider, .gauge, .containerRelativeShape:
            return []
        }
    }
}
