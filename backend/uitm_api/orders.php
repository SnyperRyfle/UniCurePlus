<?php

require_once __DIR__ . '/api_bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    $pdo = apiDatabase();
    $user = apiRequireSupplier($pdo);

    $statement = $pdo->prepare(
        'SELECT id, po_number, title, agency, quantity, amount, status
         FROM orders
         WHERE company_id = :company_id
         ORDER BY created_at DESC'
    );
    $statement->execute(['company_id' => $user['company_id']]);

    $orders = $statement->fetchAll();

    foreach ($orders as &$order) {
        $order['quantity'] = (int) $order['quantity'];
        $order['amount'] = (float) $order['amount'];
    }
    unset($order);

    echo json_encode(['success' => true, 'data' => $orders]);
} catch (Throwable $error) {
    error_log($error->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Could not load orders']);
}
