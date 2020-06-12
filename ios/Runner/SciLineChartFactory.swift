import Foundation

public class SciLineChartFactory : NSObject, FlutterPlatformViewFactory {
    let controller: FlutterViewController
    
    init(controller: FlutterViewController) {
        self.controller = controller
    }
    
    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let channel = FlutterMethodChannel(
            name: "webview" + String(viewId),
            binaryMessenger: controller.binaryMessenger
        )
        return SciLineChartView(frame, viewId: viewId, channel: channel, args: args)
    }
}
