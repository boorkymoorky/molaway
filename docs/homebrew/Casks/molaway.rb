cask "molaway" do
  version "2.2.5"
  sha256 "f1430159bdc05ebf141cd6ff583412784b572a0766c90b61254cb942f8bd5882"

  url "https://github.com/boorkymoorky/molaway/releases/download/v#{version}/Molaway-#{version}-macOS-arm64.zip"
  name "Molaway"
  desc "Local menu bar reminder for eye and movement breaks"
  homepage "https://github.com/boorkymoorky/molaway"

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Molaway.app"

  caveats <<~EOS
    Molaway is ad hoc signed and not notarized. Keep Gatekeeper enabled.
    Review the per-app first-launch instructions before opening:
      https://github.com/boorkymoorky/molaway/blob/main/docs/INSTALL.md#first-launch-and-macos-security
    Updates are manual. Removing the app preserves local settings and summaries.
  EOS
end
