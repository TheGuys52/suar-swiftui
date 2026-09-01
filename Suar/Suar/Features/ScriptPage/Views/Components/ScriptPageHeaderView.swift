import SwiftUI

struct ScriptPageHeaderView: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        HStack(spacing: 16) {
            backButton
            titleText
            Spacer()
            pageIndicator
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var backButton: some View {
        Button {
            viewModel.didTapBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.themeRed)
                .clipShape(Circle())
        }
        .accessibilityLabel("Kembali ke halaman sebelumnya")
        .accessibilityHint("Ketuk untuk kembali")
    }

    private var titleText: some View {
        Text(viewModel.scriptTitle)
            .font(.title2)
            .bold()
            .foregroundStyle(Color.themeRed)
            .lineLimit(1)
    }

    private var pageIndicator: some View {
        Text(pageIndicatorText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
