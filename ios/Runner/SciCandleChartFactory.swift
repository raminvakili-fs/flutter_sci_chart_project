import Foundation

public class SciCandleChartFactory : NSObject, FlutterPlatformViewFactory {
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
            name: "SciCandleChart" + String(viewId),
            binaryMessenger: controller.binaryMessenger
        )
        return SciCandleChartView(frame, viewId: viewId, channel: channel, args: args)
    }
}
