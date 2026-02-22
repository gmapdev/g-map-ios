//
//  OfflineDialog.swift
//

import SwiftUI


struct OfflineDialog: View {
    @ObservedObject var env = Env.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.6))
            .zIndex(9990)
            VStack(alignment: .center){
                TextLabel("No Internet", .bold ,.title2)
                    .foregroundColor(.black)
                
                Image("ic_nointernet")
                    .resizable()
                    .frame(width: 80, height: 80)
                
                TextLabel("We can't access the internet. Try connecting via WiFi or cellular data.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing, .bottom], 20)
                
                Button {
                    env.pubShowOfflineDialog = false
                } label: {
                    TextLabel("OK", .bold, .headline)
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 40)
                .background(Color.main)
                .cornerRadius(10)
                .padding(.top, 10)
            }
            .frame(height: 300)
            .background(Color.white)
            .cornerRadius(10)
            .zIndex(9999)
        }
    }
}

struct OfflineDialog_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        OfflineDialog()
    }
}
