//
//  RecordView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/17.
//

import SwiftUI
import ComposableArchitecture

struct Record: Reducer {
    struct State: Equatable {
        @BindingState var ml: String = "200"
        @BindingState var name: String = "Water"
        let items = Item.allCases
        var item: Item = .water
    }
    enum Action:BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pop
        case update(Model)
        case itemSelected(State.Item)
        case okButtonTapped
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case let .itemSelected(item):
                if item == state.item {
                    return .none
                }
                state.name = item.title
                state.item = item
            case .okButtonTapped:
                if state.checkML {
                    return .run { [model = state.model] send in
                        await send(.update(model))
                        await send(.pop)
                    }
                }
            default:
                break
            }
            return .none
        }
    }
    
    struct Model: Codable, Hashable, Equatable {
        var id: String = UUID().uuidString
        var day: String // yyyy-MM-dd
        var time: String // HH:mm
        var item: State.Item // 列别
        var name: String
        var ml: Int // 毫升
        
        var description: String {
            return name + " \(ml)ml"
        }
    }
}

extension Record.State {
    enum Item: String, Equatable, CaseIterable, Codable {
        case water, drinks, milk, coffee, tea, custom
        var icon: String{
            self.rawValue
        }
        var title: String{
            return self.rawValue.capitalized
        }
        var description: String{
            "\(title) 200ml"
        }
    }
    
    var model: Record.Model {
        Record.Model(day: Date().day, time: Date().time, item: item, name: name, ml: Int(ml) ?? 0)
    }
    
    var checkML: Bool {
        return (Int(ml) ?? 0) > 0
    }
}

struct RecordView: View {
    let store: StoreOf<Record>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack(spacing: 20){
                EditorView(store: store)
                ItemsView(store: store)
                SaveButton(store: store)
                Spacer()
            }.background(Color("#F8FFF9")).toolbarRole(.navigationStack).toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {viewStore.send(.pop)}, label: {
                        Image("back")
                    })
                }
            })
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbarRole(.navigationStack).toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Image("goal_title")
                }
            })
    }
    
    struct EditorView: View {
        let store: StoreOf<Record>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    HStack{
                        Image(viewStore.item.icon).frame(width: 100, height: 100)
                        VStack{
                            HStack{
                                TextField("", text: viewStore.$name).padding(.all, 10).background(Color("#E7F6F4").cornerRadius(8))
                                Spacer()
                            }
                            HStack{
                                TextField("", text: viewStore.$ml).padding(.all, 10).background(Color("#E7F6F4").cornerRadius(8)).keyboardType(.numbersAndPunctuation)
                                Spacer()
                            }
                        }.font(.system(size: 13.0))
                    }.background(Color.white.cornerRadius(8)).padding(.horizontal, 20).padding(.vertical, 34)
                }.background(Color("#D9F7F3").cornerRadius(32, corners: [.bottomLeft, .bottomRight]))
            }
        }
    }
    
    struct ItemsView: View {
        let store: StoreOf<Record>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                VStack{
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16, content: {
                        ForEach(viewStore.items, id: \.self) { item in
                            Button(action: {
                                viewStore.send(.itemSelected(item))
                            }, label: {
                                HStack{
                                    Image(item.icon).frame(width: 55, height: 55)
                                    VStack(alignment: .leading){
                                        Text(item.title).foregroundStyle(Color("#83B8B8")).font(.system(size: 14))
                                        Text("200ml").foregroundStyle(.black).font(.system(size: 16))
                                    }
                                }
                            })
                            .padding([.top, .leading, .bottom], 16)
                            .padding(.trailing, 30)
                            .background(getItemSelectStyle(item == viewStore.item))
                            .cornerRadius(10)
                            .shadow(color: Color("#DAE8DC"), radius: 2)
                        }
                    })
                }
            }
        }
        
        func getItemSelectStyle(_ selected: Bool) -> some View {
            VStack{
                if selected {
                    RoundedRectangle(cornerRadius: 10).stroke( Color("#34D9B8"))
                } else {
                    Color.white.cornerRadius(10)
                }
            }
        }
    }
    
    struct SaveButton: View {
        let store: StoreOf<Record>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                Button(action: {
                    viewStore.send(.okButtonTapped)
                }, label: {
                    ZStack{
                        Image("record_bg")
                        Text("OK").foregroundStyle(.white)
                    }
                })
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension Date {
    
    var day: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    
    var time: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: self)
    }
    
}
