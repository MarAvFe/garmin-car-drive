import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

(:test)
function testCardinal(logger as Logger) as Boolean {
    return cardinal(0).equals("N") && cardinal(22).equals("N") && cardinal(23).equals("NE")
        && cardinal(90).equals("E") && cardinal(337).equals("NW") && cardinal(338).equals("N");
}

(:test)
function testFmtTime(logger as Logger) as Boolean {
    return fmtTime(0).equals("0:00:00") && fmtTime(3725).equals("1:02:05");
}

(:test)
function testRouteFix(logger as Logger) as Boolean {
    // Route due east along the equator, 0.001 rad (~6371 m); position halfway, 0.0001 rad (~637 m) north
    var lat = [0.0, 0.0];
    var lon = [0.0, 0.001];
    var fix = routeFix(0.0001, 0.0005, lat, lon, [0.0, segLen(0.0, 0.0, 0.0, 0.001)]);
    logger.debug(fix.toString());
    return (fix[0] - 637.1).abs() < 1 && (fix[1] - 3185.5).abs() < 1;
}
