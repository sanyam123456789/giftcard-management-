# Gift Card Management System (MySQL-Based)

## Overview

This project is a fully functional Gift Card Management System implemented using MySQL (version 5.7 or above). It supports the complete lifecycle of gift cards including generation, user association, redemption, recharging, transfers, balance tracking, transaction logging, status updates, and automatic expiry handling. The goal is to provide a robust backend system suitable for use in real-world e-commerce, retail, or enterprise environments.

## Core Features

The system allows for the creation of gift cards with unique codes, customizable initial balances, and defined expiration dates. Gift cards can be redeemed in full or partially across multiple transactions, with built-in checks to ensure that cards are active and have sufficient balance. Additionally, cards can be recharged and reused. Each transaction (whether redemption or recharge) is logged in a dedicated transactions table for transparency and auditability.

Users can be associated with gift cards, and cards can also be transferred between users. These transfers are logged to maintain a clear history of ownership. Card statuses include active, inactive, blocked, and expired. Status changes are logged, and an automated MySQL event runs daily to update the status of cards that have reached their expiration date.

## Reporting and Analytics

For reporting, the system includes several views: one to list active gift cards, one for expired cards, one to calculate the total number of issued cards, and another to show the total redeemed value per gift card. These views allow for efficient querying and real-time monitoring of gift card usage.

## Database Design

The database schema is fully normalized and includes appropriate indexes for performance. Stored procedures are provided to handle recharges, redemptions, transfers, and bulk generation of gift cards. These procedures encapsulate business logic and help maintain data consistency and security. Input validations are included to prevent invalid operations such as redeeming expired cards or transferring to a non-existent user.

## Use Cases

This backend-only implementation can be integrated easily with any frontend (web or mobile) and is suitable for:

- Academic projects
- Internship tasks
- Real-world systems requiring secure gift card functionality
- Admin dashboards for e-commerce or retail companies

## Technologies Used

- MySQL 5.7+
- Stored Procedures
- Views
- Events (for automated expiry)
- Triggers (optional)
- Indexing for optimization
