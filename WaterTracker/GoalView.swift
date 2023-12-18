//
//  GoalView.swift
//  WaterTracker
//
//  Created by yangjian on 2023/11/16.
//

import SwiftUI
import ComposableArchitecture

struct Goal: Reducer {
    struct State: Equatable {
        var goal: Int
    }
    enum Action: Equatable {
        case pop
        case reduceButtonTapped
        case decreaseButtonTapped
        case update(Int)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .reduceButtonTapped:
            state.goal += 100
            state.goal = state.goal > 4000 ? 4000 : state.goal
            debugPrint("+++++++")
            return .run { [goal = state.goal] send in
                await send(.update(goal))
            }
        case .decreaseButtonTapped:
            state.goal -= 100
            state.goal = state.goal <= 100 ? 100 : state.goal
            debugPrint("——————")
            return .run { [goal = state.goal] send in
                await send(.update(goal))
            }
        case .update(_):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        default:
            break
        }
        return .none
    }
}

extension Goal.State {
    var progress: Double {
        Double(goal) / 4000.0
    }
    
    var circleProgress: Double {
        progress / 2.0
    }
    var x: Double {
        let hu = progress * Double.pi
        let x = (1 - cos(hu)) * 100
        if x <= 100 {
            return x + 12
        } else if x < 112 {
            return 112.0
        }
        return x
    }
    var y: Double {
        let hu = progress * Double.pi
        let y = (1 - sin(hu)) * 100
        return y - 6
    }
}

struct GoalView: View {
    let store: StoreOf<Goal>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack(spacing: 0) {
                HStack{Spacer()}
                Text("Your daily water goal：\(viewStore.goal)ml").opacity(0.5)
                ZStack{
                    CircleView(progress: 0.5, width: 12.0, color: UIColor(named: "#C8F1EE")!)
                    CircleView(progress: viewStore.circleProgress, width: 12.0, color: UIColor(named: "#2DB6B9")!)
                }
                .frame(width: 200, height: 200).rotationEffect(.degrees(270)).padding(.top, 40)
                
                VStack(alignment: .leading){
                    HStack{
                        Image("goal_point").padding(.leading, viewStore.x).padding(.top, viewStore.y)
                        Spacer()
                    }
                    Spacer()
                }.frame(width: 240, height: 100).padding(.top, -200)
                
                HStack{
                    Image("goal_-").onTapGesture {
                        viewStore.send(.decreaseButtonTapped)
                    }
                    Spacer()
                    Image("goal_+").onTapGesture {
                        viewStore.send(.reduceButtonTapped)
                    }
                }.frame(width: 240, height: 40).padding(.top, -120)
                Spacer()
            }
            .background(Image("goal_bg").resizable().ignoresSafeArea())
            .toolbarRole(.navigationStack).toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {viewStore.send(.pop)}, label: {
                        Image("back")
                    })
                }
            })
        }.navigationBarBackButtonHidden()
        .toolbarRole(.navigationStack).toolbar(content: {
            ToolbarItem(placement: .principal) {
                Image("goal_title")
            }
        })
    }
}
