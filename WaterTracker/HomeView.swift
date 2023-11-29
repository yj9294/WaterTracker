//
//  HomeView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import ComposableArchitecture

struct Home: Reducer {
    struct State: Equatable {
        static func == (lhs: Home.State, rhs: Home.State) -> Bool {
            lhs.item == rhs.item &&  lhs.dates == rhs.dates
        }
        
        @BindingState var item: Item = .drink
        var drink: Drink.State = .init()
        var charts: Charts.State = .init()
        var reminder: Reminder.State = .init()
        
        @UserDefault(key: "impression.date")
        var dates: [String: Date]?
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case drink(Drink.Action)
        case charts(Charts.Action)
        case reminder(Reminder.Action)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case let .drink(action):
                switch action {
                case let .recordUpdated(record):
                    state.charts.source = record
                default:
                    break
                }
            default:
                break
            }
            return .none
        }
        Scope(state: \.drink, action: /Action.drink) {
            Drink()
        }
        Scope(state: \.charts, action: /Action.charts) {
            Charts()
        }
        Scope(state: \.reminder, action: /Action.reminder) {
            Reminder()
        }
    }
}

extension Home.State {
    enum Item: String, Codable{
        case drink, charts, reminder
    }
    var isDrink: Bool {
        item == .drink
    }
    var isCharts: Bool {
        item == .charts
    }
    var isReminder: Bool {
        item == .reminder
    }
}

struct HomeView: View {
    let store: StoreOf<Home>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            NavigationView{
                TabView(selection: viewStore.$item,
                        content:  {
                    DrinkView(store: store.scope(state: \.drink, action: Home.Action.drink)).tabItem {
                        getTabItem(.drink, in: viewStore.state)
                    }.tag(Home.State.Item.drink)
                    ChartsView(store: store.scope(state: \.charts, action: Home.Action.charts)).tabItem {
                        getTabItem(.charts, in: viewStore.state)
                    }.tag(Home.State.Item.charts)
                    ReminderView(store: store.scope(state: \.reminder, action: Home.Action.reminder)).tabItem {
                        getTabItem(.reminder, in: viewStore.state)
                    }.tag(Home.State.Item.reminder)
                })
            }
        }
    }
    
    func getTabItem(_ item: Home.State.Item, in store: Home.State) -> Image {
        Image(store.item == item ? item.rawValue + "_1" : item.rawValue)
    }
}

#Preview {
    HomeView(store: Store.init(initialState: Home.State(), reducer: {
        Home()
    }))
}
