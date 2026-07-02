<?php

function benchmark_unoptimized($version, $iterations = 10000) {
    $start = microtime(true);
    for ($iter = 0; $iter < $iterations; $iter++) {
        $parts = explode('.', $version);
        $iVersion = 0;
        for ($i = 0; $i < count($parts); $i++) {
            $iVersion = ($iVersion << 8) + (int)$parts[$i];
        }
    }
    $end = microtime(true);
    return $end - $start;
}

function benchmark_optimized($version, $iterations = 10000) {
    $start = microtime(true);
    for ($iter = 0; $iter < $iterations; $iter++) {
        $parts = explode('.', $version);
        $iVersion = 0;
        $countParts = count($parts);
        for ($i = 0; $i < $countParts; $i++) {
            $iVersion = ($iVersion << 8) + (int)$parts[$i];
        }
    }
    $end = microtime(true);
    return $end - $start;
}

$version = "0.9.8"; // Typical rTorrent version string
$iterations = 1000000; // Increased iterations for more accurate measurement

echo "Benchmarking rTorrent version parsing (explode + bitwise shift)...\n";
echo "Version string: '$version'\n";
echo "Iterations: $iterations\n\n";

$unoptimized_time = benchmark_unoptimized($version, $iterations);
echo "Unoptimized time: " . number_format($unoptimized_time, 4) . " seconds\n";

$optimized_time = benchmark_optimized($version, $iterations);
echo "Optimized time: " . number_format($optimized_time, 4) . " seconds\n";

if ($unoptimized_time > 0) {
    $improvement = (($unoptimized_time - $optimized_time) / $unoptimized_time) * 100;
    echo "\nImprovement: " . number_format($improvement, 2) . "%\n";
} else {
    echo "Too fast to measure improvement.\n";
}

?>
