//
//  PreviewViewModels.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//
import Foundation
import Combine

// Mock ViewModels for previews
extension WatchBACViewModel {
    static var preview: WatchBACViewModel {
        let viewModel = WatchBACViewModel()
        viewModel.currentBAC = PreviewData.bacEstimate
        return viewModel
    }
}

extension WatchDrinkViewModel {
    static var preview: WatchDrinkViewModel {
        let viewModel = WatchDrinkViewModel()
        viewModel.recentDrinks = PreviewData.drinks
        return viewModel
    }
}

extension WatchUserViewModel {
    static var preview: WatchUserViewModel {
        let viewModel = WatchUserViewModel()
        viewModel.currentUser = PreviewData.user
        return viewModel
    }
}
