//
//  DrinkView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct Drink: Reducer {
    struct State: Equatable {
        static func == (lhs: Drink.State, rhs: Drink.State) -> Bool {
            lhs.goal == rhs.goal && lhs.record == rhs.record && lhs.ad == rhs.ad && lhs.path == rhs.path
        }
        @UserDefault(key: "drink.goal")
        var goal: Int?
        @UserDefault(key: "drink.record")
        var record: [Record.Model]?
        
        var path: StackState<Path.State> = .init()
        
        var ad: GADNativeViewModel = .none
    }
    
    enum Action: Equatable {
        case recordButtonTapped
        case goalButtonTapped
        case recordUpdated([Record.Model])
        case pushGoalView
        case path(StackAction<Path.State, Path.Action>)
        
        case adUpdate(GADNativeViewModel)
        
        case popRecordView
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .goalButtonTapped:
                GADUtil.share.load(.interstitial)
                let publisher = Future<Action, Never>{ promiss in
                    GADUtil.share.show(.interstitial) { _ in
                        promiss(.success(.pushGoalView))
                    }
                }
                return .publisher {
                    publisher
                }
            case .pushGoalView:
                state.pushGoalView()
            case .recordButtonTapped:
                state.pushRecordView()
            case let .path(action):
                switch action {
                case .element(id: _, action: .goal(.pop)):
                    state.popView()
                case .element(id: _, action: .record(.pop)):
                    GADUtil.share.load(.interstitial)
                    let publisher = Future<Action, Never> { promiss in
                        GADUtil.share.show(.interstitial) { _ in
                            promiss(.success(.popRecordView))
                        }
                    }
                    return .publisher {
                        publisher
                    }
                case let .element(id: _, action: .goal(.update(goal))):
                    state.updateGoal(goal)
                case let .element(id: _, action: .record(.update(model))):
                    state.updateRecord(model)
                    return .run { [record = state.recordValue] send in
                        await send(.recordUpdated(record))
                    }
                default:
                    break
                }
            case .adUpdate(let ad):
                state.updateAD(ad)
            case .popRecordView:
                state.popView()
            default:
                break
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case goal(Goal.State)
            case record(Record.State)
        }
        enum Action: Equatable {
            case goal(Goal.Action)
            case record(Record.Action)
        }
        
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.goal, action: /Action.goal) {
                Goal()
            }
            Scope(state: /State.record, action: /Action.record) {
                Record()
            }
        }
    }
}

extension Drink.State {
    mutating func updateAD(_ ad: GADNativeViewModel) {
        self.ad = ad
    }
    
    var drinkValue: Int {
        let ml = (record ?? []).filter { model in
            model.day == Date().day
        }.map({
            $0.ml
        }).reduce(0, +)
        return ml
    }
    
    var recordValue: [Record.Model] {
        record ?? []
    }
    var progressValue: Double {
        return Double(drinkValue) / Double(goalValue)
    }
    var progressString: String {
        "\(Int(progressValue * 100))%"
    }
    var goalValue: Int {
        goal ?? 2000
    }
    var goalString: String {
        "\(goalValue)ml"
    }
    
    mutating func pushGoalView() {
        if !appEnterBackground {
            path.append(.goal(.init(goal: goalValue)))
            GADUtil.share.disappear(.native)
        }
    }
    mutating func popView() {
        path.removeAll()
        GADUtil.share.load(.native)
    }
    mutating func updateGoal(_ ret: Int) {
        goal = ret
    }
    mutating func pushRecordView() {
        path.append(.record(.init()))
        GADUtil.share.disappear(.native)
    }
    mutating func updateRecord(_ model: Record.Model) {
        if record != nil {
            record?.append(model)
        } else {
            record = [model]
        }
    }
}

struct DrinkView: View {
    let store: StoreOf<Drink>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            RootView(store: store)
        } destination: {
            switch $0 {
            case .goal:
                CaseLet(/Drink.Path.State.goal, action: Drink.Path.Action.goal, then: GoalView.init(store:))
            case .record:
                CaseLet(/Drink.Path.State.record, action: Drink.Path.Action.record, then: RecordView.init(store:))
            }
        }
    }
    
    struct RootView: View {
        let store: StoreOf<Drink>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    HStack{
                        Image("drink_title")
                        Spacer()
                    }.padding(.top, 13).padding(.leading, 24)
                    ProgressView(state: viewStore.state).frame(width: 190, height: 190).padding(.top, 30)
                    HStack{
                        Button(action: {viewStore.send(.recordButtonTapped)}, label: {
                            RecordButton()
                        })
                        Button(action: {viewStore.send(.goalButtonTapped)}, label: {
                            GoalButton(state: viewStore.state)
                        })
                    }.padding(.top, 30)
                    Spacer()
                    HStack{
                        GADNativeView(model: viewStore.ad)
                    }.frame(height: 124).padding(.horizontal, 20).padding(.bottom, 30)
                }.background(Image("drink_bg").resizable().ignoresSafeArea())
            }
        }
    }
    
    struct ProgressView: View {
        let state: Drink.State
        var body: some View {
            ZStack{
                Color("#C8F1EE").cornerRadius(95)
                Image("drink_circle")
                CircleView(progress: state.progressValue)
                Text(state.progressString).font(.largeTitle).fontWeight(.medium)
            }
        }
    }
    
    struct RecordButton: View {
        var body: some View {
            HStack{
                Image("drink_record")
                VStack(alignment: .leading, spacing: 12) {
                    Text("Record").font(.system(size: 16, weight: .bold))
                    Text("Add new!").opacity(0.5)
                }.foregroundColor(Color("#464646"))
            }.padding(.horizontal, 12).padding(.vertical, 22).background(Color("#BAE8E2").cornerRadius(10))
        }
    }
    
    struct GoalButton: View {
        let state: Drink.State
        var body: some View {
            HStack{
                Image("drink_goal")
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal").font(.system(size: 16, weight: .bold))
                    Text(state.goalString).opacity(0.5)
                }.foregroundColor(Color("#464646"))
            }.padding(.horizontal, 12).padding(.vertical, 22).background(Color("#BAE8E2").cornerRadius(10))
        }
    }
}

struct CircleView: UIViewRepresentable {
    let progress: Double
    var width = 6.0
    var tintColor = UIColor(named: "#34D9B8")!
    var point = false
    
    init(progress: Double, width: Double = 6.0, color: UIColor =  UIColor(named: "#34D9B8")!, point: Bool = false) {
        self.progress = progress
        self.width = width
        self.tintColor = color
        self.point = point
    }

    func makeUIView(context: Context) -> some UIView {
        return UICircleProgressView()
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let view = uiView as? UICircleProgressView {
            view.setProgress(Int(progress * 1000.0))
            view.setWidth(width)
            view.setTintColor(tintColor)
            view.setHasPoint(point)
        }
    }
    
    class UICircleProgressView: UIView {
        // 灰色静态圆环
        var staticLayer: CAShapeLayer!
        // 进度可变圆环
        var arcLayer: CAShapeLayer!
        
        var pointLayer: CAShapeLayer!
        
        // 为了显示更精细，进度范围设置为 0 ~ 1000
        var progress = 0
        
        var width = 6.0
        
        var hasPoint = false

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setProgress(_ progress: Int) {
            self.progress = progress
            setNeedsDisplay()
        }
        
        func setWidth(_ width: Double) {
            self.width = width
            setNeedsDisplay()
        }
        
        func setTintColor(_ color: UIColor) {
            self.tintColor = color
            setNeedsDisplay()
        }
        
        func setHasPoint(_ point: Bool) {
            self.hasPoint = point
            setNeedsDisplay()
        }
        
        override func draw(_ rect: CGRect) {
            if arcLayer != nil {
                arcLayer.removeFromSuperlayer()
            }
            arcLayer = createLayer(progress, 6, self.tintColor)
            self.layer.addSublayer(arcLayer)
            
            if pointLayer != nil {
                pointLayer.removeFromSuperlayer()
            }
        }
        
        private func createLayer(_ progress: Int, _ width: Int, _ color: UIColor) -> CAShapeLayer {
            let endAngle = -CGFloat.pi / 2 + (CGFloat.pi * 2) * CGFloat(progress) / 1000
            let layer = CAShapeLayer()
            layer.lineWidth = CGFloat(self.width)
            layer.strokeColor = color.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineCap = .round
            let radius = self.bounds.width / 2 - layer.lineWidth

            let path = UIBezierPath.init(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2), radius: radius, startAngle: -CGFloat.pi / 2, endAngle: endAngle, clockwise: true)
            layer.path = path.cgPath

            return layer
        }
    }
}

@propertyWrapper
struct UserDefault<T: Codable> {
    var value: T?
    let key: String
    init(key: String) {
        self.key = key
        self.value = UserDefaults.standard.getObject(T.self, forKey: key)
    }
    
    var wrappedValue: T? {
        set  {
            value = newValue
            UserDefaults.standard.setObject(value, forKey: key)
            UserDefaults.standard.synchronize()
        }
        
        get { value }
    }
}


extension UserDefaults {
    func setObject<T: Codable>(_ object: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard let object = object else {
            debugPrint("[US] object is nil.")
            self.removeObject(forKey: key)
            return
        }
        guard let encoded = try? encoder.encode(object) else {
            debugPrint("[US] encoding error.")
            return
        }
        self.setValue(encoded, forKey: key)
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else {
            debugPrint("[US] data is nil for \(key).")
            return nil
        }
        guard let object = try? JSONDecoder().decode(type, from: data) else {
            debugPrint("[US] decoding error.")
            return nil
        }
        return object
    }
}


#Preview {
    NavigationView{
        DrinkView(store: Store.init(initialState: Drink.State(), reducer: {
            Drink()
        }))
    }
}
