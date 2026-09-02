import SwiftUI

struct ScriptPageHeaderView: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            titleText
            Spacer()
            pageIndicator
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    private var titleText: some View {
        Text(viewModel.scriptTitle)
            .font(Font.custom("Courier", size: 24))
            .bold()
            .lineLimit(1)
    }

    private var pageIndicator: some View {
        Text(pageIndicatorText)
            .font(Font.custom("Courier", size: 20))
            .foregroundStyle(.primary)
            .bold()
            .accessibilityLabel(
                "Halaman \(viewModel.currentPageNumber) dari \(viewModel.totalPages)"
            )
    }

    private var pageIndicatorText: String {
        "\(viewModel.currentPageNumber)/\(viewModel.totalPages)"
    }
}

#Preview("Default") {
    ScriptPageHeaderView(viewModel: ScriptPageViewModel())
}

#Preview("Page 5 of 10") {
    let vm = ScriptPageViewModel()
    vm.currentPageNumber = 5
    vm.totalPages = 10
    return ScriptPageHeaderView(viewModel: vm)
}
