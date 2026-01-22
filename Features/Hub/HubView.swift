//
//  HubView.swift
//  Positiv
//
//  Created by DnD-Luk on 21/01/2026.
//


import SwiftUI

struct HubView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Mes Applications")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ModuleCard(module: .countdown, isUnlocked: storeManager.isCountdownUnlocked)
                        ModuleCard(module: .affirmation, isUnlocked: storeManager.isAffirmationUnlocked)
                        ModuleCard(module: .art, isUnlocked: storeManager.isArtUnlocked)
                    }
                    .padding()
                }
            }
            .navigationTitle("Positiv Hub")
            .navigationBarHidden(true)
        }
    }
}

struct ModuleCard: View {
    let module: ModuleType
    let isUnlocked: Bool
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        VStack {
            Image(systemName: module.iconName)
                .font(.system(size: 40))
                .foregroundColor(isUnlocked ? .white : .gray)
                .padding()
            
            Text(module.rawValue)
                .font(.headline)
                .foregroundColor(isUnlocked ? .white : .gray)
            
            Spacer()
            
            if isUnlocked {
                NavigationLink(destination: destinationView()) {
                    Text("Ouvrir")
                        .font(.footnote).bold()
                        .padding(.vertical, 8).padding(.horizontal, 20)
                        .background(Color.white).foregroundColor(.black)
                        .cornerRadius(20)
                }
            } else {
                Button(action: { storeManager.purchase(module: module) }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text(module.price)
                    }
                    .font(.caption).padding(8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }
            }
            Spacer()
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(isUnlocked ? Color.blue : Color.black.opacity(0.05))
        .cornerRadius(20)
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        switch module {
        case .affirmation:
            // Si tu as déjà créé AffirmationsView, utilise-le ici, sinon mets un Text
            if #available(iOS 15.0, *) {
               AffirmationsView().navigationBarHidden(true)
            } else {
               Text("Affirmations")
            }
        default:
            Text("Bientôt disponible")
        }
    }
}