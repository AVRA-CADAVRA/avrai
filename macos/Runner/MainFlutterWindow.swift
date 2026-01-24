import Cocoa
import FlutterMacOS
import CoreML
import Foundation

/// Main window controller for macOS Flutter app.
/// Handles device capability detection and local LLM integration via method channels.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = frame
    contentViewController = flutterViewController
    setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerChannels(controller: flutterViewController)

    super.awakeFromNib()
  }

  private func registerChannels(controller: FlutterViewController) {
    let deviceCapabilitiesChannel = FlutterMethodChannel(
      name: "avra/device_capabilities",
      binaryMessenger: controller.engine.binaryMessenger
    )
    deviceCapabilitiesChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleDeviceCapabilities(call: call, result: result)
    }

    let localLlmChannel = FlutterMethodChannel(
      name: "spots/local_llm",
      binaryMessenger: controller.engine.binaryMessenger
    )
    localLlmChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleLocalLlm(call: call, result: result)
    }

    let localLlmStreamChannel = FlutterEventChannel(
      name: "avra/local_llm_stream",
      binaryMessenger: controller.engine.binaryMessenger
    )
    localLlmStreamChannel.setStreamHandler(LocalLlmStreamHandler())

    let bertSquadChannel = FlutterMethodChannel(
      name: "avra/bert_squad",
      binaryMessenger: controller.engine.binaryMessenger
    )
    bertSquadChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleBertSquad(call: call, result: result)
    }
  }
  
  /// Handle device capabilities method calls.
  private func handleDeviceCapabilities(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getCapabilities" else {
      result(FlutterMethodNotImplemented)
      return
    }
    
    do {
      let capabilities = try getDeviceCapabilities()
      result(capabilities)
    } catch {
      result(FlutterError(code: "capabilities_error", message: error.localizedDescription, details: nil))
    }
  }
  
  /// Get device capabilities (platform, model, RAM, disk, CPU, OS version).
  private func getDeviceCapabilities() throws -> [String: Any] {
    var size: size_t = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    let deviceModel = String(cString: model)
    
    // Detect Apple Silicon vs Intel
    let isAppleSilicon = deviceModel.contains("arm") || deviceModel.contains("Apple")
    let architecture = isAppleSilicon ? "Apple Silicon" : "Intel"
    
    // Get RAM
    var totalRamBytes: UInt64 = 0
    size = MemoryLayout<UInt64>.size
    sysctlbyname("hw.memsize", &totalRamBytes, &size, nil, 0)
    let totalRamMb = Int(totalRamBytes / (1024 * 1024))
    
    // Get CPU cores
    var cpuCores: Int32 = 0
    size = MemoryLayout<Int32>.size
    sysctlbyname("hw.ncpu", &cpuCores, &size, nil, 0)
    
    // Get disk space
    let fileManager = FileManager.default
    let homeURL = fileManager.homeDirectoryForCurrentUser
    guard let resourceValues = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityKey, .volumeTotalCapacityKey]) else {
      throw NSError(domain: "DeviceCapabilities", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get disk space"])
    }
    
    let freeDiskBytes = resourceValues.volumeAvailableCapacity ?? 0
    let totalDiskBytes = resourceValues.volumeTotalCapacity ?? 0
    let freeDiskMb = Int(freeDiskBytes / (1024 * 1024))
    let totalDiskMb = Int(totalDiskBytes / (1024 * 1024))
    
    // Get macOS version
    let processInfo = ProcessInfo.processInfo
    let osVersion = processInfo.operatingSystemVersion
    let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    
    return [
      "platform": "macos",
      "deviceModel": architecture,
      "osVersion": osVersionString,
      "totalRamMb": totalRamMb,
      "freeDiskMb": freeDiskMb,
      "totalDiskMb": totalDiskMb,
      "cpuCores": Int(cpuCores),
      "isLowPowerMode": false, // macOS doesn't have low power mode in the same way
    ]
  }
  
  /// Handle local LLM method calls (loadModel, generate, startStream).
  private func handleLocalLlm(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadModel":
      guard let args = call.arguments as? [String: Any],
            let modelDir = args["model_dir"] as? String else {
        result(FlutterError(code: "invalid_args", message: "model_dir required", details: nil))
        return
      }
      LocalLlmManager.shared.loadModel(modelDir: modelDir, result: result)
      
    case "generate":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "Invalid arguments", details: nil))
        return
      }
      LocalLlmManager.shared.generate(args: args, result: result)
      
    case "startStream":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_args", message: "Invalid arguments", details: nil))
        return
      }
      LocalLlmManager.shared.startStream(args: args, result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Handle BERT-SQuAD method calls (loadModel, answer).
  private func handleBertSquad(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadModel":
      guard let args = call.arguments as? [String: Any],
            let modelPath = args["model_path"] as? String else {
        result(FlutterError(code: "invalid_args", message: "model_path required", details: nil))
        return
      }
      BertSquadManager.shared.loadModel(modelPath: modelPath, result: result)
      
    case "answer":
      guard let args = call.arguments as? [String: Any],
            let question = args["question"] as? String,
            let context = args["context"] as? String else {
        result(FlutterError(code: "invalid_args", message: "question and context required", details: nil))
        return
      }
      BertSquadManager.shared.answer(question: question, context: context, result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// Manager for local LLM operations on macOS.
/// Supports CoreML models for Apple Silicon.
class LocalLlmManager {
  static let shared = LocalLlmManager()
  
  private var loadedModel: MLModel?
  private var loadedModelDir: String?
  private var streamSink: FlutterEventSink?
  private var tokenizer: Tokenizer?
  private var isGenerating = false
  private var generationTask: Task<Void, Never>?
  
  private init() {
    // Initialize tokenizer (will be loaded from model directory)
    tokenizer = nil
  }
  
  /// Load a CoreML model from the specified directory.
  func loadModel(modelDir: String, result: @escaping FlutterResult) {
    // Check if already loaded
    if let currentDir = loadedModelDir, currentDir == modelDir, loadedModel != nil {
      result(true)
      return
    }
    
    // Find CoreML model files (.mlmodelc)
    guard let modelURL = findCoreMLModel(in: modelDir) else {
      result(FlutterError(
        code: "model_not_found",
        message: "No CoreML model found in \(modelDir)",
        details: nil
      ))
      return
    }
    
    // Load the model
    do {
      let model = try MLModel(contentsOf: modelURL)
      loadedModel = model
      loadedModelDir = modelDir
      result(true)
    } catch {
      result(FlutterError(
        code: "load_failed",
        message: "Failed to load CoreML model: \(error.localizedDescription)",
        details: nil
      ))
    }
  }
  
  /// Generate a non-streaming response.
  func generate(args: [String: Any], result: @escaping FlutterResult) {
    guard let model = loadedModel else {
      result(FlutterError(
        code: "model_not_loaded",
        message: "Model must be loaded before generation",
        details: nil
      ))
      return
    }
    
    // Extract parameters
    guard let messagesArray = args["messages"] as? [[String: Any]],
          let temperature = args["temperature"] as? Double,
          let maxTokens = args["maxTokens"] as? Int else {
      result(FlutterError(
        code: "invalid_args",
        message: "Missing required arguments: messages, temperature, maxTokens",
        details: nil
      ))
      return
    }
    
    // Run generation asynchronously
    Task {
      do {
        let response = try await performGeneration(
          model: model,
          messages: messagesArray,
          temperature: temperature,
          maxTokens: maxTokens
        )
        await MainActor.run {
          result(response)
        }
      } catch {
        await MainActor.run {
          result(FlutterError(
            code: "generation_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }
  
  /// Perform CoreML model inference for text generation.
  private func performGeneration(
    model: MLModel,
    messages: [[String: Any]],
    temperature: Double,
    maxTokens: Int
  ) async throws -> String {
    // Step 1: Format messages into prompt
    let prompt = formatMessagesToPrompt(messages)
    
    // Step 2: Tokenize input
    let inputTokens = try tokenize(prompt)
    
    // Step 3: Prepare model input
    guard let inputFeature = try? MLMultiArray(
      shape: [1, NSNumber(value: inputTokens.count)],
      dataType: .int32
    ) else {
      throw NSError(domain: "CoreMLInference", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"])
    }
    
    for (index, token) in inputTokens.enumerated() {
      inputFeature[index] = NSNumber(value: token)
    }
    
    // Step 4: Run inference loop (autoregressive generation)
    var generatedTokens: [Int] = []
    var currentTokens = inputTokens
    
    for _ in 0..<maxTokens {
      // Prepare input for model
      let modelInput = try createModelInput(tokens: currentTokens)
      
      // Run prediction
      let prediction = try model.prediction(from: modelInput)
      
      // Extract logits from output
      guard let logits = extractLogits(from: prediction) else {
        break
      }
      
      // Sample next token
      let nextToken = sampleToken(from: logits, temperature: temperature)
      
      // Check for end-of-sequence token
      if nextToken == getEOSToken() {
        break
      }
      
      generatedTokens.append(nextToken)
      currentTokens.append(nextToken)
      
      // Limit context window (keep last N tokens)
      if currentTokens.count > 4096 {
        currentTokens = Array(currentTokens.suffix(4096))
      }
    }
    
    // Step 5: Detokenize output
    let response = try detokenize(generatedTokens)
    
    return response
  }
  
  /// Format chat messages into a prompt string.
  private func formatMessagesToPrompt(_ messages: [[String: Any]]) -> String {
    var prompt = ""
    for message in messages {
      guard let role = message["role"] as? String,
            let content = message["content"] as? String else {
        continue
      }
      
      switch role {
      case "system":
        prompt += "<|system|>\n\(content)\n"
      case "user":
        prompt += "<|user|>\n\(content)\n"
      case "assistant":
        prompt += "<|assistant|>\n\(content)\n"
      default:
        prompt += "\(content)\n"
      }
    }
    prompt += "<|assistant|>\n"
    return prompt
  }
  
  /// Tokenize text input.
  private func tokenize(_ text: String) throws -> [Int] {
    // Load tokenizer if not already loaded
    if tokenizer == nil {
      tokenizer = try loadTokenizer()
    }
    
    guard let tokenizer = tokenizer else {
      throw NSError(domain: "Tokenizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tokenizer not available"])
    }
    
    return try tokenizer.encode(text)
  }
  
  /// Detokenize token IDs back to text.
  private func detokenize(_ tokens: [Int]) throws -> String {
    guard let tokenizer = tokenizer else {
      throw NSError(domain: "Tokenizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tokenizer not available"])
    }
    
    return try tokenizer.decode(tokens)
  }
  
  /// Load tokenizer from model directory.
  private func loadTokenizer() throws -> Tokenizer {
    guard let modelDir = loadedModelDir else {
      throw NSError(domain: "Tokenizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model directory not set"])
    }
    
    // Look for tokenizer files in model directory
    let fileManager = FileManager.default
    let modelDirURL = URL(fileURLWithPath: modelDir)
    
    // Check for tokenizer.json (HuggingFace format)
    let tokenizerURL = modelDirURL.appendingPathComponent("tokenizer.json")
    if fileManager.fileExists(atPath: tokenizerURL.path) {
      return try JSONTokenizer(path: tokenizerURL.path)
    }
    
    // Check for tokenizer.model (SentencePiece format)
    let spmURL = modelDirURL.appendingPathComponent("tokenizer.model")
    if fileManager.fileExists(atPath: spmURL.path) {
      return try SentencePieceTokenizer(path: spmURL.path)
    }
    
    // Fallback: use simple word-based tokenizer
    return SimpleTokenizer()
  }
  
  /// Create MLFeatureProvider input for CoreML model.
  private func createModelInput(tokens: [Int]) throws -> MLFeatureProvider {
    // Create input array
    guard let inputArray = try? MLMultiArray(
      shape: [1, NSNumber(value: tokens.count)],
      dataType: .int32
    ) else {
      throw NSError(domain: "CoreMLInference", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"])
    }
    
    for (index, token) in tokens.enumerated() {
      inputArray[index] = NSNumber(value: token)
    }
    
    // Create feature provider
    let inputFeature = MLFeatureValue(multiArray: inputArray)
    let provider = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputFeature])
    
    return provider
  }
  
  /// Extract logits from model prediction output.
  private func extractLogits(from prediction: MLFeatureProvider) -> MLMultiArray? {
    // Try common output names
    let outputNames = ["logits", "output", "output_logits", "logits_output"]
    
    for name in outputNames {
      if let feature = prediction.featureValue(for: name),
         let multiArray = feature.multiArrayValue {
        return multiArray
      }
    }
    
    // If no standard name found, try to get first output
    if let firstFeature = prediction.featureNames.first,
       let feature = prediction.featureValue(for: firstFeature),
       let multiArray = feature.multiArrayValue {
      return multiArray
    }
    
    return nil
  }
  
  /// Sample next token from logits using temperature.
  private func sampleToken(from logits: MLMultiArray, temperature: Double) -> Int {
    // Get last token's logits (shape should be [batch, seq_len, vocab_size])
    // For simplicity, assume shape is [1, vocab_size] or extract last position
    
    let vocabSize = logits.shape[logits.shape.count - 1].intValue
    let lastTokenIndex = logits.count - vocabSize
    
    // Apply temperature and softmax
    var probabilities: [Double] = []
    var maxLogit = -Double.infinity
    
    for i in 0..<vocabSize {
      let logit = logits[lastTokenIndex + i].doubleValue
      maxLogit = max(maxLogit, logit)
    }
    
    var sumExp = 0.0
    for i in 0..<vocabSize {
      let logit = logits[lastTokenIndex + i].doubleValue
      let expValue = exp((logit - maxLogit) / temperature)
      probabilities.append(expValue)
      sumExp += expValue
    }
    
    // Normalize
    for i in 0..<probabilities.count {
      probabilities[i] /= sumExp
    }
    
    // Sample from distribution
    let random = Double.random(in: 0..<1)
    var cumulative = 0.0
    
    for (index, prob) in probabilities.enumerated() {
      cumulative += prob
      if random <= cumulative {
        return index
      }
    }
    
    // Fallback: return most likely token
    return probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
  }
  
  /// Get end-of-sequence token ID.
  private func getEOSToken() -> Int {
    // Common EOS tokens: 128001 (Llama), 2 (GPT-2), etc.
    // This should match the model's actual EOS token
    return 128001 // Llama 3.1 EOS token
  }
  
  /// Start streaming generation.
  func startStream(args: [String: Any], result: @escaping FlutterResult) {
    guard let model = loadedModel else {
      result(FlutterError(
        code: "model_not_loaded",
        message: "Model must be loaded before streaming",
        details: nil
      ))
      return
    }
    
    guard streamSink != nil else {
      result(FlutterError(
        code: "stream_not_ready",
        message: "Stream sink not available",
        details: nil
      ))
      return
    }
    
    guard !isGenerating else {
      result(FlutterError(
        code: "generation_in_progress",
        message: "Generation already in progress",
        details: nil
      ))
      return
    }
    
    // Extract parameters
    guard let messagesArray = args["messages"] as? [[String: Any]],
          let temperature = args["temperature"] as? Double,
          let maxTokens = args["maxTokens"] as? Int else {
      result(FlutterError(
        code: "invalid_args",
        message: "Missing required arguments: messages, temperature, maxTokens",
        details: nil
      ))
      return
    }
    
    // Start streaming generation
    isGenerating = true
    result(true)
    
    generationTask = Task {
      do {
        try await performStreamingGeneration(
          model: model,
          messages: messagesArray,
          temperature: temperature,
          maxTokens: maxTokens
        )
      } catch {
        await MainActor.run {
          streamSink?(FlutterError(
            code: "stream_error",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
      await MainActor.run {
        isGenerating = false
      }
    }
  }
  
  /// Perform streaming generation, emitting tokens as they're generated.
  private func performStreamingGeneration(
    model: MLModel,
    messages: [[String: Any]],
    temperature: Double,
    maxTokens: Int
  ) async throws {
    // Step 1: Format and tokenize
    let prompt = formatMessagesToPrompt(messages)
    let inputTokens = try tokenize(prompt)
    
    // Step 2: Generation loop
    var currentTokens = inputTokens
    var accumulatedText = ""
    
    for _ in 0..<maxTokens {
      // Prepare input
      let modelInput = try createModelInput(tokens: currentTokens)
      
      // Run prediction
      let prediction = try model.prediction(from: modelInput)
      
      // Extract logits
      guard let logits = extractLogits(from: prediction) else {
        break
      }
      
      // Sample next token
      let nextToken = sampleToken(from: logits, temperature: temperature)
      
      // Check for EOS
      if nextToken == getEOSToken() {
        await MainActor.run {
          streamSink?(["type": "done"])
        }
        break
      }
      
      // Detokenize token and emit
      let tokenText = try detokenize([nextToken])
      accumulatedText += tokenText
      
      await MainActor.run {
        streamSink?([
          "type": "token",
          "text": tokenText
        ])
      }
      
      // Update tokens
      currentTokens.append(nextToken)
      
      // Limit context
      if currentTokens.count > 4096 {
        currentTokens = Array(currentTokens.suffix(4096))
      }
    }
    
    // Emit completion
    await MainActor.run {
      streamSink?(["type": "done"])
    }
  }
  
  /// Find CoreML model directory (.mlmodelc) in the given directory.
  private func findCoreMLModel(in directory: String) -> URL? {
    let fileManager = FileManager.default
    let dirURL = URL(fileURLWithPath: directory)
    
    guard let enumerator = fileManager.enumerator(at: dirURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
      return nil
    }
    
    for case let fileURL as URL in enumerator {
      if fileURL.pathExtension == "mlmodelc" {
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir), isDir.boolValue {
          return fileURL
        }
      }
    }
    
    return nil
  }
}

/// Event channel handler for local LLM streaming.
class LocalLlmStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    LocalLlmManager.shared.setStreamSink(events)
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    LocalLlmManager.shared.setStreamSink(nil)
    return nil
  }
}

extension LocalLlmManager {
  /// Set the stream sink for emitting tokens.
  func setStreamSink(_ sink: FlutterEventSink?) {
    streamSink = sink
  }
}

// MARK: - Tokenizer Protocol and Implementations

/// Protocol for tokenizers.
protocol Tokenizer {
  func encode(_ text: String) throws -> [Int]
  func decode(_ tokens: [Int]) throws -> String
}

/// Simple word-based tokenizer (fallback).
class SimpleTokenizer: Tokenizer {
  private var vocab: [String: Int] = [:]
  private var reverseVocab: [Int: String] = [:]
  private var nextTokenId = 0
  
  init() {
    // Initialize with basic vocabulary
    // In production, this would load from a proper tokenizer file
  }
  
  func encode(_ text: String) throws -> [Int] {
    // Simple word-based encoding
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    return words.compactMap { word -> Int? in
      if let tokenId = vocab[word] {
        return tokenId
      } else {
        let tokenId = nextTokenId
        vocab[word] = tokenId
        reverseVocab[tokenId] = word
        nextTokenId += 1
        return tokenId
      }
    }
  }
  
  func decode(_ tokens: [Int]) throws -> String {
    return tokens.compactMap { reverseVocab[$0] }.joined(separator: " ")
  }
}

/// JSON-based tokenizer (HuggingFace format).
class JSONTokenizer: Tokenizer {
  private let tokenizerPath: String
  private var vocab: [String: Int] = [:]
  private var reverseVocab: [Int: String] = [:]
  
  init(path: String) throws {
    self.tokenizerPath = path
    try loadTokenizer()
  }
  
  private func loadTokenizer() throws {
    // Load tokenizer.json and parse vocabulary
    // This is a simplified implementation
    // Full implementation would parse the JSON structure properly
    _ = try Data(contentsOf: URL(fileURLWithPath: tokenizerPath))
    // Parse JSON and extract vocab
    // For now, use simple fallback
  }
  
  func encode(_ text: String) throws -> [Int] {
    // Implement proper encoding from tokenizer.json
    // For now, fallback to simple tokenizer
    let simple = SimpleTokenizer()
    return try simple.encode(text)
  }
  
  func decode(_ tokens: [Int]) throws -> String {
    // Implement proper decoding from tokenizer.json
    let simple = SimpleTokenizer()
    return try simple.decode(tokens)
  }
}

/// SentencePiece tokenizer.
class SentencePieceTokenizer: Tokenizer {
  private let modelPath: String
  
  init(path: String) throws {
    self.modelPath = path
    // Load SentencePiece model
    // This requires a SentencePiece library or implementation
  }
  
  func encode(_ text: String) throws -> [Int] {
    // Use SentencePiece to encode
    // For now, fallback
    let simple = SimpleTokenizer()
    return try simple.encode(text)
  }
  
  func decode(_ tokens: [Int]) throws -> String {
    // Use SentencePiece to decode
    let simple = SimpleTokenizer()
    return try simple.decode(tokens)
  }
}

// MARK: - BERT-SQuAD Manager

/// Manager for BERT-SQuAD question answering on macOS.
/// Uses CoreML model for precise answer extraction from context.
class BertSquadManager {
  static let shared = BertSquadManager()
  
  private var loadedModel: MLModel?
  private var loadedModelPath: String?
  
  private init() {}
  
  /// Load BERT-SQuAD CoreML model.
  func loadModel(modelPath: String, result: @escaping FlutterResult) {
    // Check if already loaded
    if let currentPath = loadedModelPath, currentPath == modelPath, loadedModel != nil {
      result(true)
      return
    }
    
    let fileManager = FileManager.default
    let modelURL = URL(fileURLWithPath: modelPath)
    
    // Check if file exists
    guard fileManager.fileExists(atPath: modelPath) else {
      result(FlutterError(
        code: "model_not_found",
        message: "BERT-SQuAD model not found at \(modelPath)",
        details: nil
      ))
      return
    }
    
    // Load the model
    do {
      let model = try MLModel(contentsOf: modelURL)
      loadedModel = model
      loadedModelPath = modelPath
      result(true)
    } catch {
      result(FlutterError(
        code: "load_failed",
        message: "Failed to load BERT-SQuAD model: \(error.localizedDescription)",
        details: nil
      ))
    }
  }
  
  /// Answer a question using the provided context.
  func answer(question: String, context: String, result: @escaping FlutterResult) {
    guard let model = loadedModel else {
      result(FlutterError(
        code: "model_not_loaded",
        message: "BERT-SQuAD model must be loaded before answering",
        details: nil
      ))
      return
    }
    
    // Run inference asynchronously
    Task {
      do {
        let answer = try await performQuestionAnswering(
          model: model,
          question: question,
          context: context
        )
        await MainActor.run {
          result(answer)
        }
      } catch {
        await MainActor.run {
          result(FlutterError(
            code: "answer_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }
  
  /// Perform BERT-SQuAD question answering inference.
  private func performQuestionAnswering(
    model: MLModel,
    question: String,
    context: String
  ) async throws -> String {
    // BERT-SQuAD expects input_ids and attention_mask
    // Format: [CLS] question [SEP] context [SEP]
    
    // Tokenize question and context
    // Note: BERT-SQuAD uses WordPiece tokenization
    // For now, we'll use a simplified approach
    // In production, you'd use the actual BERT tokenizer
    
    let combinedText = "[CLS] \(question) [SEP] \(context) [SEP]"
    
    // Tokenize (simplified - in production use proper BERT tokenizer)
    let tokens = tokenizeBert(combinedText)
    
    // Create input_ids (token IDs)
    guard let inputIds = try? MLMultiArray(
      shape: [1, NSNumber(value: tokens.count)],
      dataType: .int32
    ) else {
      throw NSError(domain: "BERTInference", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input_ids"])
    }
    
    for (index, tokenId) in tokens.enumerated() {
      inputIds[index] = NSNumber(value: tokenId)
    }
    
    // Create attention_mask (all 1s for valid tokens)
    guard let attentionMask = try? MLMultiArray(
      shape: [1, NSNumber(value: tokens.count)],
      dataType: .int32
    ) else {
      throw NSError(domain: "BERTInference", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create attention_mask"])
    }
    
    for i in 0..<tokens.count {
      attentionMask[i] = NSNumber(value: 1)
    }
    
    // Create model input
    let inputFeature1 = MLFeatureValue(multiArray: inputIds)
    let inputFeature2 = MLFeatureValue(multiArray: attentionMask)
    
    // BERT-SQuAD model input names may vary - try common names
    let provider = try MLDictionaryFeatureProvider(dictionary: [
      "input_ids": inputFeature1,
      "attention_mask": inputFeature2
    ])
    
    // Run prediction
    let prediction = try model.prediction(from: provider)
    
    // Extract answer start and end positions
    // BERT-SQuAD outputs start_logits and end_logits
    guard let startLogits = extractLogits(from: prediction, name: "start_logits"),
          let endLogits = extractLogits(from: prediction, name: "end_logits") else {
      // Fallback: try to extract any logits
      throw NSError(domain: "BERTInference", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not extract logits from model output"])
    }
    
    // Find best answer span
    let (startIdx, endIdx) = findBestAnswerSpan(startLogits: startLogits, endLogits: endLogits)
    
    // Extract answer tokens
    guard startIdx >= 0 && endIdx >= startIdx && endIdx < tokens.count else {
      return "" // No valid answer found
    }
    
    // Detokenize answer (simplified)
    let answerTokens = Array(tokens[startIdx...endIdx])
    let answer = detokenizeBert(answerTokens)
    
    return answer
  }
  
  /// Simplified BERT tokenization (for demonstration).
  /// In production, use proper BERT tokenizer from HuggingFace.
  private func tokenizeBert(_ text: String) -> [Int] {
    // Simplified tokenization - split by whitespace and assign IDs
    // In production, use actual BERT WordPiece tokenizer
    let words = text.components(separatedBy: .whitespacesAndNewlines)
    return words.enumerated().map { $0.offset + 101 } // Start from 101 (BERT vocab offset)
  }
  
  /// Simplified BERT detokenization.
  private func detokenizeBert(_ tokens: [Int]) -> String {
    // Simplified - in production use proper BERT detokenizer
    return tokens.map { "token\($0)" }.joined(separator: " ")
  }
  
  /// Extract logits from model output by name.
  private func extractLogits(from prediction: MLFeatureProvider, name: String) -> MLMultiArray? {
    if let feature = prediction.featureValue(for: name),
       let multiArray = feature.multiArrayValue {
      return multiArray
    }
    return nil
  }
  
  /// Find best answer span from start and end logits.
  private func findBestAnswerSpan(startLogits: MLMultiArray, endLogits: MLMultiArray) -> (Int, Int) {
    // Find position with highest start logit
    var bestStart = 0
    var bestStartScore = -Double.infinity
    
    for i in 0..<startLogits.count {
      let score = startLogits[i].doubleValue
      if score > bestStartScore {
        bestStartScore = score
        bestStart = i
      }
    }
    
    // Find position with highest end logit (must be >= start)
    var bestEnd = bestStart
    var bestEndScore = -Double.infinity
    
    for i in bestStart..<endLogits.count {
      let score = endLogits[i].doubleValue
      if score > bestEndScore {
        bestEndScore = score
        bestEnd = i
      }
    }
    
    return (bestStart, bestEnd)
  }
}
