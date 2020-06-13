package com.example.flutterscichartproject;

import androidx.annotation.NonNull;

import com.example.flutterscichartproject.sci.CandleStickFactory;
import com.example.flutterscichartproject.sci.InteractingAnnotationFactory;
import com.example.flutterscichartproject.sci.OHLCFactory;
import com.scichart.charting.visuals.SciChartSurface;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterSciChartPlugin */
public class FlutterSciChartProject implements FlutterPlugin {
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {

    setLicense();

    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "plugins.com.example/ohlc", new OHLCFactory(registrar.messenger()));

    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "SciCandleChart", new CandleStickFactory(registrar.messenger()));

    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "plugins.com.example/interacting_annotation", new InteractingAnnotationFactory(registrar.messenger()));
  }

  private static void setLicense() {
    try {
      SciChartSurface.setRuntimeLicenseKey(LicenseKey.LICENSE_KEY);
    } catch (Exception e) {
      Log.e("SciChart", "Error when setting the license", e);
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }
}
