//
//  OnboardingCoverView.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import SwiftUI

public struct OnboardingCoverView: View {
    @State private var onboardingViewModel = OnboardingViewModel()
    public var onDismiss: () -> Void = {}

    public init(onDismiss: @escaping () -> Void = {}) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        OnboardingView(viewModel: onboardingViewModel)
            .onAppear {
                onboardingViewModel.onFinish = { [self] in
                    onDismiss()
                }
            }
    }
}
