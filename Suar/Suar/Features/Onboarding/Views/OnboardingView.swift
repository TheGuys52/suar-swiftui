//
//  OnboardingPageView.swift
//  Suar
//
//  Created by Gogo Figo on 02/09/26.
//

import SwiftUI

public struct OnboardingView: View {
    let viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                onboardingContent
            }
            .scrollIndicators(.hidden)

            primaryButton
                .padding(.top, 16)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .background(Color.white.ignoresSafeArea())
    }

    private var onboardingContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            illustrationCard
                .padding(.top, 72)

            Text(viewModel.currentPage.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .padding(.top, 30)

            Text(viewModel.currentPage.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 14)

            pageIndicator
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var illustrationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(uiColor: .systemGray5))

            Image(systemName: viewModel.currentPage.systemImageName)
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .aspectRatio(0.82, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.pages.indices, id: \.self) { index in
                Circle()
                    .fill(index <= viewModel.currentPageIndex ? Color.themeRed : Color(uiColor: .systemGray3))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(viewModel.currentPageIndex + 1) of \(viewModel.pages.count)")
    }

    private var primaryButton: some View {
        Button {
            viewModel.didTapContinue()
        } label: {
            Text(viewModel.primaryButtonTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
        }
        .foregroundStyle(.white)
        .background(Color.themeRed)
        .clipShape(Capsule())
        .buttonStyle(.plain)
        .accessibleTouchTarget()
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel()
    )
}
