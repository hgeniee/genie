//
//  ContentView.swift
//  genie
//
//  Created by 이현진 on 2/4/26.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    // 간단한 루틴 데이터
    let routines = ["물 마시기", "영양제 먹기", "10분 명상", "스쿼트 20개"]
    
    var body: some View {
        NavigationStack {
            List(routines, id: \.self) { routine in
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text(routine)
                }
            }
            .navigationTitle("나의 루틴")
        }
    }
}

#Preview {
    ContentView()
}
