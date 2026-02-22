import XCTest
@testable import WhisperFlow

final class ModelManagerTests: XCTestCase {
    func testModelCatalogContainsExpectedModels() {
        let modelIds = ModelCatalog.models.map(\.id)
        XCTAssertTrue(modelIds.contains("tiny"))
        XCTAssertTrue(modelIds.contains("base"))
        XCTAssertTrue(modelIds.contains("small"))
        XCTAssertTrue(modelIds.contains("medium"))
        XCTAssertTrue(modelIds.contains("large-v3"))
    }

    func testModelCatalogContainsQuantizedVariants() {
        let modelIds = ModelCatalog.models.map(\.id)
        XCTAssertTrue(modelIds.contains("tiny-q5_0"))
        XCTAssertTrue(modelIds.contains("base-q5_0"))
        XCTAssertTrue(modelIds.contains("small-q5_1"))
        XCTAssertTrue(modelIds.contains("medium-q5_0"))
        XCTAssertTrue(modelIds.contains("large-v3-q5_0"))
    }

    func testRecommendedModel() {
        let recommended = ModelCatalog.recommendedModel
        XCTAssertEqual(recommended.id, "base")
    }

    func testModelLookup() {
        let base = ModelCatalog.model(for: "base")
        XCTAssertNotNil(base)
        XCTAssertEqual(base?.name, "Base")

        let nonexistent = ModelCatalog.model(for: "nonexistent")
        XCTAssertNil(nonexistent)
    }

    func testModelSpeedComparable() {
        XCTAssertTrue(WhisperModel.ModelSpeed.fastest < WhisperModel.ModelSpeed.slowest)
        XCTAssertTrue(WhisperModel.ModelSpeed.fast < WhisperModel.ModelSpeed.medium)
    }

    func testModelQualityComparable() {
        XCTAssertTrue(WhisperModel.ModelQuality.basic < WhisperModel.ModelQuality.best)
        XCTAssertTrue(WhisperModel.ModelQuality.good < WhisperModel.ModelQuality.great)
    }

    func testModelsDirectoryExists() {
        let dir = ModelManager.modelsDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
    }

    func testModelFilenames() {
        for model in ModelCatalog.models {
            XCTAssertTrue(model.filename.hasPrefix("ggml-"), "Model \(model.id) filename should start with ggml-")
            XCTAssertTrue(model.filename.hasSuffix(".bin"), "Model \(model.id) filename should end with .bin")
        }
    }

    func testDownloadURLsAreValid() {
        for model in ModelCatalog.models {
            XCTAssertTrue(
                model.downloadURL.absoluteString.contains("huggingface.co"),
                "Model \(model.id) should download from Hugging Face"
            )
        }
    }
}
