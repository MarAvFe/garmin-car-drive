import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

(:test)
function testVmg(logger as Logger) as Boolean {
    var head = velocityMadeGood(5.0, 0.0, 0.0);                  // heading straight at it
    var beam = velocityMadeGood(5.0, 0.0, Math.PI / 2);          // 90 deg off
    var away = velocityMadeGood(5.0, 0.0, Math.PI);              // opposite
    return (head - 5).abs() < 0.001 && beam.abs() < 0.001 && (away + 5).abs() < 0.001;
}

(:test)
function testFmt(logger as Logger) as Boolean {
    return fmt(null, KN).equals("--") && fmt(1852.0, 1 / NM).equals("1.0") && fmt(5.144, KN).equals("10.0");
}
