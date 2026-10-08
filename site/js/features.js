(function () {
  var sdk = window.CoralogixRum;
  if (!sdk) return;
  sdk.setLabels({ site: "otelnew.com", page: "features" });
  sdk.addTiming("features_ready");
  sdk.sendCustomMeasurement("feature_groups", 4);
})();
