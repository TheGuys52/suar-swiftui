import SwiftUI

public struct ScriptPageView: View {
    @Bindable var viewModel: ScriptPageViewModel

    public init(viewModel: ScriptPageViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScriptPageHeaderView(viewModel: viewModel)
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            ScriptPageNavigationView(viewModel: viewModel)
        }
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.lines) { line in
                    ScriptLineRowView(line: line)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 88)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ScriptPageView(viewModel: ScriptPageViewModel())
}
