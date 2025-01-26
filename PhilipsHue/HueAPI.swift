import Foundation

class HueAPI {
    static let bridgeIP = "192.168.1.81"
    static let appKey = "LWkFP3ojIoyrbVZ94Nh0X2qZStE5NqreVWlDYkwc"
    static let lightID = "42b85a64-9e01-4f07-a4e8-d637e89e1fa8"
    
    static let colorCoordinates: [String: (x: Double, y: Double)] = [
        "red": (0.675, 0.322),
        "green": (0.4091, 0.518),
        "blue": (0.167, 0.04),
        "yellow": (0.432, 0.4996),
        "purple": (0.272, 0.109),
        "orange": (0.556, 0.408),
        "pink": (0.382, 0.160),
        "white": (0.3227, 0.329)
    ]

    // Method to turn the light on or off
    static func controlLamp(on: Bool, completion: @escaping (Bool) -> Void) {
        let urlString = "https://\(bridgeIP)/clip/v2/resource/light/\(lightID)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "hue-application-key")

        let body: [String: Any] = ["on": ["on": on]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // SSLBypass
        let session = URLSession(configuration: .default, delegate: SSLBypassDelegate(), delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed response: \(response.debugDescription)")
                completion(false)
                return
            }

            completion(true)
        }

        task.resume()
    }

    // change the color
    static func changeLampColor(to color: String, completion: @escaping (Bool) -> Void) {
        guard let coordinates = colorCoordinates[color.lowercased()] else {
            print("Unsupported color")
            completion(false)
            return
        }

        let urlString = "https://\(bridgeIP)/clip/v2/resource/light/\(lightID)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "hue-application-key")

        // Color change
        let body: [String: Any] = [
            "color": [
                "xy": ["x": coordinates.x, "y": coordinates.y]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        // SSLBypass
        let session = URLSession(configuration: .default, delegate: SSLBypassDelegate(), delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed response: \(response.debugDescription)")
                completion(false)
                return
            }

            completion(true)
        }

        task.resume()
    }
}
