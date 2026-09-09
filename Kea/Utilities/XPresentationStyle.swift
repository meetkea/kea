import Foundation

enum XPresentationStyle {
    private static let styleIdentifier = "kea-x-presentation-style"
    private static let hiddenClassName = "kea-hide-x-sidebar"

    static func script(hideRightSidebar: Bool) -> String {
        """
        (() => {
          const root = document.documentElement;
          if (!root) return;

          let style = document.getElementById('\(styleIdentifier)');
          if (!style) {
            style = document.createElement('style');
            style.id = '\(styleIdentifier)';
            style.textContent = `
              html.\(hiddenClassName) [data-testid="sidebarColumn"] {
                display: none !important;
              }
              html.\(hiddenClassName) [data-testid="primaryColumn"] {
                width: auto !important;
                max-width: none !important;
                min-width: 0 !important;
                flex: 1 1 auto !important;
              }
            `;
            root.appendChild(style);
          }

          root.classList.toggle('\(hiddenClassName)', \(hideRightSidebar ? "true" : "false"));
        })();
        """
    }
}
