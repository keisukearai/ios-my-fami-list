import SwiftUI
import PhotosUI
import UIKit

struct EditProfileSheet: View {
    let user: AppUser
    let onSave: (AppUser) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var avatarEmoji: String = ""
    @State private var selectedColor: String = ""
    @State private var photoBase64: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarPreview
                    formFields
                    colorSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(AppTheme.bg)
            .navigationTitle(loc("Edit Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("Cancel")) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(loc("Save")) { save() }
                            .accessibilityIdentifier("editProfileSaveButton")
                    }
                }
            }
            .alert(loc("Error"), isPresented: .constant(errorMessage != nil), actions: {
                Button(loc("OK")) { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
        .presentationDetents([.large])
        .onAppear {
            displayName = user.displayName
            avatarEmoji = user.avatarEmoji
            selectedColor = user.avatarColor.isEmpty ? AvatarView.palette[0] : user.avatarColor
            photoBase64 = user.avatarPhoto
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
    }

    private var avatarPreview: some View {
        VStack(spacing: 12) {
            AvatarView(
                name: displayName.isEmpty ? "U" : displayName,
                size: 80,
                colorHex: selectedColor.isEmpty ? nil : selectedColor,
                emoji: avatarEmoji.isEmpty ? nil : avatarEmoji,
                photo: photoBase64.isEmpty ? nil : photoBase64
            )

            HStack(spacing: 16) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(loc("Select Photo"), systemImage: "photo")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.primary)
                }

                if !photoBase64.isEmpty {
                    Button(role: .destructive) {
                        photoBase64 = ""
                        selectedPhoto = nil
                    } label: {
                        Label(loc("Delete Photo"), systemImage: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.deleteText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private var formFields: some View {
        VStack(spacing: 0) {
            formRow(label: loc("Display Name")) {
                TextField(loc("Name"), text: $displayName)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.trailing)
            }
            Divider().padding(.leading, 16)
            formRow(label: loc("Icon Emoji")) {
                HStack(spacing: 8) {
                    TextField(loc("None"), text: $avatarEmoji)
                        .font(.system(size: 20))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 48)
                        .accessibilityIdentifier("editProfileEmojiField")
                    if !avatarEmoji.isEmpty {
                        Button {
                            avatarEmoji = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textTer)
                                .font(.system(size: 16))
                        }
                        .accessibilityIdentifier("editProfileEmojiClearButton")
                    }
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    @ViewBuilder
    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.text)
            content()
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: AppTheme.rowH)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc("Icon Color (when no photo)"))
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSec)
                .padding(.leading, 4)

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 12) {
                ForEach(AvatarView.palette, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(height: 38)
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
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        photoBase64 = resizeAndEncode(image) ?? ""
    }

    private func resizeAndEncode(_ image: UIImage) -> String? {
        let maxSide: CGFloat = 256
        let size = image.size
        let scale = min(maxSide / size.width, maxSide / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.6) else { return nil }
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let updated = try await APIClient.shared.updateProfile(
                    displayName: displayName,
                    avatarEmoji: avatarEmoji,
                    avatarColor: selectedColor,
                    avatarPhoto: photoBase64
                )
                onSave(updated)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
