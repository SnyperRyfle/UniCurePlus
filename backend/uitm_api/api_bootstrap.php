<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *'); // Local development only
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function apiRespond(int $status, array $body): void
{
    http_response_code($status);
    echo json_encode($body);
    exit;
}

function apiDatabase(): PDO
{
    return new PDO(
        'mysql:host=127.0.0.1;port=3307;dbname=uitm_intern_db;charset=utf8mb4',
        'root',
        '',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
}

function apiRequireSupplier(PDO $pdo): array
{
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authorization = $_SERVER['HTTP_AUTHORIZATION']
        ?? $headers['Authorization']
        ?? $headers['authorization']
        ?? '';

    if (!preg_match('/^Bearer ([a-f0-9]{64})$/i', trim($authorization), $matches)) {
        apiRespond(401, ['success' => false, 'message' => 'Authentication required']);
    }

    $tokenHash = hash('sha256', $matches[1]);
    $statement = $pdo->prepare(
        'SELECT u.id, u.username, u.company_id, u.role, t.token_hash
         FROM api_tokens t
         INNER JOIN users u ON u.id = t.user_id
         WHERE t.token_hash = :token_hash AND t.expires_at > NOW()
         LIMIT 1'
    );
    $statement->execute(['token_hash' => $tokenHash]);
    $user = $statement->fetch();

    if (!$user) {
        apiRespond(401, ['success' => false, 'message' => 'Session expired; please log in again']);
    }

    if ($user['role'] !== 'supplier' || $user['company_id'] === null) {
        apiRespond(403, ['success' => false, 'message' => 'Supplier access required']);
    }

    $user['company_id'] = (int) $user['company_id'];
    return $user;
}
