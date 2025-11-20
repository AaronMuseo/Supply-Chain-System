<?php
require 'vendor/autoload.php';

use Google\Cloud\Firestore\FirestoreClient;
use Google\Cloud\Firestore\FieldValue;

// --- Configuration ---
$projectId = ''; // Your Google Cloud Project ID

// --- Initialize Firestore ---
try {
    $firestore = new FirestoreClient(['projectId' => $projectId]);
    echo "Successfully connected to Firestore." . PHP_EOL;
} catch (Exception $e) {
    die('Failed to connect to Firestore: ' . $e->getMessage());
}

// --- WARNING: Safety Check ---
// The function below will DELETE all data in the specified collections.
// It is commented out by default for safety. Uncomment to enable a full reset.
/*
function clearCollections($firestore, $collections) {
    foreach ($collections as $collectionName) {
        echo "Clearing collection: $collectionName..." . PHP_EOL;
        $documents = $firestore->collection($collectionName)->documents();
        foreach ($documents as $document) {
            $document->reference()->delete();
        }
        echo "$collectionName cleared." . PHP_EOL;
    }
}
// Call the function if you want to clear data before adding more.
// clearCollections($firestore, ['ingredients', 'suppliers', 'menu_items']);
*/


// --- Data Seeding Functions ---

/**
 * Adds ingredients and returns an associative array mapping a key name to its Firestore ID.
 */
function addIngredients($firestore): array
{
    echo "Adding ingredients..." . PHP_EOL;
    $ingredients = [
        'sukuma' => ['name' => 'Sukuma Wiki (Kales)', 'inventoryLevel' => 100],
        'tomatoes' => ['name' => 'Tomatoes', 'inventoryLevel' => 200],
        'onions' => ['name' => 'Onions', 'inventoryLevel' => 150],
        'dhania' => ['name' => 'Dhania (Coriander)', 'inventoryLevel' => 50],
        'beef' => ['name' => 'Nyama (Beef)', 'inventoryLevel' => 50],
        'unga' => ['name' => 'Unga (Maize Flour)', 'inventoryLevel' => 80],
        'cabbage' => ['name' => 'Cabbage', 'inventoryLevel' => 40],
    ];

    $ingredientIds = [];
    foreach ($ingredients as $key => $data) {
        $docRef = $firestore->collection('ingredients')->add($data);
        $ingredientIds[$key] = $docRef->id();
    }
    echo "Finished adding ingredients." . PHP_EOL;
    return $ingredientIds;
}

/**
 * Adds suppliers and links them to the ingredients they supply.
 */
function addSuppliers($firestore, array $ingredientIds)
{
    echo "Adding suppliers..." . PHP_EOL;
    $suppliers = [
        [
            'name' => 'Nairobi Fresh Veggies',
            'contactPerson' => 'Jane Wanjiku',
            'phone' => '0712345678',
            'address' => 'City Market, Nairobi',
            'email' => 'jane@nairofresh.co.ke',
            'bankAccount' => '1122334455',
            'ingredientsSupplied' => [$ingredientIds['sukuma'], $ingredientIds['tomatoes'], $ingredientIds['onions'], $ingredientIds['dhania'], $ingredientIds['cabbage']],
            'ingredientPrices' => [
                $ingredientIds['sukuma'] => 50.00,
                $ingredientIds['tomatoes'] => 120.00,
                $ingredientIds['onions'] => 100.00,
                $ingredientIds['dhania'] => 20.00,
                $ingredientIds['cabbage'] => 80.00,
            ],
        ],
        [
            'name' => 'Kenya Meat Masters',
            'contactPerson' => 'David Omondi',
            'phone' => '0722334455',
            'address' => 'Buru Buru, Nairobi',
            'email' => 'david@meatmasters.co.ke',
            'bankAccount' => '6677889900',
            'ingredientsSupplied' => [$ingredientIds['beef']],
            'ingredientPrices' => [
                $ingredientIds['beef'] => 550.00,
            ],
        ],
        [
            'name' => 'Unga Millers Ltd',
            'contactPerson' => 'Peter Kimani',
            'phone' => '0733445566',
            'address' => 'Industrial Area, Nairobi',
            'email' => 'peter@ungamillers.co.ke',
            'bankAccount' => '1234567890',
            'ingredientsSupplied' => [$ingredientIds['unga']],
            'ingredientPrices' => [
                $ingredientIds['unga'] => 150.00,
            ],
        ],
    ];

    foreach ($suppliers as $supplier) {
        $firestore->collection('suppliers')->add($supplier);
    }
    echo "Finished adding suppliers." . PHP_EOL;
}

/**
 * Adds menu items and defines their recipes using existing ingredients.
 */
function addMenuItems($firestore, array $ingredientIds)
{
    echo "Adding menu items..." . PHP_EOL;
    $menuItems = [
        [
            'name' => 'Nyama Choma (1/2 Kg) with Ugali & Sukuma',
            'price' => 750.00,
            'ingredients' => [
                ['ingredientId' => $ingredientIds['beef'], 'ingredientName' => 'Nyama (Beef)', 'quantity' => 1],
                ['ingredientId' => $ingredientIds['unga'], 'ingredientName' => 'Unga (Maize Flour)', 'quantity' => 1],
                ['ingredientId' => $ingredientIds['sukuma'], 'ingredientName' => 'Sukuma Wiki (Kales)', 'quantity' => 1],
            ],
        ],
        [
            'name' => 'Kachumbari Side Salad',
            'price' => 100.00,
            'ingredients' => [
                ['ingredientId' => $ingredientIds['tomatoes'], 'ingredientName' => 'Tomatoes', 'quantity' => 1],
                ['ingredientId' => $ingredientIds['onions'], 'ingredientName' => 'Onions', 'quantity' => 1],
                ['ingredientId' => $ingredientIds['dhania'], 'ingredientName' => 'Dhania (Coriander)', 'quantity' => 1],
            ],
        ],
        [
            'name' => 'Plain Ugali',
            'price' => 80.00,
            'ingredients' => [
                ['ingredientId' => $ingredientIds['unga'], 'ingredientName' => 'Unga (Maize Flour)', 'quantity' => 1],
            ],
        ],
    ];

    foreach ($menuItems as $item) {
        $firestore->collection('menu_items')->add($item);
    }
    echo "Finished adding menu items." . PHP_EOL;
}


// --- Main Execution ---
echo "Starting to seed database..." . PHP_EOL;

$ingredientIds = addIngredients($firestore);
addSuppliers($firestore, $ingredientIds);
addMenuItems($firestore, $ingredientIds);

echo "Database seeding complete!" . PHP_EOL;

?>
