//
//  OnboardingPageViewModel.swift
//  Suar
//
//  Created by Gogo Figo on 02/09/26.
//

import Foundation
import Observation
import SwiftData

public struct OnboardingPage: Identifiable {
    public let id: Int
    public let title: String
    public let message: String
    public let imageName: String
}

public extension OnboardingPage {
    static let defaults: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Your Script\nReady For Rehearsal",
            message: "Turn a PDF or photo into a script with clear dialogue, characters,and stage directions.",
            imageName: "onBoarding1"
        ),
        OnboardingPage(
            id: 1,
            title: "Find Your Place\nKeep Your Focus",
            message: "Move between scenes, characters,and dialogue without searching through every page.",
            imageName: "onBoarding2"
        ),
        OnboardingPage(
            id: 2,
            title: "Your Next Rehearsal\nStarts Here",
            message: "Try a sample, or bring your own script. You can add more from your library.",
            imageName: "onBoarding3"
        )
    ]
}

@Observable
public final class OnboardingViewModel {
    public let pages: [OnboardingPage]
    public private(set) var currentPageIndex = 0
    
    public var onFinish: (() -> Void)?

    public init(pages: [OnboardingPage] = OnboardingPage.defaults) {
        precondition(!pages.isEmpty, "Onboarding pages cannot be empty")
        self.pages = pages
    }
    
    public var currentPage: OnboardingPage {
        pages[currentPageIndex]
    }
    
    public var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }
    
    public var primaryButtonTitle: String {
         isLastPage ? "Get Started" : "Continue"
     }
    
    public func didTapContinue() {
          if isLastPage {
              onFinish?()
          } else {
              currentPageIndex += 1
          }
      }

      public func didTapSkip() {
          onFinish?()
      }
}
