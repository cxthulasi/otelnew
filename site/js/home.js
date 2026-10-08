(function () {
  var sdk = window.CoralogixRum;
  if (!sdk) return;
  sdk.addTiming("landing_ready");
  sdk.sendCustomMeasurement("landing_cards", 4);
})();
