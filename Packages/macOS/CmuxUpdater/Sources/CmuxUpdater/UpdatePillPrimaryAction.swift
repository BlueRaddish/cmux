/// The action a plain click on the update pill performs (see
/// ``UpdateStateModel/pillPrimaryAction``).
public enum UpdatePillPrimaryAction: Equatable, Sendable {
    /// Resolve the newest update, then download, install, and relaunch without another prompt.
    case installLatest
    /// Relaunch into the update Sparkle already staged.
    case restart
    /// Dismiss the "No Updates Available" result.
    case acknowledgeNotFound
    /// Show or hide the details popover.
    case togglePopover
}
