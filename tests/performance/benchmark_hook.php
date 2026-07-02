<?php

class Settings {
    public $hooks = [];
    public function register($plugin, $ename) {
        $this->hooks[$ename][] = $plugin;
    }

    public function unregisterBaseline($plugin, $ename) {
        if( array_key_exists($ename, $this->hooks) )
        {
            for( $i = 0; $i<count($this->hooks[$ename]); $i++ )
            {
                if($this->hooks[$ename][$i] == $plugin)
                {
                    unset($this->hooks[$ename][$i]);
                    if( empty($this->hooks[$ename]) )
                    {
                        unset($this->hooks[$ename]);
                    }
                    break;
                }
            }
        }
    }

    public function unregisterOptimized($plugin, $ename) {
        if( array_key_exists($ename, $this->hooks) )
        {
            $count = count($this->hooks[$ename]);
            for( $i = 0; $i < $count; $i++ )
            {
                if($this->hooks[$ename][$i] == $plugin)
                {
                    unset($this->hooks[$ename][$i]);
                    if( empty($this->hooks[$ename]) )
                    {
                        unset($this->hooks[$ename]);
                    }
                    break;
                }
            }
        }
    }
}

$runs = 100000;
$elements = 100;

// Baseline
$start = microtime(true);
for ($r = 0; $r < $runs; $r++) {
    $s = new Settings();
    for ($i = 0; $i < $elements; $i++) {
        $s->register("plugin_".$i, "event1");
    }
    // worst case: not found or last element
    $s->unregisterBaseline("plugin_not_found", "event1");
}
$end = microtime(true);
$baseline = $end - $start;

// Optimized
$start = microtime(true);
for ($r = 0; $r < $runs; $r++) {
    $s = new Settings();
    for ($i = 0; $i < $elements; $i++) {
        $s->register("plugin_".$i, "event1");
    }
    // worst case: not found or last element
    $s->unregisterOptimized("plugin_not_found", "event1");
}
$end = microtime(true);
$optimized = $end - $start;

echo "Baseline: " . $baseline . " seconds\n";
echo "Optimized: " . $optimized . " seconds\n";
echo "Improvement: " . (($baseline - $optimized) / $baseline * 100) . "%\n";
