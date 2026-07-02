<?php

$parts = ['0', '9', '6']; // Example version parts
$iterations = 10000000;

// Baseline
$start = microtime(true);
for ($j = 0; $j < $iterations; $j++) {
    $iVersion = 0;
    for($i = 0; $i<count($parts); $i++) {
        $iVersion = ($iVersion<<8) + $parts[$i];
    }
}
$baselineTime = microtime(true) - $start;

// Optimized
$start = microtime(true);
for ($j = 0; $j < $iterations; $j++) {
    $iVersion = 0;
    $count = count($parts);
    for($i = 0; $i<$count; $i++) {
        $iVersion = ($iVersion<<8) + $parts[$i];
    }
}
$optimizedTime = microtime(true) - $start;

echo "Baseline time: {$baselineTime} seconds\n";
echo "Optimized time: {$optimizedTime} seconds\n";
echo "Improvement: " . (($baselineTime - $optimizedTime) / $baselineTime * 100) . "%\n";
