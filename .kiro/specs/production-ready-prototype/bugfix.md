# Bugfix Requirements Document

## Introduction

FindProcurement+ (UiTM Mobile eProcurement, PEMBEKAL / supplier flow) has 20 screens (V01-V20) that look complete but behave like a static mock. All data is hardcoded, nothing is persisted, wizard steps do not share state, and key actions (submit tender, accept order, create invoice) change nothing. There is no input validation, no empty/loading/error handling, no session guard, and the admin flow from the wireframe is missing. The stale `test/widget_test.dart` fails because it references a non-existent `MyApp`. Only the web build has been verified. The system must be a complete, demo-ready prototype by the 24 November 2026 presentation (11 days from 13 November 2026), so the gaps below must be closed without changing the existing look, language or navigation.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the user closes and reopens the app, or reloads it THEN the system shows only the hardcoded dummy data and loses any change made during the previous session, because no database or persistent storage exists

1.2 WHEN the user submits a tender through the wizard (spesifikasi, harga, dokumen, semak) THEN the system shows the success screen but does not add or update any tender in "Tawaran Saya"

1.3 WHEN the user moves between wizard steps (or goes back to a previous step) THEN the system does not carry the entered specification, price and document values forward, so the review step cannot show what was entered

1.4 WHEN the user accepts an order (Pesanan) THEN the system navigates to the accepted screen but the order status and timeline remain unchanged in the list and detail screens

1.5 WHEN the user creates an invoice THEN the system shows the success screen but no invoice is added to the invoice list and the invoice status screen does not reflect it

1.6 WHEN the user enters empty, malformed or out-of-range values (for example blank login fields, zero or negative price, no specification selected, no document attached) THEN the system accepts them and proceeds to the next step

1.7 WHEN a list has no items, data is being loaded, or an operation fails THEN the system has no empty, loading or error state and shows a blank area or nothing at all

1.8 WHEN an unauthenticated user opens a protected route directly (for example /home or /pesanan) THEN the system displays it without requiring login, and logout does not clear any session

1.9 WHEN a user wants to demonstrate the administrative side of the wireframe (review tenders, issue orders, process invoices) THEN the system has no admin flow, so supplier actions can never be seen to progress on the other side

1.10 WHEN the automated tests are run THEN the system fails because `test/widget_test.dart` references a non-existent `MyApp`, and there are no tests covering the real behavior

1.11 WHEN the app is built for any platform other than web (Windows desktop, Android) THEN the system has not been verified to build, and the prerequisites (Visual Studio C++ workload, Android SDK) are not installed, so the demo target is not confirmed

1.12 WHEN notifications, counts on the home screen, or profile data are shown THEN the system displays static values that do not change in response to user actions

### Expected Behavior (Correct)

2.1 WHEN the user closes and reopens the app, or reloads it THEN the system SHALL load all invitations, tenders, orders, invoices, notifications and profile data from a local persistent database (seeded with the existing demo data on first run) and SHALL retain every change made in earlier sessions

2.2 WHEN the user submits a tender through the wizard THEN the system SHALL save a new tender (with its specification, price, documents, date and status "Dihantar") and SHALL show it in "Tawaran Saya" and in the home screen counts

2.3 WHEN the user moves between wizard steps or goes back THEN the system SHALL keep the entered specification, price and document values in shared wizard state, SHALL pre-fill returning steps, and SHALL show all entered values on the review step

2.4 WHEN the user accepts an order THEN the system SHALL update the stored order status and timeline, and the list, detail and accepted screens SHALL show the new status consistently

2.5 WHEN the user creates an invoice THEN the system SHALL save it against the selected order, SHALL list it in the invoice list, and SHALL show its status and timeline on the invoice status screen

2.6 WHEN the user enters empty, malformed or out-of-range values THEN the system SHALL block progression, SHALL show a clear Malay validation message next to the offending field, and SHALL NOT save the data

2.7 WHEN a list has no items, data is loading, or an operation fails THEN the system SHALL show a Malay empty state, a loading indicator, or an error message with a retry action respectively

2.8 WHEN an unauthenticated user opens a protected route THEN the system SHALL redirect to /login, and WHEN the user logs out THEN the system SHALL clear the session and return to /login

2.9 WHEN a user opens the admin flow THEN the system SHALL provide admin screens following the wireframe (at minimum: admin login or role selection, review submitted tenders and award or reject them, issue orders to suppliers, review and mark invoices as paid), and admin actions SHALL update the same stored data so the supplier side reflects them (including notifications)

2.10 WHEN the automated tests are run THEN the system SHALL pass a valid `flutter test` run, with the stale widget test replaced and tests covering persistence, wizard state, validation, order acceptance, invoice creation and route guarding

2.11 WHEN the app is built for the demo THEN the system SHALL build and run successfully on the verified target (web at minimum, with `flutter analyze` clean), and the supported demo path and run steps SHALL be documented; any additional platform (Windows, Android) SHALL be listed with the prerequisites it needs

2.12 WHEN notifications, home screen counts or profile data are shown THEN the system SHALL derive them from stored data so they update after user and admin actions

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the user navigates between the existing 20 screens (V01-V20) THEN the system SHALL CONTINUE TO use the same routes and navigation flow defined in the current go_router configuration

3.2 WHEN any screen is displayed THEN the system SHALL CONTINUE TO show all UI text in Malay

3.3 WHEN any screen is displayed THEN the system SHALL CONTINUE TO use the existing Material 3 monochrome theme, shared widgets and layout

3.4 WHEN the app is started for the first time THEN the system SHALL CONTINUE TO show the same demo content (company profile, invitations, tenders, orders, invoices, notifications and timelines) that appears today

3.5 WHEN valid input is provided THEN the system SHALL CONTINUE TO let the user complete the full supplier journey (login, view invitations, create tender, view orders, create invoice, view status) without extra required steps

3.6 WHEN the app is run on web THEN the system SHALL CONTINUE TO build and run as it does today

3.7 WHEN the user uses the bottom tab navigation and notification screen THEN the system SHALL CONTINUE TO behave as it does today for navigation and display
