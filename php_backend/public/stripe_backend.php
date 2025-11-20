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
require_once 'secrets.php';

error_reporting(0);
header('Content-Type: application/json');

\Stripe\Stripe::setApiKey(STRIPE_SECRET_KEY);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['checkout'])) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // The 'total' from the app is in shillings. Convert to cents for Stripe.
    $amount_in_shillings = $input['total'] ?? 0;
    $amount_in_cents = (int)($amount_in_shillings * 100);

    $currency = $input['currency'] ?? 'kes';
    $receipt_id = $input['receipt_id'] ?? null;

    // Stripe's minimum for KES is 50.00
    if ($amount_in_cents < 5000) {
        echo json_encode(['success' => false, 'error' => 'The total amount must be at least KSh 50.00.']);
        exit;
    }

    if (empty($receipt_id)) {
        echo json_encode(['success' => false, 'error' => 'Receipt ID is required.']);
        exit;
    }

    $success_url = 'http://localhost:8000/success.html?session_id={CHECKOUT_SESSION_ID}';
    $cancel_url = 'http://localhost:8000/cancel.html';

    try {
        $session = \Stripe\Checkout\Session::create([
            'payment_method_types' => ['card'],
            'line_items' => [[
                'price_data' => [
                    'currency' => $currency,
                    'product_data' => [
                        'name' => 'Supplier Ingredient Purchase',
                    ],
                    'unit_amount' => $amount_in_cents, // Use the corrected amount in cents
                ],
                'quantity' => 1,
            ]],
            'mode' => 'payment',
            'success_url' => $success_url,
            'cancel_url' => $cancel_url,
            'metadata' => [
                'receipt_id' => $receipt_id,
            ],
        ]);
        echo json_encode([
            'success' => true,
            'checkoutUrl' => $session->url,
            'stripeId' => $session->id
        ]);
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ]);
    }
    exit;
}

// This block for creating a PaymentIntent is likely for mobile and can be kept if needed.
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !isset($_GET['checkout']) && !isset($_GET['record_payment'])) {
    $input = json_decode(file_get_contents('php://input'), true);
    $amount = $input['amount'] ?? 1000;
    $currency = $input['currency'] ?? 'kes';
    try {
        $paymentIntent = \Stripe\PaymentIntent::create([
            'amount' => $amount,
            'currency' => $currency,
            'payment_method_types' => ['card'],
        ]);
        echo json_encode([
            'success' => true,
            'clientSecret' => $paymentIntent->client_secret,
            'stripeId' => $paymentIntent->id
        ]);
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => $e->getMessage()
        ]);
    }
    exit;
}

// This block is likely no longer needed as confirmation is handled by confirm_payment.php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_GET['record_payment'])) {
    echo json_encode(['success' => true, 'message' => 'This endpoint is disabled.']);
    exit;
}
?>
