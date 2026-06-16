import SwiftUI

struct CategoryManagerSheet: View {
    @Bindable var groupVM: GroupViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddForm = false
    @State private var editTarget: GroupCategory?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.secGap) {
                    defaultsSection
                    customSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AppTheme.bg)
            .navigationTitle(String(localized: "Manage Categories"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editTarget = nil
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await groupVM.fetchCategories() }
            .sheet(isPresented: $showAddForm) {
                CategoryFormSheet(groupVM: groupVM, editing: nil)
            }
            .sheet(item: $editTarget) { cat in
                CategoryFormSheet(groupVM: groupVM, editing: cat)
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "OK")) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
    }

    private var defaultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default (cannot be modified)")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSec)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(AppTheme.categories.enumerated()), id: \.offset) { i, cat in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(cat.color)
                            .frame(width: 14, height: 14)
                        Text(cat.name)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48)

                    if i < AppTheme.categories.count - 1 {
                        Divider().padding(.leading, 42)
                    }
                }
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSec)
                .padding(.leading, 4)

            if groupVM.customCategories.isEmpty {
                Text("No custom categories yet")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textTer)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
                    .cardShadow()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(groupVM.customCategories.enumerated()), id: \.element.id) { i, cat in
                        customRow(cat: cat)
                        if i < groupVM.customCategories.count - 1 {
                            Divider().padding(.leading, 42)
                        }
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
                .cardShadow()
            }

            Text("Deleting will not affect existing items")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTer)
                .padding(.leading, 4)
        }
    }

    private func customRow(cat: GroupCategory) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: cat.color))
                .frame(width: 14, height: 14)
            Text(cat.name)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.text)
            Spacer()
            Button {
                editTarget = cat
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSec)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            Button(role: .destructive) {
                Task {
                    do {
                        try await groupVM.deleteCategory(id: cat.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.deleteText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
}

// MARK: - Category Form Sheet

struct CategoryFormSheet: View {
    let groupVM: GroupViewModel
    let editing: GroupCategory?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: String = CategoryFormSheet.colorPalette[0]
    @State private var isSaving = false
    @State private var errorMessage: String?

    static let colorPalette = [
        "#54A862", "#D9695F", "#E0A03A", "#C5934F",
        "#5690C9", "#B179B0", "#D981A6", "#7C8AA1",
        "#16A368", "#98A0A4",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField(String(localized: "Category name"), text: $name)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(AppTheme.fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))

                    colorGrid
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 24)
            .background(AppTheme.bg)
            .navigationTitle(editing == nil ? String(localized: "Add Category") : String(localized: "Edit Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .alert(String(localized: "Error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "OK")) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let cat = editing {
                name = cat.name
                selectedColor = cat.color
            }
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
            ForEach(Self.colorPalette, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: selectedColor == hex ? 3 : 0)
                            .padding(2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(hex: hex), lineWidth: selectedColor == hex ? 2 : 0)
                    )
                    .onTapGesture { selectedColor = hex }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            do {
                if let cat = editing {
                    try await groupVM.updateCategory(id: cat.id, name: trimmed, color: selectedColor)
                } else {
                    try await groupVM.createCategory(name: trimmed, color: selectedColor)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
