//
//  ContentView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import ComposableArchitecture

var appEnterBackground = false
struct WaterTracker: Reducer {
    struct State: Equatable {
        var state: State = .launching
        var launching: Launch.State = .init()
        var launched:  Home.State = .init()
    }
    enum Action: Equatable {
        case launching(Launch.Action)
        case launched(Home.Action)
        case enterbackground
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .launching(action):
                appEnterBackground = false
                switch action {
                case .onAppear:
                    state.goLaunching()
                case .stop:
                    state.goLaunched()
                default:
                    break
                }
            case .enterbackground:
                state.goLaunching()
                appEnterBackground = true
            default:
                break
            }
            return .none
        }
        
        Scope(state: \.launching, action: /Action.launching) {
            Launch()
        }
        Scope(state: \.launched, action: /Action.launched) {
            Home()
        }
    }
}

extension WaterTracker.State {
    enum State{
        case launching, launched
    }
    var isLaunched: Bool {
        state == .launched
    }
    mutating func goLaunched() {
        state = .launched
    }
    mutating func goLaunching() {
        state = .launching
    }
}

struct WaterTrackerView: View {
    let store: StoreOf<WaterTracker>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                if viewStore.isLaunched {
                    HomeView(store: store.scope(state: \.launched, action: WaterTracker.Action.launched))
                } else {
                    LaunchView(store: store.scope(state: \.launching, action: WaterTracker.Action.launching))
                }
            }.onReceive(NotificationCenter.default.publisher(for: .`init`), perform: { _ in
                viewStore.send(.launching(.onAppear))
            }).onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
                viewStore.send(.launching(.onAppear))
            }).onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
                viewStore.send(.launching(.stop))
                viewStore.send(.enterbackground)
            }).onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                appEnterBackground = true
            }
        }
    }
}
