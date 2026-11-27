<?php

require_once __DIR__ . '/api_bootstrap.php';

if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST'], true)) {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    $pdo = apiDatabase();
    $user = apiRequireSupplier($pdo);

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $statement = $pdo->prepare(
            "SELECT i.id, i.invoice_no, o.po_number AS order_ref,
                    DATE_FORMAT(i.date, '%Y-%m-%d') AS date,
                    i.amount, i.status
             FROM invoices i
             INNER JOIN orders o ON o.id = i.order_ref
             WHERE o.company_id = :company_id
             ORDER BY i.created_at DESC"
        );
        $statement->execute(['company_id' => $user['company_id']]);
        $invoices = $statement->fetchAll();

        foreach ($invoices as &$invoice) {
            $invoice['amount'] = (float) $invoice['amount'];
        }
        unset($invoice);

        echo json_encode(['success' => true, 'data' => $invoices]);
        exit;
    }

    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON body']);
        exit;
    }

    $invoiceNo = trim($input['invoice_no'] ?? '');
    $orderId = trim($input['order_id'] ?? '');
    $invoiceDate = trim($input['date'] ?? '');
    $amount = $input['amount'] ?? null;

    if ($invoiceNo === '' || strlen($invoiceNo) > 50) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid invoice number']);
        exit;
    }

    $date = DateTime::createFromFormat('!Y-m-d', $invoiceDate);
    if (!$date || $date->format('Y-m-d') !== $invoiceDate) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Date must use YYYY-MM-DD']);
        exit;
    }

    if (!is_numeric($amount) || !is_finite((float) $amount) || (float) $amount <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Amount must be greater than zero']);
        exit;
    }

    $orderQuery = $pdo->prepare(
        'SELECT id, po_number, amount
         FROM orders
         WHERE id = :order_id AND company_id = :company_id'
    );
    $orderQuery->execute([
        'order_id' => $orderId,
        'company_id' => $user['company_id'],
    ]);
    $order = $orderQuery->fetch();

    if (!$order) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Order not found']);
        exit;
    }

    if ((float) $amount > (float) $order['amount']) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invoice amount exceeds order amount']);
        exit;
    }

    $invoiceId = 'API-' . bin2hex(random_bytes(12));

    $insert = $pdo->prepare(
        'INSERT INTO invoices (id, invoice_no, order_ref, date, amount, status)
         VALUES (:id, :invoice_no, :order_ref, :date, :amount, :status)'
    );
    $insert->execute([
        'id' => $invoiceId,
        'invoice_no' => $invoiceNo,
        'order_ref' => $order['id'],
        'date' => $invoiceDate,
        'amount' => (float) $amount,
        'status' => 'Dihantar',
    ]);

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'data' => [
            'id' => $invoiceId,
            'invoice_no' => $invoiceNo,
            'order_ref' => $order['po_number'],
            'date' => $invoiceDate,
            'amount' => (float) $amount,
            'status' => 'Dihantar',
        ],
    ]);
} catch (PDOException $error) {
    error_log($error->getMessage());

    if ($error->getCode() === '23000') {
        http_response_code(409);
        echo json_encode(['success' => false, 'message' => 'Invoice number already exists']);
        exit;
    }

    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database request failed']);
} catch (Throwable $error) {
    error_log($error->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Could not create invoice']);
}
