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
    public let systemImageName: String
}

public extension OnboardingPage {
    static let defaults: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Scripts Made Easier to Navigate",
            message: "Suar organizes theater scripts into a clearer structure designed to work seamlessly with VoiceOver.",
            systemImageName: "doc.text"
        ),
        OnboardingPage(
            id: 1,
            title: "Find What You Need, Faster",
            message: "Quickly navigate between scenes, characters, dialogue, and stage directions.",
            systemImageName: "text.viewfinder"
        ),
        OnboardingPage(
            id: 2,
            title: "Start Reading",
            message: "Add your own script and let Suar organize it into an accessible reading experience.",
            systemImageName: "play.fill"
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
