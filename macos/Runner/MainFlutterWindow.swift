import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    let resizedFrame = NSRect(
      x: windowFrame.origin.x,
      y: windowFrame.origin.y + (windowFrame.height * 0.5),
      width: windowFrame.width * 0.5,
      height: windowFrame.height * 0.5
    )
    self.contentViewController = flutterViewController
    self.setFrame(resizedFrame, display: true)
    self.level = .floating

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
