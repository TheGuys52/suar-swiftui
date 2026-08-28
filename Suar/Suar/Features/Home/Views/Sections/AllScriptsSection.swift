import SwiftUI

struct AllScriptsSection: View {
    @State private var sortOption: SortOption = .newest
    
    enum SortOption: String, CaseIterable {
        case newest
        case oldest
        case alphabeticalAZ
        case alphabeticalZA
        
        var title: String {
            switch self {
            case .newest:
                return "Terbaru"
            case .oldest:
                return "Terlama"
            case .alphabeticalAZ:
                return "Abjad (A-Z)"
            case .alphabeticalZA:
                return "Abjad (Z-A)"
            }
        }
        
        var icon: String {
            switch self {
            case .newest:
                return "clock.arrow.circlepath"
            case .oldest:
                return "clock"
            case .alphabeticalAZ:
                return "textformat.abc"
            case .alphabeticalZA:
                return "textformat.abc"
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("All Scripts")
                    .bold()
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if #available(iOS 26.0, *) {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.title, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.white)
                            .bold()
                            .frame(width: 44, height: 44)
                            .glassEffect(
                                .regular
                                    .tint(Color.themeRed)
                                    .interactive()
                            )
                    }
                    .clipShape(Circle())
                } else {
                    Menu {
                        Picker("Sort By", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Label(option.title, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.white)
                            .bold()
                            .frame(width: 44, height: 44)
                            .background(Color.themeRed)
                            .clipShape(Circle())
                            .shadow(radius: 8)
                            .contentShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                AllScriptList()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AllScriptsSection()
}
