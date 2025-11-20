<?php
// --- CORS Headers ---
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}
// --- End CORS Headers ---

require 'vendor/autoload.php';
require_once 'vendor/google/cloud-firestore/src/FirestoreClient.php';
require_once 'secrets.php';

use Google\Cloud\Firestore\FirestoreClient;

header('Content-Type: application/json');

\Stripe\Stripe::setApiKey(STRIPE_SECRET_KEY);

$session_id = $_GET['session_id'] ?? null;

if (empty($session_id)) {
    echo json_encode(['success' => false, 'message' => 'Session ID is required.']);
    exit;
}

try {
    // Retrieve the session from Stripe
    $session = \Stripe\Checkout\Session::retrieve($session_id);

    // Get the receipt ID from metadata
    $receipt_id = $session->metadata->receipt_id ?? null;

    if (empty($receipt_id)) {
        throw new Exception('Receipt ID not found in session metadata.');
    }

    // Initialize Firestore
    $firestore = new FirestoreClient([
        'projectId' => 'supplychain-e8b13',
    ]);

    $receiptRef = $firestore->collection('supplier_receipts')->document($receipt_id);

    // Update the receipt in Firestore
    $receiptRef->update([
        ['path' => 'paymentStatus', 'value' => 'paid'],
        ['path' => 'transactionId', 'value' => $session->payment_intent],
    ]);

    // Optionally, you could re-send a "paid" email here if needed

    echo json_encode(['success' => true, 'message' => 'Payment confirmed and receipt updated.']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
