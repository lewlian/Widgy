import Testing
import Foundation
@testable import WidgyCore

@Suite("WidgetConfig Codable Tests")
struct WidgetConfigTests {

    @Test("Encode and decode round-trip preserves all data")
    func roundTrip() throws {
        let original = SampleConfigs.simpleClock

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WidgetConfig.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.schemaVersion == original.schemaVersion)
        #expect(decoded.family == original.family)
        #expect(decoded == original)
    }

    @Test("All sample configs encode and decode successfully")
    func allSamplesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for config in SampleConfigs.all {
            let data = try encoder.encode(config)
            let decoded = try decoder.decode(WidgetConfig.self, from: data)
            #expect(decoded.name == config.name)
            #expect(decoded == config)
        }
    }

    @Test("Schema version is set to current")
    func schemaVersion() {
        let config = SampleConfigs.simpleClock
        #expect(config.schemaVersion == SchemaVersion.current)
        #expect(config.schemaVersion == "1.0")
    }

    @Test("JSON output contains schema_version key")
    func jsonContainsSchemaVersion() throws {
        let config = SampleConfigs.simpleClock
        let data = try JSONEncoder().encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["schema_version"] as? String == "1.0")
    }

    @Test("Migration returns config unchanged for current version")
    func migrationNoOp() {
        let config = SampleConfigs.simpleClock
        let migrated = SchemaVersion.migrate(config)
        #expect(migrated == config)
    }
}

@Suite("ConfigValidator Tests")
struct ConfigValidatorTests {
    let validator = ConfigValidator()

    @Test("Valid sample configs pass validation")
    func validConfigs() {
        for config in SampleConfigs.all {
            let result = validator.validate(config)
            #expect(result.isValid, "Config '\(config.name)' should be valid but got errors: \(result.errors)")
        }
    }

    @Test("Deeply nested config fails validation")
    func nestingLimit() {
        // Create a config nested beyond the limit
        var node: WidgetNode = .text(TextProperties(content: "deep"))
        for _ in 0..<6 {
            node = .padding(PaddingProperties(child: node))
        }
        let config = WidgetConfig(name: "Deep", root: node)
        let result = validator.validate(config)
        #expect(!result.isValid)
        #expect(result.errors.contains(where: {
            if case .nestingTooDeep = $0 { return true }
            return false
        }))
    }

    @Test("Invalid gauge value fails validation")
    func invalidGauge() {
        let config = WidgetConfig(
            name: "Bad Gauge",
            root: .gauge(GaugeProperties(value: 1.5))
        )
        let result = validator.validate(config)
        #expect(!result.isValid)
    }

    @Test("Invalid hex color fails validation")
    func invalidHexColor() {
        let config = WidgetConfig(
            name: "Bad Color",
            root: .text(TextProperties(
                content: "Hello",
                color: .hex("#ZZZZZZ")
            ))
        )
        let result = validator.validate(config)
        #expect(!result.isValid)
    }
}

@Suite("DataBinding Tests")
struct DataBindingTests {

    @Test("Extract placeholders from text")
    func extractPlaceholders() {
        let text = "Temperature: {{weather.temperature}} Battery: {{battery.level}}"
        let placeholders = BindingResolution.extractPlaceholders(from: text)
        #expect(placeholders.count == 2)
        #expect(placeholders[0].source == "weather")
        #expect(placeholders[0].field == "temperature")
        #expect(placeholders[1].source == "battery")
        #expect(placeholders[1].field == "level")
    }

    @Test("Resolve placeholders in text")
    func resolvePlaceholders() {
        let text = "It's {{weather.temperature}} outside"
        let resolved = BindingResolution.resolve(text: text, values: ["weather.temperature": "72°F"])
        #expect(resolved == "It's 72°F outside")
    }

    @Test("Text without placeholders returns unchanged")
    func noPlaceholders() {
        let text = "Hello World"
        let placeholders = BindingResolution.extractPlaceholders(from: text)
        #expect(placeholders.isEmpty)
    }
}
