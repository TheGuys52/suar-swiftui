import SwiftUI

struct ScriptPageNavigationView: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            previousButton
            Spacer()
            nextButton
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private var previousButton: some View {
        Button {
            viewModel.goToPreviousPage()
        } label: {
            ZStack {
                Circle()
                    .fill(buttonBackground(isEnabled: viewModel.currentPageNumber > 1))
                    .frame(width: 56, height: 56)

                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(buttonForeground(isEnabled: viewModel.currentPageNumber > 1))
            }
        }
        .disabled(viewModel.currentPageNumber <= 1)
        .accessibilityLabel("Halaman sebelumnya")
        .accessibilityValue(
            viewModel.currentPageNumber > 1
                ? "Halaman \(viewModel.currentPageNumber - 1)"
                : "Halaman pertama"
        )
    }

    private var nextButton: some View {
        Button {
            viewModel.goToNextPage()
        } label: {
            ZStack {
                Circle()
                    .fill(buttonBackground(
                        isEnabled: viewModel.currentPageNumber < viewModel.totalPages
                    ))
                    .frame(width: 56, height: 56)

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(buttonForeground(
                        isEnabled: viewModel.currentPageNumber < viewModel.totalPages
                    ))
            }
        }
        .disabled(viewModel.currentPageNumber >= viewModel.totalPages)
        .accessibilityLabel("Halaman berikutnya")
        .accessibilityValue(
            viewModel.currentPageNumber < viewModel.totalPages
                ? "Halaman \(viewModel.currentPageNumber + 1)"
                : "Halaman terakhir"
        )
    }

    private func buttonBackground(isEnabled: Bool) -> Color {
        isEnabled ? Color.themeRed : Color.gray.opacity(0.3)
    }

    private func buttonForeground(isEnabled: Bool) -> Color {
        isEnabled ? .white : Color.gray.opacity(0.5)
    }
}

#Preview("First Page") {
    let vm = ScriptPageViewModel()
    vm.currentPageNumber = 1
    vm.totalPages = 10
    return ScriptPageNavigationView(viewModel: vm)
}

#Preview("Middle Page") {
    let vm = ScriptPageViewModel()
    vm.currentPageNumber = 5
    vm.totalPages = 10
    return ScriptPageNavigationView(viewModel: vm)
}

#Preview("Last Page") {
    let vm = ScriptPageViewModel()
    vm.currentPageNumber = 10
    vm.totalPages = 10
    return ScriptPageNavigationView(viewModel: vm)
}
