import SwiftUI

struct ScriptPageNavigationView: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        HStack(spacing: 0) {
            previousButton
            Spacer()
            nextButton
        }
        .padding(.horizontal, 24)
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
        .accessibilityLabel(previousButtonAccesibilityLabel)
        .accessibilityValue(previousButtonAccesibilityValue)
    }
    
    private var previousButtonAccesibilityLabel: String {
        ("Halaman Sebelumnya")
    }
    
    private var previousButtonAccesibilityValue: String {
        viewModel.currentPageNumber > 1
            ? "Halaman \(viewModel.currentPageNumber - 1)"
            : "Halaman pertama"
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
        .accessibilityLabel(nextButtonAccesibilityLabel)
        .accessibilityValue(nextButtonAccesibilityValue)
    }
    
    private var nextButtonAccesibilityLabel: String {
        ("Halaman Berikutnya")
    }
    
    private var nextButtonAccesibilityValue: String {
        viewModel.currentPageNumber < viewModel.totalPages
            ? "Halaman \(viewModel.currentPageNumber + 1)"
            : "Halaman terakhir"
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
