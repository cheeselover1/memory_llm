//
//  ContentView.swift
//  memory_llm
//
//  Created by Xinyuan Chen on 5/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var images: [MemoryImage] = []
    @State private var showImagePicker = false
    @State private var query: String = ""
    @State private var showResult = false
    @State private var searchResult: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // 查询输入框
                    HStack {
                        TextField("Ask a question...", text: $query)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Search") {
                            performSearch()
                        }
                        .disabled(isLoading || images.isEmpty || query.isEmpty)
                    }
                    .padding()
                    
                    // 图片网格
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(images) { memoryImage in
                                if let uiImage = memoryImage.uiImage() {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // 添加图片按钮
                    Button(action: { showImagePicker = true }) {
                        Label("Add Image", systemImage: "plus")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.bottom)
                }
                .navigationTitle("Memory App")
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker { image in
                        images.append(MemoryImage(image: image))
                    }
                }
                .sheet(isPresented: $showResult) {
                    VStack(spacing: 20) {
                        Text("Gemini 2.5 Flash Answer")
                            .font(.headline)
                        ScrollView {
                            Text(searchResult)
                                .padding()
                        }
                        Button("Close") {
                            showResult = false
                        }
                    }
                    .padding()
                }
                
                // 等待动画
                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Waiting for Gemini response...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    // 调用Gemini 2.5 Flash API进行问答
    func performSearch() {
        guard let firstImage = images.first?.uiImage() else {
            searchResult = "请先添加图片再进行搜索。"
            showResult = true
            return
        }
        isLoading = true
        GeminiService.shared.askGemini(image: firstImage, question: query) { answer in
            DispatchQueue.main.async {
                self.isLoading = false
                self.searchResult = answer ?? "No answer."
                self.showResult = true
            }
        }
    }
}

#Preview {
    ContentView()
}
