# UniCurePlus

UniCurePlus is a Flutter prototype of a UiTM eProcurement mobile application for suppliers. It provides supplier authentication and screens for invitations, tender submissions, purchase orders, invoices, notifications, and company profiles.

The Flutter client is written in Bahasa Melayu and is designed for Android, iOS, web, Windows, and other supported Flutter targets. The prototype includes a PHP and MySQL backend for authentication and supplier data.

## Features

- Supplier login and bearer-token logout
- Dashboard with recent invitations and purchase orders
- Invitation and tender views
- Tender creation workflow
- Purchase order list, details, acceptance, and delivery status
- Invoice list, creation, and status views
- Supplier profile and notification screens
- API-backed authentication, orders, and invoices

## Technology

- Flutter 3.10 or newer
- Dart 3
- GoRouter for navigation
- HTTP package for API communication
- PHP
- MySQL/MariaDB
- Material 3

## Project Structure

```text
lib/
  data/          Static prototype data
  models/        Application models
  router/        GoRouter route configuration
  screens/       Login, dashboard, tender, order, invoice, and profile screens
  services/      Authentication and REST API services
  theme/         Application colours and theme
  widgets/       Shared Flutter widgets

backend/uitm_api/
  api_bootstrap.php  Shared database and authentication helpers
  auth.php           Login and logout API
  orders.php         Supplier order API
  invoices.php       Invoice list and creation API

database/
  schema.sql         Database, demo data, and table definitions
```

## Prerequisites

- Flutter SDK 3.10 or newer
- Dart SDK 3.0 or newer
- Apache and PHP
- MySQL or MariaDB
- XAMPP or an equivalent PHP/MySQL environment

## Backend Setup

The PHP backend is currently configured for:

- Host: `127.0.0.1`
- Port: `3307`
- Database: `uitm_intern_db`
- Username: `root`
- Password: empty

MySQL commonly uses port `3306`; `3307` is also used when a local MySQL instance, such as XAMPP or WampServer, is configured with it. Use the port reported by your own MySQL installation:

- For MySQL port `3306`, set `3306` in `backend/uitm_api/api_bootstrap.php`.
- For MySQL port `3307`, keep the current `3307` setting.

These values are defined in `backend/uitm_api/api_bootstrap.php`. Update them if your local database configuration is different.

1. Start Apache and MySQL.
2. Ensure MySQL is listening on the same port configured in `api_bootstrap.php` (`3306` or `3307`).
3. Import `database/schema.sql` using phpMyAdmin or the MySQL command-line client.
4. Import `backend/uitm_api/auth_tokens.sql` after `schema.sql` to create the API token table.
5. Copy or link the `backend/uitm_api` directory to your Apache web root as `uitm_api`.

For a standard XAMPP installation, the API should be available at:

```text
http://localhost/uitm_api/auth.php
http://localhost/uitm_api/orders.php
http://localhost/uitm_api/invoices.php
```

The Flutter API endpoints currently use `localhost`. This works for web and Windows targets on the same computer. Android and iOS devices or emulators must use the host computer's network address instead, and the PHP CORS and network settings must allow the connection.

## Demo Accounts

| Username | Password |
| --- | --- |
| `supplier1` | `password123` |
| `supplier2` | `password123` |

The first successful login upgrades the demo plaintext password to a PHP password hash. Only supplier accounts can access the protected API endpoints.

## Run the Flutter Application

Install dependencies:

```powershell
flutter pub get
```

Check available devices:

```powershell
flutter devices
```

Run the application:

```powershell
flutter run
```

To run on Windows:

```powershell
flutter run -d windows
```

To run on Chrome:

```powershell
flutter run -d chrome
```

To run on an Android device or emulator:

```powershell
flutter run -d <device-id>
```

## Tests

Run the Flutter test suite:

```powershell
flutter test
```

The tests cover API services and invoice draft/status behaviour.

## API Summary

All protected endpoints require:

```text
Authorization: Bearer <token>
```

| Method | Endpoint | Description |
| --- | --- | --- |
| POST | `/uitm_api/auth.php` | Supplier login |
| DELETE | `/uitm_api/auth.php` | Invalidate the current bearer token |
| GET | `/uitm_api/orders.php` | List orders for the authenticated supplier |
| GET | `/uitm_api/invoices.php` | List invoices for the authenticated supplier |
| POST | `/uitm_api/invoices.php` | Create an invoice for an owned order |

## Notes

- Static demo data is still used in some screens.
- API endpoints must be reachable from the selected Flutter target.
- Demo credentials and database settings are intended for local development, not production.
- Plaintext seed passwords are upgraded to password hashes after the first login.

## Mobile LAN Preview (iOS / Android)

To test the prototype on a physical phone over the same Wi-Fi network without conflicting with port `8080`:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8085