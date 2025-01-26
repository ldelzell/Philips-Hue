import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @State private var isListening = false
    @State private var recognizedText = ""
    
    let speechRecognizer = SFSpeechRecognizer()
    let audioEngine = AVAudioEngine()
    let request = SFSpeechAudioBufferRecognitionRequest()
    
    let colors = ["Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Pink", "White"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Smart Light Control")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            HStack(spacing: 20) {
                // Turn on
                Button(action: {
                    HueAPI.controlLamp(on: true) { success in
                        DispatchQueue.main.async {
                            print("Light turned on: \(success)")
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        Text("Turn On")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                // Turn off
                Button(action: {
                    HueAPI.controlLamp(on: false) { success in
                        DispatchQueue.main.async {
                            print("Light turned off: \(success)")
                        }
                    }
                }) {
                    VStack {
                        Image(systemName: "lightbulb.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                        Text("Turn Off")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
            }
            .padding(.horizontal)
            
            Text("Change Color")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            HueAPI.changeLampColor(to: color.lowercased()) { success in
                                DispatchQueue.main.async {
                                    print("\(color) color applied: \(success)")
                                }
                            }
                        }) {
                            Text(color)
                                .padding()
                                .frame(width: 100)
                                .background(Color.primary.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .background(self.backgroundColor(for: color))
                        .cornerRadius(15)
                        .padding(5)
                    }
                }
            }
            .padding(.horizontal)
            
            // voiuce controll
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
                isListening.toggle()
            }) {
                HStack {
                    Image(systemName: isListening ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 30))
                    Text(isListening ? "Stop Listening" : "Start Listening")
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.white.opacity(0.8).edgesIgnoringSafeArea(.all))
    }
    // not working
    func backgroundColor(for color: String) -> Color {
        switch color.lowercased() {
        case "red":
            return Color.red
        case "green":
            return Color.green
        case "blue":
            return Color.blue
        case "yellow":
            return Color.yellow
        case "purple":
            return Color.purple
        case "orange":
            return Color.orange
        case "pink":
            return Color.pink
        case "white":
            return Color.white
        default:
            return Color.gray
        }
    }
    
    func startListening() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                startRecording()
            case .denied:
                print("Speech recognition access denied by the user.")
            case .restricted:
                print("Speech recognition is restricted on this device.")
            case .notDetermined:
                print("Speech recognition has not been authorized.")
            @unknown default:
                break
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        print("Stopped listening.")
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                self.request.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            speechRecognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    print("Recognized Text: \(self.recognizedText)")
                    self.processCommand(text: self.recognizedText)
                }
                
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to configure and start the audio session: \(error.localizedDescription)")
        }
    }
    
    // check the voice commands
    func processCommand(text: String) {
        if text.lowercased().contains("turn on") {
            HueAPI.controlLamp(on: true) { success in
                DispatchQueue.main.async {
                    print("Voice command: Light turned on")
                }
            }
        } else if text.lowercased().contains("turn off") {
            HueAPI.controlLamp(on: false) { success in
                DispatchQueue.main.async {
                    print("Voice command: Light turned off")
                }
            }
        } else if let color = colors.first(where: { text.lowercased().contains($0.lowercased()) }) {
            HueAPI.changeLampColor(to: color.lowercased()) { success in
                DispatchQueue.main.async {
                    print("Voice command: Color changed to \(color)")
                }
            }
        }
    }
}
