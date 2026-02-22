//
//  ProfileButtonView.swift
//

import SwiftUI

struct ProfileButtonView: View {
    @State var profileName: String
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Text(profileName).font(.system(size: 15)).foregroundColor(Color(hex: "#848484"))
                    .bold().padding(.trailing, 15)
            }.frame(height: 50)
            Divider()
            
            Button {
                
            } label: {
                Text("Account Settings").font(.system(size: 17)).foregroundColor(.black).bold()
            }.frame(height: 50, alignment: .center)
            Divider()
            
            Button {
                
            } label: {
                Text("Help").font(.system(size: 17)).foregroundColor(.black).bold()
            }.frame(height: 50, alignment: .center)
            Divider()
            
            Button {
                
            } label: {
                Text("Sign out").font(.system(size: 17)).foregroundColor(Color(hex: "#BC1919")).bold()
            }.frame(height: 50, alignment: .center)
            Divider()

        }.cornerRadius(20).shadow(color: Color.shadow, radius: 10)
            .frame(height: 200, alignment: .bottom)
    }
}

struct ProfileButtonView_Previews: PreviewProvider {
    static var profileName = "IBI Group"
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        ProfileButtonView(profileName: profileName)
    }
}
