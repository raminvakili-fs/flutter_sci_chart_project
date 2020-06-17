package com.example.flutterscichartproject;

import android.os.Bundle;
import android.os.PersistableBundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.plugin.platform.PlatformViewsController;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    public void onCreate(@Nullable Bundle savedInstanceState, @Nullable PersistableBundle persistentState) {
        super.onCreate(savedInstanceState, persistentState);

//        FlutterEngine flutterEngine = new FlutterEngine(
//                this,
//                FlutterLoader.getInstance(),
//                new FlutterJNI(),
//                new String[2], // or an empty array if no args needed
//                false // this arg instructs the FlutterEngine NOT to register plugins automatically
//        );
//        flutterEngine.getPlugins().add(new FlutterSciChartProject());
        //FlutterSciChartProject.registerWith(registrarFor("io.flutter.plugins.battery.BatteryPlugin"));

//        GeneratedPluginRegistrant.registerWith(flutterEngine);
//        // Immediately add plugins to the cached FlutterEngine.
//        // The ShimPluginRegistry is how the v2 embedding works with v1 plugins.
//        ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(
//                flutterEngine
//        );
//
//        // Add any v1 plugins to the shim
//         FlutterSciChartProject.registerWith(
//           shimPluginRegistry.registrarFor("SciCandleChart")
//         );
//
//        // Add any v2 plugins that you want
//        // engine.getPlugins().add(new MyPlugin());
//        //FlutterSciChartProject.registerWith(registrarFor("SciCandleChart"));
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine);
        FlutterSciChartProject.registerWith(shimPluginRegistry.registrarFor("SciCandleChart"));
        //GeneratedPluginRegistrant.registerWith(flutterEngine);
        super.configureFlutterEngine(flutterEngine);
    }
}
