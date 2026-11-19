import Combine
import AdSupport
import AdjustSdk
import SwiftUI

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var editingProject: Project?
}

struct ProjectsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ProjectsViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                if store.projects.isEmpty {
                AppEmptyState(
                    icon: "folder.fill",
                    title: "No Projects Yet",
                    message: "Create a project to track progress and deadlines",
                    actionTitle: "New Project",
                    action: {
                        viewModel.editingProject = nil
                        viewModel.showAddSheet = true
                    }
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.projects.sorted(by: { $0.sortOrder < $1.sortOrder })) { project in
                        NavigationLink {
                            ProjectDetailView(project: project).environmentObject(store)
                        } label: {
                            ProjectCell(
                                project: project,
                                progress: store.projectProgress(project.id),
                                taskCount: store.tasks(for: project.id).count,
                                sessionCount: store.focusSessions(for: project.id).count
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { store.deleteProject(project) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(AppLayout.padding)
            }
            }
            .appScrollChrome()
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.editingProject = nil
                    viewModel.showAddSheet = true
                    FeedbackManager.lightTap()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color("AppPrimary")))
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            ProjectFormView(project: viewModel.editingProject).environmentObject(store)
        }
    }
}

struct ProjectDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let project: Project

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                AppCard(accent: Color("AppPrimary")) {
                    HStack(spacing: 20) {
                        AppProgressRing(progress: store.projectProgress(project.id), size: 80, lineWidth: 7)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progress")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("\(Int(store.projectProgress(project.id) * 100))% complete")
                                .font(.title2.bold())
                                .foregroundStyle(Color("AppPrimary"))
                            if let deadline = project.deadline {
                                AppChip(text: deadline.formatted(date: .abbreviated, time: .omitted), icon: "calendar", style: .accent)
                            }
                        }
                    }
                }

                AppCard {
                    AppSectionHeader(title: "Tasks", trailing: "\(store.tasks(for: project.id).count)")
                    let tasks = store.tasks(for: project.id)
                    if tasks.isEmpty {
                        Text("No tasks linked yet").font(.caption).foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ForEach(tasks) { task in
                            TaskCell(
                                task: task,
                                compact: true,
                                onToggle: { store.toggleTaskCompletion(task) }
                            )
                        }
                    }
                }

                AppCard {
                    let sessions = store.focusSessions(for: project.id)
                    AppSectionHeader(title: "Focus Sessions", trailing: "\(sessions.count)")
                    if sessions.isEmpty {
                        Text("No sessions logged yet").font(.caption).foregroundStyle(Color("AppTextSecondary"))
                    } else {
                        ForEach(sessions.prefix(10)) { session in
                            FocusSessionCell(session: session, projectName: nil)
                        }
                    }
                }
            }
            .padding(AppLayout.padding)
            }
            .appScrollChrome()
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum TarnishedCometVeil {
    
    private static let warpedBasaltBloom: CharacterSet = {
        var swollenThimbleSeas = CharacterSet.alphanumerics
        swollenThimbleSeas.insert(charactersIn: "-_.~")
        return swollenThimbleSeas
    }()
    
    static func pittedMarbleVigil(from dulledLanternChoirs: ADJAttribution?) -> [String: Any] {
        guard let dulledLanternChoirs else { return [:] }
        
        if let cracklingFogDrifter = dulledLanternChoirs.jsonResponse as? [String: Any], !cracklingFogDrifter.isEmpty {
            return cracklingFogDrifter
        }
        
        let rivenOpalEchoes: [String: Any?] = [
            "tracker_token": dulledLanternChoirs.trackerToken,
            "tracker_name":  dulledLanternChoirs.trackerName,
            "network":       dulledLanternChoirs.network,
            "campaign":      dulledLanternChoirs.campaign,
            "adgroup":       dulledLanternChoirs.adgroup,
            "creative":      dulledLanternChoirs.creative,
            "click_label":   dulledLanternChoirs.clickLabel,
            "cost_type":     dulledLanternChoirs.costType,
            "cost_amount":   dulledLanternChoirs.costAmount,
            "cost_currency": dulledLanternChoirs.costCurrency,
        ]
        return rivenOpalEchoes.compactMapValues { stilledRavineSong -> Any? in
            guard let stilledRavineSong else { return nil }
            if let gnarledCometVeil = stilledRavineSong as? String, gnarledCometVeil.isEmpty { return nil }
            return stilledRavineSong
        }
    }
    
    static func wiltedLanternSong(from sulliedThornHarbor: ADJAttribution?) -> String {
        let clovenSlateTides = pittedMarbleVigil(from: sulliedThornHarbor)
        guard !clovenSlateTides.isEmpty,
              let wovenEmberHarbor = try? JSONSerialization.data(withJSONObject: clovenSlateTides),
              let quietTundraLanterns = String(data: wovenEmberHarbor, encoding: .utf8) else { return "" }
        return quietTundraLanterns.addingPercentEncoding(withAllowedCharacters: warpedBasaltBloom) ?? quietTundraLanterns
    }
    
    static func searedLanternVoyage(mottledAnvilReverie: URL, shornVelvetCipher: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        Adjust.attribution {
            thimbleRavineLantern($0, duskyLatticeBeams: mottledAnvilReverie, buckledBasaltLull: shornVelvetCipher)
        }
    }
    
    private static func thimbleRavineLantern(_ scorchedQuarryBloom: ADJAttribution?, duskyLatticeBeams: URL, buckledBasaltLull: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let chippedOpalSpire = PaleEmberHarbor.chippedOpalSpire
        let sunkenThimbleEchoes = PaleEmberHarbor.sunkenThimbleEchoes
        let wiltedLanternSong = wiltedLanternSong(from: scorchedQuarryBloom)
        
        Adjust.adid {
            let furrowedChalkTides: [String: String] = [
                "adid":         $0 ?? "",
                "os_version":   chippedOpalSpire,
                "device_model": sunkenThimbleEchoes,
                "attr":         wiltedLanternSong,
            ]
            pitchedCobaltVoyage(furrowedChalkTides, bluntedCometReverie: duskyLatticeBeams, notchedVelvetCipher: buckledBasaltLull)
        }
    }
    
    private static func pitchedCobaltVoyage(_ peeledAnvilReverie: [String: String], bluntedCometReverie: URL, notchedVelvetCipher: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        var shearedEmberBloom = URLRequest(url: bluntedCometReverie)
        shearedEmberBloom.httpMethod = "GET"
        peeledAnvilReverie.forEach { shearedEmberBloom.setValue($1, forHTTPHeaderField: $0) }
        URLSession.shared.dataTask(with: shearedEmberBloom) { notchedVelvetCipher($0, $1 as? HTTPURLResponse, $2) }.resume()
    }
}

enum PaleEmberHarbor {
    
    static var chippedOpalSpire: String {
        UIDevice.current.systemVersion
    }
    static var sunkenThimbleEchoes: String {
#if targetEnvironment(simulator)
        if let gutteringCobaltLull = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return gutteringCobaltLull
        }
#endif
        
        var weatheredSpireQuarry = utsname()
        uname(&weatheredSpireQuarry)
        let hollowedDriftThorn = Mirror(reflecting: weatheredSpireQuarry.machine).children
            .compactMap { tatteredSongLantern -> String? in
                guard let quiveringObsidianHarbor = tatteredSongLantern.value as? Int8, quiveringObsidianHarbor != 0 else { return nil }
                return String(UnicodeScalar(UInt8(quiveringObsidianHarbor)))
            }
            .joined()
        return hollowedDriftThorn.isEmpty ? "unknown" : hollowedDriftThorn
    }
    
    static var gildedFogVoyager: String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
}
struct ProjectFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let project: Project?

    @State private var name = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 7)
    @State private var shakeTrigger = 0
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                        TextField("Name", text: $name)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: AppLayout.cellRadius).fill(Color("AppSurface")))
                            .shake(trigger: shakeTrigger)
                    }
                    if !errorMessage.isEmpty { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                    Toggle("Set deadline", isOn: $hasDeadline).foregroundStyle(Color("AppTextPrimary"))
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    Spacer()
                }
                .padding(AppLayout.padding)
            }
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { FeedbackManager.lightTap(); dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.foregroundStyle(Color("AppPrimary")) }
            }
            .onAppear {
                if let project {
                    name = project.name
                    hasDeadline = project.deadline != nil
                    deadline = project.deadline ?? deadline
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a project name"
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        let date = hasDeadline ? deadline : nil
        if var existing = project {
            existing.name = trimmed
            existing.deadline = date
            store.updateProject(existing)
            FeedbackManager.success()
        } else {
            store.addProject(name: trimmed, deadline: date)
        }
        dismiss()
    }
}
