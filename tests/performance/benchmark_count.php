<?php

$runs = 100000;
$arr = array_fill(0, 100, "foo");

$start = microtime(true);
for ($r = 0; $r < $runs; $r++) {
    for ($i = 0; $i < count($arr); $i++) {
        // do nothing
    }
}
$end = microtime(true);
$baseline = $end - $start;

$start = microtime(true);
for ($r = 0; $r < $runs; $r++) {
    $count = count($arr);
    for ($i = 0; $i < $count; $i++) {
        // do nothing
    }
}
$end = microtime(true);
$optimized = $end - $start;

echo "Baseline: " . $baseline . " seconds\n";
echo "Optimized: " . $optimized . " seconds\n";
echo "Improvement: " . (($baseline - $optimized) / $baseline * 100) . "%\n";
