import SwiftUI

struct SearchBar: View {
    @ObservedObject var viewModel: TerminalViewModel
    @FocusState private var isSearchFocused: Bool
    
    private let cyberAccent = Color(red: 0.0, green: 0.95, blue: 0.75)
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(cyberAccent)
            
            TextField("Search...", text: $viewModel.searchQuery)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: viewModel.searchQuery) { newValue in
                    viewModel.search(newValue)
                }
                .onSubmit {
                    viewModel.nextSearchResult()
                }
            
            if !viewModel.searchQuery.isEmpty {
                Text("\(viewModel.currentSearchIndex + 1)/\(viewModel.searchResults.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.gray)
                
                Button {
                    viewModel.previousSearchResult()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(cyberAccent)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.nextSearchResult()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(cyberAccent)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.08, green: 0.12, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cyberAccent.opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            isSearchFocused = true
        }
    }
}
