<?php
// --- CORS Headers ---
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}
// --- End CORS Headers ---

require_once 'config.php';

// Enable detailed error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

$input = json_decode(file_get_contents('php://input'), true);

$supplier_email = $input['supplier_email'] ?? '';
$supplier_name = $input['supplier_name'] ?? '';
$items = $input['items'] ?? [];
$total = $input['total'] ?? 0;
$payment_status = $input['payment_status'] ?? 'unpaid';
$transaction_id = $input['transaction_id'] ?? '';

if (empty($supplier_email) || empty($items)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields: supplier_email or items.']);
    exit;
}

$items_html = '';
foreach ($items as $item) {
    $items_html .= '<li>' . htmlspecialchars($item['ingredientName']) . ' x ' . $item['quantity'] . ' @ KSh' . number_format($item['unitCost'], 2) . ' each</li>';
}

try {
    $mail = createMailer();

    //Recipients
    $mail->addAddress($supplier_email, $supplier_name);

    //Content
    $mail->isHTML(true);
    if ($payment_status == 'paid') {
        $mail->Subject = 'Purchase Order - Paid';
        $template = file_get_contents('email_templates/purchase_paid.html');
        $template = str_replace('{{SUPPLIER_NAME}}', $supplier_name, $template);
        $template = str_replace('{{ITEMS}}', $items_html, $template);
        $template = str_replace('{{TOTAL}}', number_format($total, 2), $template);
        $template = str_replace('{{TRANSACTION_ID}}', $transaction_id, $template);
    } else {
        $mail->Subject = 'Purchase Order';
        $template = file_get_contents('email_templates/purchase_unpaid.html');
        $template = str_replace('{{SUPPLIER_NAME}}', $supplier_name, $template);
        $template = str_replace('{{ITEMS}}', $items_html, $template);
        $template = str_replace('{{TOTAL}}', number_format($total, 2), $template);
    }
    $mail->Body = $template;

    $mail->send();
    echo json_encode(['success' => true, 'message' => 'Email sent successfully.']);
} catch (Throwable $e) { // Catch all errors, not just Exceptions
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => "Email script error: " . $e->getMessage() . " on line " . $e->getLine()]);
}
?>
