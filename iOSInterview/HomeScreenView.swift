//
//  ContentView.swift
//  iOSInterview
//
//  Created by Fadil Bećirović on 19. 10. 2025..
//
import SwiftUI
import SwiftData

struct HomeScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]

    @StateObject private var tracker = HorseCountTracker.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Text("Total horses:")
                    Text("\(tracker.total)").font(.title3).bold()
                }

                List {
                    ForEach(horses) { horse in
                        NavigationLink(destination: HorseDetailView(horse: horse)) {
                            VStack(alignment: .leading) {
                                Text(horse.name)
                                Text(horse.breed)
                                Text("\(horse.age) years old")
                            }
                        }
                    }
                    .onDelete(perform: deleteHorse)
                }
                .navigationTitle("Horse List")

                NavigationLink(destination: AddHorseView(modelContext: modelContext)) {
                    Text("Add Horse")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .onAppear {
                tracker.configure(with: modelContext)
                tracker.refreshCount()
            }
        }
    }

    private func deleteHorse(at offsets: IndexSet) {
        DispatchQueue.global(qos: .background).async {
            for index in offsets {
                let horseToDelete = self.horses[index]
                self.modelContext.delete(horseToDelete)
                HorseCountTracker.shared.noteDelete()
            }
            try? self.modelContext.save()
        }
    }
    
    private func checkAndAddDummyHorses() {
        if horses.isEmpty {
            let dummyHorses = [
                Horse(name: "Thunder", breed: "Arabian", age: 4),
                Horse(name: "Storm", breed: "Thoroughbred", age: 3),
                Horse(name: "Bella", breed: "Quarter Horse", age: 5)
            ]
            
            dummyHorses.forEach { horse in
                modelContext.insert(horse)
            }
            
            print("Dummy horses added!")
        }
    }
}

struct AddHorseView: View {
    private let modelContext: ModelContext
    @State private var horseName = ""
    @State private var horseBreed = ""
    @State private var horseAge = ""
    @Environment(\.dismiss) var dismiss

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    var body: some View {
        Form {
            Section(header: Text("Horse Information")) {
                TextField("Enter Horse Name", text: $horseName)
                TextField("Enter Horse Breed", text: $horseBreed)
                TextField("Enter Horse Age", text: $horseAge)
            }
            Button("Save Horse") { addHorse() }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .navigationTitle("Add New Horse")
    }

    private func addHorse() {
        let newHorse = Horse(name: horseName, breed: horseBreed, age: Int(horseAge) ?? 0)
        modelContext.insert(newHorse)
        try? modelContext.save()

        DispatchQueue.global(qos: .userInitiated).async {
            HorseCountTracker.shared.noteInsert()
        }

        dismiss()
    }
}

struct HorseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State var horse: Horse

    var body: some View {
        VStack {
            Text("Editing Horse: \(horse.name)")
                .font(.largeTitle)
            
            TextField("Horse Name", text: $horse.name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Horse Breed", text: $horse.breed)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Horse Age", value: $horse.age, format: .number)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save Changes") {
                saveChanges()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .navigationTitle("Horse Details")
    }

    private func saveChanges() {
        DispatchQueue.global(qos: .background).async {
            let modifiedHorse = self.horse
            
            DispatchQueue.main.async {
                self.horse = modifiedHorse
                print("Saved changes to the horse: \(modifiedHorse.name), Age: \(modifiedHorse.age)")
            }
        }
    }
}

@Model
final class Horse: Identifiable {
    var name: String
    var breed: String
    var age: Int
    var id: String { name }
    
    init(name: String, breed: String, age: Int) {
        self.name = name
        self.breed = breed
        self.age = age
    }
}

#Preview {
    HomeScreenView()
}
