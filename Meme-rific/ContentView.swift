import SwiftUI

struct Meme: Hashable, Codable {
    let id: String
    let name: String
    let url: String
    let width: Int
    let height: Int
    let boxCount: Int
    let captions: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case width
        case height
        case boxCount = "box_count"
        case captions
    }
}

struct MemeResponse: Codable {
    let data: MemeData
}

struct MemeData: Codable {
    let memes: [Meme]
}

class ViewModel: ObservableObject {
    @Published var meme: Meme?
    
    func generateRandomMeme() {
        guard let url = URL(string: "https://api.imgflip.com/get_memes") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let memeResponse = try JSONDecoder().decode(MemeResponse.self, from: data)
                let memes = memeResponse.data.memes
                let randomIndex = Int.random(in: 0..<memes.count)
                
                DispatchQueue.main.async {
                    self?.meme = memes[randomIndex]
                }
            } catch {
                print(error)
            }
        }
        
        task.resume()
    }
}

func loadMeme(from url: URL) -> UIImage? {
    guard let memeData = try? Data(contentsOf: url),
          let source = CGImageSourceCreateWithData(memeData as CFData, nil) else {
        return nil
    }

    var images = [UIImage]()
    let count = CGImageSourceGetCount(source)
    for i in 0..<count {
        if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
            images.append(UIImage(cgImage: cgImage))
        }
    }

    return UIImage.animatedImage(with: images, duration: Double(count) / 10.0)
}

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if let meme = viewModel.meme,
                   let memeURL = URL(string: meme.url),
                   let memeImage = loadMeme(from: memeURL) {
                    VStack {
                        Image(uiImage: memeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(1)
                            .layoutPriority(1)
                        
                        Text(meme.name)
                            .padding(.top, 8)
                    }
                } else {
                    Text("No meme available.")
                        .foregroundColor(.red)
                }

                Button("Generate Random Meme") {
                    viewModel.generateRandomMeme()
                }
                .padding(2)
            }
            .navigationTitle("Meme Generator")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
