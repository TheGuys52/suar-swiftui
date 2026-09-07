import SwiftUI

struct ScriptPageNavigationView: View {
    @Bindable var viewModel: ScriptPageViewModel

    var body: some View {
        HStack(spacing: 0) {
            previousButton
            nextButton
            Spacer()
            editorButton
            
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
                    .padding(10)

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
    
    private var editorButton: some View {
        Button {
            if viewModel.isEditing {
                Task {
                    await viewModel.saveEdits()
                }
            } else {
                viewModel.toggleEditMode()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(buttonBackground(isEnabled: true))
                    .frame(width: 56, height: 56)
                    .padding(10)

                Image(systemName: viewModel.isEditing ? "checkmark" : "pencil")
                    .font(.title)
                    .bold()
            }
        }
        .accessibilityLabel(viewModel.isEditing ? "Simpan perubahan" : "Edit halaman")
        .accessibilityHint(
            viewModel.isEditing
                ? "Simpan semua perubahan yang telah diedit"
                : "Aktifkan mode edit untuk mengubah teks halaman"
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
    let viewModel = ScriptPageViewModel()
    viewModel.currentPageNumber = 1
    viewModel.totalPages = 10
    return ScriptPageNavigationView(viewModel: viewModel)
}
