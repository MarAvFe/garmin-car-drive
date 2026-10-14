import Toybox.Lang;
import Toybox.System;

function metric() as Boolean {
    return System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
}

function fmtSpeed(mps as Float?) as String {
    return mps == null ? "--" : (mps * (metric() ? 3.6 : 2.23694)).format("%d");
}

function speedUnit() as String {
    return metric() ? " km/h" : " mph";
}

function fmtDist(m as Float?) as String {
    return (m == null || !(m > 0) ? 0.0 : m / (metric() ? 1000.0 : 1609.344)).format("%.1f") + (metric() ? " km" : " mi");
}

function fmtAlt(m as Numeric?) as String {
    if (m == null) {
        return "--";
    }
    var ft = System.getDeviceSettings().elevationUnits != System.UNIT_METRIC;
    return (ft ? m * 3.28084 : m).format("%d") + (ft ? " ft" : " m");
}

function fmtTime(s as Number) as String {
    return (s / 3600) + ":" + (s / 60 % 60).format("%02d") + ":" + (s % 60).format("%02d");
}

function cardinal(deg as Number) as String {
    return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][((deg * 2 + 45) / 90) % 8];
}
