<?php

require_once __DIR__ . '/api_bootstrap.php';

if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'], true)) {
    apiRespond(405, ['success' => false, 'message' => 'Method not allowed']);
}

try {
    $pdo = apiDatabase();

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        if (!is_array($input)) {
            apiRespond(400, ['success' => false, 'message' => 'Invalid JSON body']);
        }

        $username = isset($input['username']) && is_string($input['username'])
            ? trim($input['username'])
            : '';
        $password = isset($input['password']) && is_string($input['password'])
            ? $input['password']
            : '';

        if ($username === '' || $password === '') {
            apiRespond(422, ['success' => false, 'message' => 'Username and password are required']);
        }

        $statement = $pdo->prepare(
            'SELECT u.id, u.username, u.password, u.company_id, u.role, c.name AS company_name
             FROM users u
             LEFT JOIN company_profiles c ON c.id = u.company_id
             WHERE u.username = :username
             LIMIT 1'
        );
        $statement->execute(['username' => $username]);
        $user = $statement->fetch();

        $validPassword = false;
        $upgradePassword = false;
        if ($user) {
            $validPassword = password_verify($password, $user['password']);
            if (!$validPassword && hash_equals((string) $user['password'], $password)) {
                // Upgrade the plaintext demo seed the first time its account logs in.
                $validPassword = true;
                $upgradePassword = true;
            } elseif ($validPassword && password_needs_rehash($user['password'], PASSWORD_DEFAULT)) {
                $upgradePassword = true;
            }
        }

        if (!$user || !$validPassword) {
            apiRespond(401, ['success' => false, 'message' => 'Invalid username or password']);
        }

        if ($user['role'] !== 'supplier' || $user['company_id'] === null) {
            apiRespond(403, ['success' => false, 'message' => 'Supplier access required']);
        }

        if ($upgradePassword) {
            $passwordHash = password_hash($password, PASSWORD_DEFAULT);
            if ($passwordHash === false) {
                throw new RuntimeException('Could not hash user password');
            }
            $upgrade = $pdo->prepare('UPDATE users SET password = :password WHERE id = :id');
            $upgrade->execute(['password' => $passwordHash, 'id' => $user['id']]);
        }

        $pdo->prepare('DELETE FROM api_tokens WHERE expires_at <= NOW()')->execute();

        $token = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $token);
        $insert = $pdo->prepare(
            'INSERT INTO api_tokens (token_hash, user_id, expires_at)
             VALUES (:token_hash, :user_id, DATE_ADD(NOW(), INTERVAL 12 HOUR))'
        );
        $insert->execute([
            'token_hash' => $tokenHash,
            'user_id' => $user['id'],
        ]);

        echo json_encode([
            'success' => true,
            'data' => [
                'token' => $token,
                'expires_in' => 43200,
                'user' => [
                    'id' => (int) $user['id'],
                    'username' => $user['username'],
                    'role' => $user['role'],
                    'company_id' => (int) $user['company_id'],
                    'company_name' => $user['company_name'],
                ],
            ],
        ]);
        exit;
    }

    $user = apiRequireSupplier($pdo);
    $delete = $pdo->prepare(
        'DELETE FROM api_tokens WHERE token_hash = :token_hash AND user_id = :user_id'
    );
    $delete->execute([
        'token_hash' => $user['token_hash'],
        'user_id' => $user['id'],
    ]);

    echo json_encode(['success' => true]);
} catch (Throwable $error) {
    error_log($error->getMessage());
    apiRespond(500, ['success' => false, 'message' => 'Authentication request failed']);
}
