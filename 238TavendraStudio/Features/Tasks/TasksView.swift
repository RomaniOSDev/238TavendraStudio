import Combine
import SwiftUI

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var editingTask: TaskItem?
    @Published var pulsingTaskID: UUID?
    @Published var showSuccessCheckmark = false

    func openAdd() {
        FeedbackManager.lightTap()
        editingTask = nil
        showAddSheet = true
    }

    func openEdit(_ task: TaskItem) {
        FeedbackManager.lightTap()
        editingTask = task
        showAddSheet = true
    }

    func triggerCompletionAnimation(for taskID: UUID) {
        pulsingTaskID = taskID
        showSuccessCheckmark = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.pulsingTaskID = nil }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.showSuccessCheckmark = false }
    }
}

struct TasksView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = TasksViewModel()
    @State private var isEditingOrder = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    if !store.filteredTasks.isEmpty {
                        summaryStrip
                    }

                    if store.filteredTasks.isEmpty {
                        ScrollView {
                            AppEmptyState(
                                icon: "tray.fill",
                                title: "No Tasks Yet",
                                message: "Tap + to add your first task and organize your day",
                                actionTitle: "Add Task",
                                action: { viewModel.openAdd() }
                            )
                        }
                        .appScrollChrome()
                    } else {
                        taskList
                    }

                    AppFilterBar(options: TaskFilterOption.allCases, selection: Binding(
                        get: { store.filterOption },
                        set: { store.filterOption = $0 }
                    ))
                }

                if viewModel.showSuccessCheckmark {
                    SuccessCheckmarkOverlay(isVisible: $viewModel.showSuccessCheckmark)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.showSuccessCheckmark)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        if !store.filteredTasks.isEmpty {
                            Button(isEditingOrder ? "Done" : "Reorder") {
                                FeedbackManager.lightTap()
                                isEditingOrder.toggle()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppPrimary"))
                        }
                        NavigationLink {
                            ProjectsView().environmentObject(store)
                        } label: {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color("AppPrimary"))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color("AppSurface")))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { viewModel.openAdd() } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color("AppPrimary")))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                TaskFormView(task: viewModel.editingTask).environmentObject(store)
            }
        }
        .appScreenChrome()
    }

    private var summaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                AppChip(text: "\(store.tasks.filter { !$0.completed }.count) open", icon: "circle", style: .accent)
                AppChip(text: "\(store.tasks.filter(\.completed).count) done", icon: "checkmark", style: .primary)
                AppChip(text: "\(store.projects.count) projects", icon: "folder.fill", style: .neutral)
            }
            .padding(.horizontal, AppLayout.padding)
            .padding(.vertical, 10)
        }
    }

    private var taskList: some View {
        List {
            ForEach(store.filteredTasks) { task in
                TaskCell(
                    task: task,
                    projectName: store.projectName(for: task.projectId),
                    isPulsing: viewModel.pulsingTaskID == task.id,
                    onToggle: {
                        let wasPending = !task.completed
                        store.toggleTaskCompletion(task)
                        if wasPending { viewModel.triggerCompletionAnimation(for: task.id) }
                    },
                    onEdit: { viewModel.openEdit(task) }
                )
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { store.deleteTask(task) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        store.toggleTaskCompletion(task)
                        if !task.completed { viewModel.triggerCompletionAnimation(for: task.id) }
                    } label: {
                        Label(task.completed ? "Undo" : "Done", systemImage: "checkmark")
                    }
                    .tint(Color("AppPrimary"))
                }
            }
            .onMove { source, destination in
                store.moveTasks(from: source, to: destination, in: store.filteredTasks)
            }
        }
        .listStyle(.plain)
        .appScrollChrome()
        .environment(\.editMode, .constant(isEditingOrder ? .active : .inactive))
    }
}

struct TaskFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem?
    var defaultDayBlock: DayBlock?

    @State private var title = ""
    @State private var category = "General"
    @State private var priority: TaskPriority = .medium
    @State private var dayBlock: DayBlock?
    @State private var workContext: WorkContext = .deepWork
    @State private var projectId: UUID?
    @State private var energyLevel: EnergyLevel = .medium
    @State private var shakeTrigger = 0
    @State private var errorMessage = ""

    private var isEditing: Bool { task != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        formField(title: "Title", content: {
                            TextField("Task title", text: $title)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .shake(trigger: shakeTrigger)
                        })
                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                        formField(title: "Category", content: {
                            TextField("Category", text: $category).foregroundStyle(Color("AppTextPrimary"))
                        })
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                            Picker("Priority", selection: $priority) {
                                ForEach(TaskPriority.allCases) { p in
                                    Text(p.rawValue).tag(p)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        formOptionalBlockPicker()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Context").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                            Picker("Context", selection: $workContext) {
                                ForEach(WorkContext.allCases) { ctx in
                                    Text(ctx.rawValue).tag(ctx)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                            Picker("Energy", selection: $energyLevel) {
                                ForEach(EnergyLevel.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        projectPicker()
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { FeedbackManager.lightTap(); dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTask() }.foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear { loadFields() }
        }
        .appScreenChrome()
        .presentationDetents([.large])
    }

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
            content()
                .padding(14)
                .background(RoundedRectangle(cornerRadius: AppLayout.cellRadius).fill(Color("AppSurface")))
        }
    }

    private func formOptionalBlockPicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Block").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
            Picker("Block", selection: $dayBlock) {
                Text("Inbox").tag(DayBlock?.none)
                ForEach(DayBlock.allCases) { block in
                    Text(block.rawValue).tag(Optional(block))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func projectPicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
            Picker("Project", selection: $projectId) {
                Text("None").tag(UUID?.none)
                ForEach(store.projects) { p in
                    Text(p.name).tag(Optional(p.id))
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: AppLayout.cellRadius).fill(Color("AppSurface")))
        }
    }

    private func loadFields() {
        if let task {
            title = task.title; category = task.category; priority = task.priority
            dayBlock = task.dayBlock; workContext = task.workContext
            projectId = task.projectId; energyLevel = task.energyLevel
        } else {
            dayBlock = defaultDayBlock
            workContext = defaultDayBlock?.defaultContext ?? .deepWork
            energyLevel = workContext.suggestedEnergy
        }
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a task title"
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        if var existing = task {
            existing.title = trimmed
            existing.category = category.isEmpty ? "General" : category
            existing.priority = priority; existing.dayBlock = dayBlock
            existing.workContext = workContext; existing.projectId = projectId
            existing.energyLevel = energyLevel
            store.updateTask(existing)
            FeedbackManager.success()
        } else {
            store.addTask(title: trimmed, category: category.isEmpty ? "General" : category,
                          priority: priority, dayBlock: dayBlock, workContext: workContext,
                          projectId: projectId, energyLevel: energyLevel)
        }
        dismiss()
    }
}
