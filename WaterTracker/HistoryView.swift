//
//  HistoryView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/17.
//

import SwiftUI
import ComposableArchitecture

struct History: Reducer {
    struct State: Equatable {
        var source: [Record.Model]
    }
    enum Action: Equatable {
        case pop
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

extension History.State {
    var sourceString: [[Record.Model]] {
        return (source).reduce([]) { (result, item) -> [[Record.Model]] in
            var result = result
            if result.count == 0 {
                result.append([item])
            } else {
                if var arr = result.last, let lasItem = arr.last, lasItem.day == item.day  {
                    arr.append(item)
                    result[result.count - 1] = arr
                } else {
                    result.append([item])
                }
            }
           return result
        }.reversed()
    }
}

struct HistoryView: View {
    let store: StoreOf<History>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing:  20) {
                        ForEach(viewStore.sourceString, id: \.self) { items in
                            ContentView(items: items)
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 20).padding(.top, 20)
            }
            .background(Image("goal_bg").resizable().ignoresSafeArea())
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {viewStore.send(.pop)}, label: {
                        Image("back")
                    })
                }
                ToolbarItem(placement: .principal) {
                    Image("history_title")
                }
            })
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
    }
    
    struct ContentView: View {
        let items: [Record.Model]
        var body: some View {
            VStack(alignment: .leading){
                HStack{
                    Image("history_date").frame(width: 28, height: 28)
                    Text(items.first?.day ?? "")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading,8)
                }.padding(.top, 14).padding(.leading, 16)
                Divider()
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 6){
                            Image(item.item.icon).resizable().scaledToFit().frame(width: 40, height: 40)
                            Text(item.description).font(.system(size: 12, weight: .semibold))
                        }.padding(.vertical, 8).background(.white).cornerRadius(8)
                    }
                }.padding(.horizontal, 14).padding(.bottom, 15).background(Color("#B2E9FF").cornerRadius(12))
            }.background(.white).cornerRadius(8)
        }
    }
}
