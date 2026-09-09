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
            HStack {
                Text("Suar")
                    .font(.custom("Georgia", size: 32))
                    .foregroundStyle(Color.themeRed)
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            Spacer()
            
            illustrationCard
            
            Text(viewModel.currentPage.title)
                .font(.custom("Georgia", size: 28))
                .foregroundStyle(.primary)
                .padding(.top, 60)
            
            Text(viewModel.currentPage.message)
                .font(.custom("HelveticaNeue", size: 17))
                .foregroundStyle(.secondary)
                .padding(.top, 30)
            
            pageIndicator
                .padding(.top, 50)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 12)
    }
    
    private var illustrationCard: some View {
        Image(viewModel.currentPage.imageName)
            .resizable().scaledToFit()
            .frame(maxWidth: .infinity)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .contentShape(Rectangle())
                .background(Color.themeRed)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibleTouchTarget()
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel()
    )
}
