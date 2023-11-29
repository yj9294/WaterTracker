//
//  Reminder.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/15.
//

import UIKit
import SwiftUI
import ComposableArchitecture

struct Reminder: Reducer {
    struct State: Equatable {
        static func == (lhs: Reminder.State, rhs: Reminder.State) -> Bool {
            lhs.source == rhs.source && lhs.picker == rhs.picker && lhs.showPickerView == rhs.showPickerView
        }
        
        @UserDefault(key: "reminder.list")
        var source: [String]?
        
        var showPickerView: Bool = false
        
        var picker: DatePicker.State = .init()
        
    }
    enum Action: Equatable {
        case addButtonTapped
        case deleteButtonTapped(String)
        
        case picker(DatePicker.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .addButtonTapped:
                state.showPickerView = true
            case let .deleteButtonTapped(item):
                state.deleteItem(item)
            case .picker(.cancelButtonTapped):
                state.showPickerView = false
            case let .picker(.dateSaveButtonTapped(item)):
                state.showPickerView = false
                state.addItem(item)
            }
            return .none
        }
        Scope(state: \.picker, action: /Action.picker) {
            DatePicker()
        }
    }
}

extension Reminder.State {
    
    var sourceValue: [String] {
        source ?? ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00"]
    }
    
    mutating func deleteItem(_ item: String) {
        if source == nil {
            source = sourceValue
        }
        source?.removeAll{$0 == item}
        NotificationHelper.shared.deleteNotifications(item)
    }
    
    mutating func addItem(_ item: String) {
        if source == nil {
            source = sourceValue
        }
        source?.append(item)
        source?.sort{$0 < $1}
        NotificationHelper.shared.appendReminder(item)
    }
}

struct ReminderView: View {
    let store: StoreOf<Reminder>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            ZStack {
                RootView(store: store)
                if viewStore.showPickerView {
                    DatePickerView(store: store.scope(state: \.picker, action: {.picker($0)})).ignoresSafeArea()
                }
            }
        }.navigationBarBackButtonHidden().navigationBarTitleDisplayMode(.inline)
    }
    
    struct RootView: View {
        let store: StoreOf<Reminder>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    HStack{
                        Image("reminder_title")
                        Spacer()
                        Image("reminder_add").onTapGesture {
                            viewStore.send(.addButtonTapped)
                        }
                    }.padding(.horizontal, 24).padding(.top, 13)
                    ScrollView{
                        ForEach(viewStore.sourceValue, id: \.self) { item in
                            HStack{
                               Text(item)
                                Spacer()
                                Button(action: {
                                    viewStore.send(.deleteButtonTapped(item))
                                }, label: {
                                    Image("reminder_delete")
                                })
                            }.frame(height: 70).padding(.horizontal, 24)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

struct DatePicker: Reducer {
    struct State: Equatable {}
    enum Action: Equatable {
        case dateSaveButtonTapped(String)
        case cancelButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DatePickerView: UIViewRepresentable {
    let store: StoreOf<DatePicker>
    func makeUIView(context: Context) -> some UIView {
        if let view = Bundle.main.loadNibNamed("DateView", owner: nil)?.first as? DateView {
            view.delegate = context.coordinator
           return view
        }
        let dateView = DateView()
        dateView.delegate = context.coordinator
        return dateView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DateViewDelegate {
        init(_ preview: DatePickerView) {
            self.parent = preview
        }
        let parent: DatePickerView
        
        func completion(time: String) {
            parent.store.send(.dateSaveButtonTapped(time))
        }
        
        func cancel() {
            parent.store.send(.cancelButtonTapped)
        }
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

protocol DateViewDelegate : NSObjectProtocol {
    func completion(time: String)
    func cancel()
}

class DateView: UIView {

    weak var delegate: DateViewDelegate?
    var selectedHours = 0
    var selectedMine = 0
    var hours:[Int] = Array(0..<13)
    var minu: [Int] = Array(0..<60)
    @IBOutlet weak var hourView: UIPickerView!
    @IBOutlet weak var minuView: UIPickerView!
    @IBOutlet weak var amLabel: UIButton!
    @IBOutlet weak var pmLabel: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        hours.append(contentsOf: Array(1..<12))
    }
    
    @IBAction func saveAction() {
        let str = String(format: "%02d:%02d", selectedHours, selectedMine)
        delegate?.completion(time: str)
    }
    
    @IBAction func cancelAction() {
        delegate?.cancel()
    }
}

extension DateView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == hourView {
            return hours.count
        }
        return minu.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 56.0
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let view = view as? UIButton{
            view.isSelected = pickerView == hourView ? selectedHours == row : selectedMine == row
            if view.isSelected {
                view.titleLabel?.font = UIFont.systemFont(ofSize: 40)
            } else {
                view.titleLabel?.font = UIFont.systemFont(ofSize: 22)
            }
            let str = String(format: "%02d", pickerView == hourView ? hours[row] : minu[row])
            view.setTitle(str, for: .normal)
            return view
        }
        let view = UIButton()
        view.isSelected = pickerView == hourView ? selectedHours == row : selectedMine == row
        view.setTitleColor(UIColor(named: "#141E1F"), for: .selected)
        view.setTitleColor(UIColor(named: "#93ACA8"), for: .normal)
        if view.isSelected {
            view.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        } else {
            view.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        }
        let str = String(format: "%02d", pickerView == hourView ? hours[row] : minu[row])
        view.setTitle(str, for: .normal)
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == hourView {
            selectedHours = row
        } else {
            selectedMine = row
        }
        if pickerView == hourView {
            if selectedHours < 13 {
                amLabel.titleLabel?.textColor = .white
                amLabel.backgroundColor = UIColor(named: "#38C7CA")
                pmLabel.titleLabel?.textColor = UIColor(named: "#141E1F")
                pmLabel.backgroundColor = .clear
            } else {
                pmLabel.titleLabel?.textColor = .white
                pmLabel.backgroundColor = UIColor(named: "#38C7CA")
                amLabel.titleLabel?.textColor = UIColor(named: "#141E1F")
                amLabel.backgroundColor = .clear
            }
        }
        pickerView.reloadComponent(0)
    }
}


#Preview {
    NavigationView {
        ReminderView(store: Store.init(initialState: Reminder.State(), reducer: {
            Reminder()
        }))
    }
}
