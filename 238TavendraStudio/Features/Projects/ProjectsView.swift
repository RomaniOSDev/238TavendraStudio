import Combine
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
