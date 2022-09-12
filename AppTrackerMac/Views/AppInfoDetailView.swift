//
//  AppInfoDetailView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/11.
//

import SwiftUI

struct AppInfoDetailView: View {
    
    var appInfo: AppInfoElement
    
    @State var imageUrl: URL? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(colorScheme == .light ? .white : .init(.displayP3, red: 0x1E/0xFF, green: 0x1E/0xFF, blue: 0x1E/0xFF))
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding()
                } placeholder: {
                    ProgressView()
                        .frame(width: 200, height: 200)
                }
            }
            .frame(maxHeight: 216)
            .padding()
            
            Text(appInfo.appName)
                .font(.headline)
            Form {
                Section {
                    TextField("Package Name", text: .constant(appInfo.packageName))
                    TextField("Activity Name", text: .constant(appInfo.activityName))
                    TextField("Appfilter.xml", text: .constant(appInfo.xml))
                }
            }
            .padding()
            Spacer()
        }
        .task {
            getImageUrl()
        }
        .onChange(of: appInfo, perform: { newValue in
            getImageUrl(packageName: newValue.packageName)
        })
    }
    
    private func getImageUrl(packageName: String? = nil) {
        Task {
            imageUrl = nil
            let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/icon?appId=\(packageName ?? appInfo.packageName)")!
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let imageUrlResponse = try JSONDecoder().decode(GetImageUrlResponse.self, from: data)
                imageUrl = URL(string: imageUrlResponse.image)
            } catch { debugPrint(error.localizedDescription) }
        }
    }
}

struct AppInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoDetailView(appInfo: .example)
    }
}
