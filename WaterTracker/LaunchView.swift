//
//  LaunchView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct Launch: Reducer {
    @Dependency(\.continuousClock) var clock
    enum CancelID {case timer}
    struct State: Equatable {
        var progress = 0.0
        var duration = 13.5
    }
    enum Action: Equatable {
        case onAppear
        case update
        case stop
        case checkOpenAD
        case showOpenAD
        case closedOpenAD
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .onAppear:
                state.progress = 0
                state.duration = 12.5
                GADUtil.share.requestConfig()
                GADUtil.share.load(.open)
                GADUtil.share.load(.interstitial)
                GADUtil.share.load(.native)
                return .run { send in
                    for await _ in clock.timer(interval: .milliseconds(20)) {
                        await send(.update)
                        await send(.checkOpenAD)
                    }
                }.cancellable(id: CancelID.timer)
            case .update:
                debugPrint(state.progress)
                state.progress += 0.02 / state.duration
                if state.progress >= 1.0 {
                    state.progress = 1.0
                    return .run { send in
                        await send(.stop)
                        await send(.showOpenAD)
                    }
                }
            case .checkOpenAD:
                if GADUtil.share.isLoaded(.open), state.progress > 0.2 {
                    state.duration = 0.5
                }
            case .stop:
                return .cancel(id: CancelID.timer)
            case .showOpenAD:
                let publisher = Future<Launch.Action, Never>{ promiss in
                    GADUtil.share.show(.open) { _ in
                        promiss(.success(.closedOpenAD))
                    }
                }
                return .publisher {
                    publisher
                }
            case .closedOpenAD:
                break
            }
            return .none
        }
    }
}

struct LaunchView: View {
    let store: StoreOf<Launch>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                Image("launch_icon").padding(.top, 111)
                Image("launch_title").padding(.top, 40)
                Spacer()
                Text("Start developing healthy habits").foregroundStyle(Color("#7CA7A1")).font(.subheadline)
                ProgressView(value: viewStore.progress).tint(Color("#2B9FA0")).padding(.horizontal, 70).padding(.bottom, 60)
            }
        }.background(Image("launch_bg").resizable().ignoresSafeArea())
    }
}

#Preview {
    LaunchView(store: Store.init(initialState: Launch.State(), reducer: {
        Launch()
    }))
}
