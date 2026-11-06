<?php
// Genera config.inc.php desde la plantilla oficial usando variables de entorno.
// Solo corre en el primer arranque; despues manda el archivo del volumen.

function required(string $name): string
{
    $value = getenv($name);
    if ($value === false || $value === '') {
        fwrite(STDERR, "Falta la variable de entorno {$name}\n");
        exit(1);
    }
    return $value;
}

$baseUrl = rtrim(required('OJS_BASE_URL'), '/');
$host = parse_url($baseUrl, PHP_URL_HOST);
if (!$host) {
    fwrite(STDERR, "OJS_BASE_URL no es una URL valida: {$baseUrl}\n");
    exit(1);
}

// section => [key => valor ya formateado para el .ini]
$quote = function (string $value): string {
    if (str_contains($value, '"')) {
        fwrite(STDERR, "Los valores de configuracion no pueden contener comillas dobles\n");
        exit(1);
    }
    return '"' . $value . '"';
};
$settings = [
    'general' => [
        'base_url' => $quote($baseUrl),
        'allowed_hosts' => "'" . json_encode([$host]) . "'",
        'trust_x_forwarded_for' => getenv('OJS_BEHIND_PROXY') === 'true' ? 'On' : 'Off',
    ],
    'database' => [
        'host' => $quote(required('OJS_DB_HOST')),
        'username' => $quote(required('OJS_DB_USER')),
        'password' => $quote(required('OJS_DB_PASSWORD')),
        'name' => $quote(required('OJS_DB_NAME')),
    ],
    'files' => [
        'files_dir' => $quote('/var/www/files'),
    ],
    'security' => [
        'salt' => $quote(bin2hex(random_bytes(32))),
        'api_key_secret' => $quote(bin2hex(random_bytes(32))),
    ],
];

[, $template, $target] = $argv;
$section = null;
$pending = $settings;
$lines = [];
foreach (file($template) as $line) {
    if (preg_match('/^\[([^\]]+)\]/', $line, $m)) {
        $section = $m[1];
    } elseif (preg_match('/^([a-z_]+)\s*=/', $line, $m) && isset($settings[$section][$m[1]])) {
        $line = "{$m[1]} = {$settings[$section][$m[1]]}\n";
        unset($pending[$section][$m[1]]);
    }
    $lines[] = $line;
}

$missing = array_filter($pending);
if ($missing) {
    fwrite(STDERR, 'Claves no encontradas en la plantilla: ' . json_encode($missing) . "\n");
    exit(1);
}

file_put_contents($target, implode('', $lines));
echo "Generado {$target}\n";
