//
//  UploadView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/15.
//

import SwiftUI
import ZIPFoundation

struct UploadView: View {
    
    @StateObject private var viewModel: UploadViewModel
    @Namespace var namespace
    
    init() {
        _viewModel = .init(wrappedValue: UploadViewModel())
    }
        
    var body: some View {
        ZStack {
            VStack {
                if viewModel.isUploading {
                    VStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .resizable()
                            .foregroundColor(viewModel.isDragNDropping ? .primary : .secondary)
                            .aspectRatio(contentMode: .fit)
                            .matchedGeometryEffect(id: "uploadicon", in: namespace)
                            .frame(width: 100, height: 100)
                            .padding()
                        ProgressView("Uploading", value: viewModel.currentProgress, total: viewModel.totalProgress)
                            .frame(width: 100)
                    }
                } else if !viewModel.isDragNDropping {
                    LazyVGrid(columns: [GridItem(), GridItem()], alignment: .leading) {
                        Image(systemName: "cursorarrow.and.square.on.square.dashed")
                        Text("Drag")
                        Image(systemName: "tray.and.arrow.down")
                            .matchedGeometryEffect(id: "dropicon", in: namespace)
                        Text("Drop")
                        Image(systemName: "icloud.and.arrow.up")
                            .matchedGeometryEffect(id: "uploadicon", in: namespace)
                        Text("Upload")
                    }
                        .frame(width: 170)
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "tray.and.arrow.down")
                        .resizable()
                        .foregroundColor(viewModel.isDragNDropping ? .primary : .secondary)
                        .aspectRatio(contentMode: .fit)
                        .matchedGeometryEffect(id: "dropicon", in: namespace)
                        .frame(width: 100, height: 100)
                        .padding()
                }
                Text("\(viewModel.errorList.map { $0.localizedDescription }.joined(separator: "\n"))")
            }
            
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(viewModel.isDragNDropping ? Color.primary : Color.secondary, style: StrokeStyle(lineWidth: 5, dash: [20, 8]))
                .foregroundColor(.none)
                .onTapGesture {
                    viewModel.isUploading.toggle()
                }
        }
        .padding()
        .animation(.spring(), value: viewModel.isDragNDropping)
        .animation(.easeInOut, value: viewModel.isUploading)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragNDropping) { providers in
            Task { await viewModel.onDropAction(providers) }
            return true
        }
    }
}

//struct UploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadView()
//    }
//}
