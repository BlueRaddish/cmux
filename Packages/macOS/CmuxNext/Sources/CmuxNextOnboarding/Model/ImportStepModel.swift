public import CmuxNextBrowserImport
import Foundation
public import Observation

/// Import step: detect browsers, pick profiles and kinds, run the import
/// (cancellable, off the main thread), then show counts and extensions.
@MainActor
@Observable
public final class ImportStepModel {
    public enum Phase: Equatable {
        case idle
        case detecting
        case ready
        case importing(ImportProgress?)
        case finished(ImportSummary)
        case cancelled
        case failed(String)
    }

    public private(set) var phase: Phase = .idle
    public private(set) var sources: [BrowserSource] = []
    /// Selected profile ids (`BrowserSourceProfile.id`).
    public private(set) var selectedProfiles: Set<String> = []
    /// Kinds to import from every selected profile, unless the profile has its own.
    public private(set) var kinds: Set<ImportDataKind> = [.bookmarks, .history, .openTabs, .extensions, .cookies]
    /// Per-profile choices that differ from `kinds`.
    public private(set) var profileKinds: [String: Set<ImportDataKind>] = [:]
    /// True: every source goes into one cmux profile (the default one);
    /// false: each source profile becomes its own cmux browser profile.
    public private(set) var mergeIntoOne = false
    /// Extensions the one-step install has seen installed.
    public private(set) var installedExtensions: Set<String> = []
    public private(set) var installingAll = false
    /// Extensions whose store page was opened from the summary.
    public private(set) var installRequested: Set<String> = []
    public private(set) var tabsOpened = false
    @ObservationIgnored private let services: any OnboardingServices
    @ObservationIgnored private var task: Task<Void, Never>?

    /// Kinds offered as toggles (passwords show why they are off).
    public static let offeredKinds: [ImportDataKind] = [.bookmarks, .history, .openTabs, .cookies, .extensions]

    init(services: any OnboardingServices) {
        self.services = services
    }

    public var browserProfilesAvailable: Bool { services.browserProfilesAvailable }

    /// Detects once; again after `redetect()` (for example after granting Full Disk Access).
    public func detect() {
        guard phase == .idle else { return }
        redetect()
    }

    public func redetect() {
        task?.cancel()
        phase = .detecting
        task = Task { [weak self, services] in
            let found = await services.detectBrowsers()
            guard let self, !Task.isCancelled else { return }
            sources = found
            let known = Set(found.flatMap(\.profiles).map(\.id))
            selectedProfiles = selectedProfiles.intersection(known)
            if selectedProfiles.isEmpty, let first = found.flatMap(\.profiles).first(where: { !$0.importableKinds.isEmpty }) {
                selectedProfiles = [first.id]
            }
            phase = .ready
        }
    }

    public func isSelected(_ profile: BrowserSourceProfile) -> Bool { selectedProfiles.contains(profile.id) }

    public func toggle(_ profile: BrowserSourceProfile) {
        guard canEditSelection, !profile.importableKinds.isEmpty else { return }
        if selectedProfiles.remove(profile.id) == nil { selectedProfiles.insert(profile.id) }
    }

    public func toggle(_ kind: ImportDataKind) {
        guard canEditSelection, Self.offeredKinds.contains(kind) else { return }
        if kinds.remove(kind) == nil { kinds.insert(kind) }
        profileKinds = [:]
    }

    /// The kinds that will be imported from `profile` (offered and available).
    public func kinds(for profile: BrowserSourceProfile) -> Set<ImportDataKind> {
        (profileKinds[profile.id] ?? kinds).filter { profile.availability(of: $0).isImportable }
    }

    /// Turns one kind on or off for one profile only.
    public func toggle(_ kind: ImportDataKind, for profile: BrowserSourceProfile) {
        guard canEditSelection, profile.availability(of: kind).isImportable else { return }
        var set = profileKinds[profile.id] ?? kinds
        if set.remove(kind) == nil { set.insert(kind) }
        profileKinds[profile.id] = set
    }

    public func setMergeIntoOne(_ value: Bool) {
        guard canEditSelection else { return }
        mergeIntoOne = value
    }

    public var canEditSelection: Bool {
        switch phase {
        case .ready, .cancelled, .failed, .finished: true
        default: false
        }
    }

    public var plan: ImportPlan {
        let profiles = sources.flatMap(\.profiles).filter { selectedProfiles.contains($0.id) }
        return ImportPlan(items: profiles.map { ImportPlan.Item(profile: $0, kinds: kinds(for: $0)) },
                          mergeTarget: mergeIntoOne ? ImportPlan.defaultProfileID : nil)
    }

    public var canStart: Bool { canEditSelection && !plan.items.isEmpty }

    public var isImporting: Bool {
        if case .importing = phase { return true }
        return false
    }

    public func start() {
        guard canStart else { return }
        let plan = plan
        phase = .importing(nil)
        task = Task { [weak self, services] in
            do {
                let summary = try await services.runImport(plan) { progress in
                    guard let self, case .importing = self.phase else { return }
                    self.phase = .importing(progress)
                }
                self?.phase = .finished(summary)
            } catch is CancellationError {
                self?.phase = .cancelled
            } catch {
                self?.phase = .failed(error.localizedDescription)
            }
        }
    }

    /// Back from a summary (or a stop) to the choices, to import more.
    public func reset() {
        switch phase {
        case .finished, .cancelled, .failed:
            phase = .ready
            tabsOpened = false
            installRequested = []
            installingAll = false
        default:
            return
        }
    }

    public func cancel() {
        guard let task else { return }
        task.cancel()
        self.task = nil
        if case .importing = phase { phase = .cancelled }
        if phase == .detecting { phase = .idle }
    }

    public func install(_ item: ImportedExtension) {
        installRequested.insert(item.id)
        services.installExtension(item)
    }

    /// Installs every imported extension in one step: the store pages open
    /// in background Chromium tabs of each extension's target profile, and
    /// the list fills in as Chromium reports installs.
    public func installAllExtensions() {
        guard case .finished(let summary) = phase, !installingAll else { return }
        installingAll = true
        for batch in summary.batches where !batch.extensions.isEmpty {
            let pending = batch.extensions.filter { !installedExtensions.contains($0.id) }
            installRequested.formUnion(pending.map(\.id))
            services.installExtensions(pending, profileID: batch.source.targetProfileID) { [weak self] installed in
                self?.installedExtensions.formUnion(installed)
            }
        }
    }

    public func openImportedTabs() {
        guard case .finished(let summary) = phase, !summary.openTabs.isEmpty, !tabsOpened else { return }
        tabsOpened = true
        services.openTabs(summary.openTabs)
    }

    public func openFullDiskAccessSettings() {
        services.openExternal(SystemSettingsLink.fullDiskAccess)
    }
}
