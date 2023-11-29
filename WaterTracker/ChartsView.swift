//
//  Charts.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import ComposableArchitecture

struct Charts: Reducer {
    struct State: Equatable {
        
        var source: [Record.Model] = UserDefaults.standard.getObject([Record.Model].self, forKey: "drink.record") ?? []
        var item: Itme = .day
        let topSource = Itme.allCases
        var leftSource = Array(0..<7)
        var path: StackState<Path.State> = .init()
        
        var ad: GADNativeViewModel = .none
    }
    enum Action: Equatable {
        case itemSelected(State.Itme)
        case historyButtonTapped
        case path(StackAction<Path.State, Path.Action>)
        case adUpdate(GADNativeViewModel)
    }
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .itemSelected(item):
                state.item = item
            case .historyButtonTapped:
                state.pushHistoryView()
            case .path(.element(id: _, action: .history(.pop))):
                state.popView()
            case .adUpdate(let ad):
                state.updateAD(ad)
            default:
                break
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    struct Model: Codable, Hashable, Identifiable {
        var id: String = UUID().uuidString
        var progress: CGFloat
        var ml: Int
        var unit: String // 描述 类似 9:00 或者 Mon  或者03/01 或者 Jan
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case history(History.State)
        }
        enum Action: Equatable {
            case history(History.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.history, action: /Action.history) {
                History()
            }
        }
    }

}

extension Charts.State {
    
    mutating func updateAD(_ ad: GADNativeViewModel) {
        self.ad = ad
    }
    
    mutating func pushHistoryView() {
        path.append(.history(.init(source: source)))
    }
    
    mutating func popView() {
        path.removeAll()
    }
    
    enum Itme: String, CaseIterable {
        case day, week, month, year
        var title: String {
            self.rawValue.capitalized
        }
    }
    
    var leftSourceString: [String] {
        switch item {
        case .day:
             return leftSource.map({
                "\($0 * 200)"
             }).reversed()
        case .week, .month:
            return leftSource.map({
               "\($0 * 500)"
            }).reversed()
        case .year:
            return leftSource.map({
               "\($0 * 500 * 30)"
            }).reversed()
        }
    }
    
    var rightBottomSourceString: [String] {
        switch item {
        case .day:
            return source.filter { model in
                return model.day == Date().day
            }.compactMap { model in
                model.time
            }.reduce([]) { partialResult, element in
                return partialResult.contains(element) ?  partialResult : partialResult + [element]
            }
        case .week:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        case .month:
            var days: [String] = []
            for index in 0..<30 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd"
                let date = Date(timeIntervalSinceNow: TimeInterval(index * 24 * 60 * 60 * -1))
                let day = formatter.string(from: date)
                days.insert(day, at: 0)
            }
            return days
        case .year:
            var months: [String] = []
            for index in 0..<12 {
                let d = Calendar.current.date(byAdding: .month, value: -index, to: Date()) ?? Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let day = formatter.string(from: d)
                months.insert(day, at: 0)
            }
            return months
        }
    }
    
    var rightCenterSourceString: [Charts.Model] {
        var max = 1
        // 数据源
        // 用于计算进度
        max = leftSourceString.map({Int($0) ?? 0}).max { l1, l2 in
            l1 < l2
        } ?? 1
        switch item {
        case .day:
            return rightBottomSourceString.map({ time in
                let total = source.filter { model in
                    model.day == Date().day && time == model.time
                }.map({
                    $0.ml
                }).reduce(0, +)
                return Charts.Model(progress: Double(total)  / Double(max) , ml: total, unit: time)
            })
        case .week:
            return rightBottomSourceString.map { weeks in
                // 当前搜索目的周几 需要从周日开始作为下标0开始的 所以 unit数组必须是7123456
                let week = rightBottomSourceString.firstIndex(of: weeks) ?? 0
                
                // 当前日期 用于确定当前周
                let weekDay = Calendar.current.component(.weekday, from: Date())
                let firstCalendar = Calendar.current.date(byAdding: .day, value: 1-weekDay, to: Date()) ?? Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                // 目标日期
                let target = Calendar.current.date(byAdding: .day, value: week, to: firstCalendar) ?? Date()
                let targetString = dateFormatter.string(from: target)
                
                let total = source.filter { model in
                    model.day == targetString
                }.map({
                    $0.ml
                }).reduce(0, +)
                return Charts.Model(progress: Double(total)  / Double(max), ml: total, unit: weeks)
            }
        case .month:
            return rightBottomSourceString.reversed().map { date in
                let year = Calendar.current.component(.year, from: Date())
                
                let month = date.components(separatedBy: "/").first ?? "01"
                let day = date.components(separatedBy: "/").last ?? "01"
                
                let total = source.filter { model in
                    return model.day == "\(year)-\(month)-\(day)"
                }.map({
                    $0.ml
                }).reduce(0, +)
                
                return Charts.Model(progress: Double(total)  / Double(max), ml: total, unit: date)

            }
        case .year:
            return  rightBottomSourceString.reversed().map { month in
                let total = source.filter { model in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let date = formatter.date(from: model.day)
                    formatter.dateFormat = "MMM"
                    let m = formatter.string(from: date!)
                    return m == month
                }.map({
                    $0.ml
                }).reduce(0, +)
                return Charts.Model(progress: Double(total)  / Double(max), ml: total, unit: month)

            }
        }
    }
}

struct ChartsView: View {
    let store: StoreOf<Charts>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
        } destination: {
            switch $0 {
            case .history:
                CaseLet(/Charts.Path.State.history, action: Charts.Path.Action.history, then: HistoryView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<Charts>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    HStack{
                        Image("charts_title")
                        Spacer()
                        Image("history").onTapGesture {
                            viewStore.send(.historyButtonTapped)
                        }
                    }.padding(.horizontal, 24).padding(.top, 13)
                    ItemsView(store: store)
                    ZStack(alignment: .leading){
                        VStack{
                            LeftView(state: viewStore.state)
                            Spacer().frame(height: 30)
                        }
                        RightView(state: viewStore.state)
                    }.font(.system(size: 12))
                    Spacer()
                    HStack{
                        GADNativeView(model: viewStore.ad)
                    }.frame(height: 124).padding(.horizontal, 20).padding(.bottom, 30)
                }
                .background(Color("#F8FFF9"))
            }.navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct ItemsView: View {
        let store: StoreOf<Charts>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                LazyHGrid(rows: [GridItem(.flexible(), spacing: 0)], content: {
                    ForEach(viewStore.topSource, id: \.self) { item in
                        VStack{
                            if viewStore.item == item {
                                Button(action: {
                                    viewStore.send(.itemSelected(item))
                                }, label: {
                                    Text(item.title)
                                }).padding(.horizontal, 24).padding(.vertical, 12)
                                    .background(.linearGradient(colors: [Color("#59FAFF"), Color("#159192")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .foregroundStyle(Color.white).cornerRadius(20)
                            } else {
                                Button(action: {
                                    viewStore.send(.itemSelected(item))
                                }, label: {
                                    Text(item.title)
                                }).padding(.horizontal, 24).padding(.vertical, 12).foregroundStyle(Color.black)
                            }
                        }.font(.system(size: 14))
                    }
                    
                }).frame(height: 40).padding(.horizontal, 28).padding(.vertical, 15).padding(.top, 20)
            }
        }
    }
    
    struct LeftView: View {
        let state: Charts.State
        var body: some View {
            HStack{
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 0, content: {
                    ForEach(state.leftSourceString, id: \.self) { item in
                        HStack{
                            Spacer()
                            VStack{
                                Spacer()
                                Text(item).frame(height: 14)
                            }
                        }.frame(height: 42)
                    }
                }).frame(width: 60)
                Spacer()
            }
        }
    }
    
    struct RightView: View {
        let state: Charts.State
        var body: some View {
            HStack(alignment: .top){
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 15, content: {
                        ForEach(state.rightBottomSourceString.indices, id: \.self) { index in
                            VStack(spacing: 0){
                                VStack(spacing: 0){
                                    GeometryReader { proxy in
                                        Color("#2DB6B9")
                                        Color.white.frame(height: proxy.size.height * (1-state.rightCenterSourceString[index].progress))
                                    }
                                }.frame(width: 36)
                                Text(verbatim: "\(state.rightBottomSourceString[index])").frame(height: 30)
                            }
                        }
                    })
                }.padding(.leading, 80).padding(.trailing, 20)
            }.frame(height: CGFloat(state.leftSource.count) * 42 + 30)
        }
    }
}

#Preview {
    ChartsView(store: Store.init(initialState: Charts.State(), reducer: {
        Charts()
    }))
}
