# Pomfret Card App
**Developer**: Ilia Eremin ’25  
**Last Updated**: 1/30/2025  

---

## Table of Contents
1. [Mission Statement](#mission-statement)
2. [Pomcard App Overview](#pomcard-app-overview)
   - [1. Overview](#1-overview)
   - [2. Security Statement (Short Form)](#2-security-statement-short-form)
3. [Pomcard App Security Statement (Detailed)](#pomcard-app-security-statement-detailed)
4. [Statement of Legal Compliance](#statement-of-legal-compliance)
5. [Complete Overview Document](#complete-overview-document)
   - [1. Overview (Extended)](#1-overview-extended)
   - [2. Security Statement (Extended)](#2-security-statement-extended)
6. [License](#license)

---

## Mission Statement
**Date**: 1/21/2025  
**Author**: Ilia Eremin ’25  

The mission of the **Pomfret Card App** is to empower students by providing secure and convenient access to their own Pomfret Card data. Unlike traditional solutions such as the MyKidsSpending (MKS) app, which is designed for parental control and management, the Pomfret Card App focuses exclusively on students’ needs, offering a streamlined and read-only interface.

**Key Principles**:
- **Access Their Data**: Students can view balances and transaction history tied to their Pomfret Cards without intermediary steps or permissions.  
- **Gain Financial Awareness**: By monitoring their own spending habits, students can make more informed decisions about their finances.

The Pomfret Card App does **not** allow users to manage or alter financial data, preserving parental controls while enhancing transparency and direct access for students. It fills the gap left by inefficient systems like MKS, fostering student independence and financial awareness.

---

## Pomcard App Overview

### 1. Overview
- **Purpose and Goals**:  
  - Provide a read-only interface for Pomfret School community members (students, faculty) to view balances and transaction history.  
  - Deliver a secure, user-friendly experience without enabling financial transactions.

- **Problem Statement**:  
  Previously, users had to rely on manual methods or outdated systems (like MKS) to track their balances and transaction history. The Pomfret Card App modernizes this process.

- **Target Audience**:  
  - **Students**: For tracking Pomfret Card balances and transactions.  
  - **Faculty**: For personal use of their Pomfret Card (if applicable).

- **Reason for Creation**:  
  Address the limitations of older systems by providing an efficient, user-centric solution that respects security, privacy, and best practices.

- **Main Functions**:  
  - **Read-Only Interface**: View balances and transaction history.  
  - **Information Display**: Balances, transactions.  
  - **Card Scanning**: Optional scanning at authorized on-campus locations.

- **Emphasis on Read-Only Functionality**:  
  The app deliberately excludes any financial management features (adding funds, transferring, etc.) to ensure security and maintain a clear boundary.

### 2. Security Statement (Short Form)
The Pomfret Card App enforces strict security measures:

1. **Encryption**: Sensitive credentials (passwords, PINs, verification codes) are encrypted (SHA-256, AES-256) and securely stored.  
2. **Secure Database Hosting**: Uses Google Cloud SQL with SSL/TLS encryption and restricted IP access.  
3. **Backend Architecture**:  
   - **Pomfret Card Backend**: Handles authentication, session management, and stores only directory-like user data.  
   - **Integration Backend**: Hosted on a secure, school-managed server. It processes all financial data and transmits it directly to the user’s device, bypassing the Pomfret Card Backend.

4. **Data Visibility**:  
   - **Developer Access**: Limited to first name, last name, graduation year, and Pomfret email.  
   - **Financial Data**: Only the Integration Backend handles or sees balances, transaction history, etc.

5. **Data Retention and Deletion**:  
   - Temporary data (e.g., verification codes) is promptly deleted.  
   - Users can request account deletion at any time.

The Pomfret Card App maintains ongoing security audits and adheres to industry best practices to ensure user data remains private and safe.

---

## Pomcard App Security Statement (Detailed)
**Date**: 1/29/2025  
**Author**: Ilia Eremin ’25  

I designed the PomCard app with a **zero-knowledge security model**, ensuring that user privacy and data security are protected at all times. By implementing a **two-backend architecture**, robust **end-to-end encryption**, and strict **authentication controls**, my system eliminates vulnerabilities and ensures that even I, as the developer, cannot access user data under any circumstances.

### Two-Backend Architecture

1. **Integration Backend (Financial Data)**
   - Handles all sensitive financial data without storing or processing authentication credentials.  
   - Encrypts all user data before transmission using the **RSA algorithm**, ensuring that only the intended recipient can decrypt it.  
   - Sends encrypted data directly to the user’s device for decryption, preventing third-party interception.

2. **PomCard Backend (Authentication & Access Control)**
   - Manages user authentication and identity verification separately from financial data processing.  
   - Validates user requests through **JWT-based access tokens**, ensuring that all requests are authorized, secure, and device-bound.  
   - Prevents unauthorized access by ensuring that financial data requests originate from the intended, authenticated user.

### Security Impact of Architecture
This separation of duties guarantees that no single backend has access to both raw user data and authentication mechanisms, mitigating risks of insider threats, data leaks, and unauthorized access.

### Encryption and Key Management
1. **RSA Key Pair Generation**
   - Each user’s RSA key pair is generated at login.  
   - Private keys are stored exclusively on the user’s device and never transmitted.  
   - Public keys are stored in plaintext in the database for encryption purposes only.

2. **Data Encryption**
   - All sensitive financial data is encrypted before leaving Odin Inc.'s backend using the user’s public key.  
   - Only the user’s private key, stored securely on their device, can decrypt the data.  
   - Even if Odin Inc.'s database is compromised, the data remains completely indecipherable.

3. **JWT-Based Authentication**
   - The PomCard backend issues JWTs, which include:
     - **UID**: Identifies the user.  
     - **Full Name**: Provides additional context.  
     - **Device Info**: Ensures the request originates from the authenticated device.  
     - **Expiration (exp) and Issue Dates (iat)**: Limits token validity.  
     - **Audience (aud) and Issuer (iss)**: Ensures tokens are valid for the intended recipient and backend.  
   - JWTs are cryptographically signed and validated before every request.

4. **Key Validation**
   - Before any sensitive data is encrypted and transmitted, the PomCard backend verifies that the public key used for encryption matches the user’s registered key.  
   - Prevents key-swapping attacks by ensuring only the intended user can decrypt data.

### Threat Mitigation Strategies
- **SQL Injection Prevention**: All database queries use parameterized queries via ORM tools like SQLAlchemy.  
- **Cross-Site Scripting (XSS) Prevention**: User inputs are sanitized and escaped before storage/rendering.  
- **Man-in-the-Middle (MITM) Attack Prevention**: All communication is secured with HTTPS/TLS encryption.  
- **Replay Attack Protection**: Strict JWT expiration policy and device/session claims.  
- **Database Breach Mitigation**: Financial data is fully encrypted. Even if compromised, it remains indecipherable without the user’s private key.  
- **Private Key Security**: Stored securely on the device (Android Keystore or iOS Secure Enclave).  
- **Insider Threat Prevention**:  
  - Developers have **zero access** to user data.  
  - Databases do not store or transmit decryptable user data.

### Commitment to Privacy and Security
Through **strong cryptographic enforcement**, **key pair management**, and **strict separation of duties**, PomCard ensures that no entity—including the developer or any third party—except Odin Inc. can access or misuse user data. Ongoing **security audits** and updates are integral to maintaining a **zero-knowledge architecture**, enabling users to retain full control over their own data.

---

## Statement of Legal Compliance
**Date**: 1/30/2025  
**Author**: Ilia Eremin ’25  

I, Ilia Eremin, am the developer of the Pomfret Card app, a non-commercial, school-focused application designed to help Pomfret School students access their account balance and transaction history. This statement clarifies how the app handles data and explains why certain regulatory requirements do not apply.

### 1. Overview of Data Flow
- **Zero-Knowledge Financial Data Backend (Integration Backend)**  
  - **What It Provides**: Transaction history, balance, and barcode (student ID) data come directly from Odin’s secure database.  
  - **Developer Access**: I do not have direct access to Odin’s financial backend or its stored data.  
  - **Responsibility**: Odin Inc. is SOC 2 certified and responsible for protecting and securing all financial data.

- **App’s Directory Data Backend**  
  - **What It Holds**: Name, last name, graduation year, Pomfret email.  
  - **Nature of Data**: Considered “directory information” at Pomfret School and **not** sensitive personal data under the relevant regulations discussed below.

### 2. SOC (System and Organization Controls)
- **Why SOC Does Not Apply**:  
  - The Pomfret Card app does not store or process financial data independently; it only displays data from Odin Inc.  
  - Odin Inc. holds SOC 2 certification and is responsible for securing financial data.

### 3. FERPA (Family Educational Rights and Privacy Act)
- **Why FERPA Does Not Apply**:  
  - FERPA protects student education records like grades and transcripts.  
  - The Pomfret Card app only displays transaction history (financial data) and minimal directory information, which is **not** considered an education record under FERPA.

### 4. CTDPA (Connecticut Data Privacy Act)
- **Why CTDPA Does Not Apply**:  
  - CTDPA generally applies to for-profit entities processing large volumes of personal data or earning revenue from data sales.  
  - The Pomfret Card app is a **non-commercial** tool and does not sell user data or handle large-scale data.  

### 5. COPPA (Children’s Online Privacy Protection Act)
- **Why COPPA Does Not Apply**:  
  - COPPA covers online services targeting children under 13.  
  - The Pomfret Card app is intended for high school students (13+). No data is collected from children under 13.

### 6. GLBA (Gramm-Leach-Bliley Act)
- **Why GLBA Does Not Apply**:  
  - GLBA pertains to financial institutions handling consumer financial data.  
  - Odin Inc. (not the Pomfret Card app) manages all financial data, and they assume compliance responsibilities.

### 7. Security and Privacy Best Practices
Despite these regulations not applying directly, the Pomfret Card app upholds best practices:
- **Secure Data Transmission**: End-to-end encryption for financial data.  
- **Minimal Data Collection**: Only first name, last name, graduation year, Pomfret email.  
- **Zero-Knowledge Approach**: The developer cannot access user balances, transaction histories, or barcodes.  
- **Access Controls**: Strict authentication ensures only legitimate users see their data.  
- **No Data Sharing or Selling**: Non-commercial and does not sell or share data with third parties.

### Conclusion
The Pomfret Card app does not require SOC, FERPA, CTDPA, COPPA, or GLBA compliance because it does not independently process or store sensitive financial or educational data. Odin Inc. remains responsible for financial data security (SOC 2 certified), and the app only utilizes directory information deemed non-sensitive by these regulations. Nevertheless, the app implements robust security measures to protect user data at all times.

---

## Complete Overview Document

Below is a consolidated version of the **Pomfret Card App Overview** and its sections, including a short security statement that aligns with the detailed approach above.

### 1. Overview (Extended)
1. **Purpose and Goals**  
   - Provide students and faculty at Pomfret School with a read-only interface for accessing Pomfret Card balances, transactions, and barcode scanning.  
   - Offer a secure platform that does **not** facilitate financial transactions.

2. **Problem Statement**  
   - Users previously relied on outdated or manual methods to track balances and transactions. The Pomfret Card App serves as a modern, centralized solution.

3. **Target Audience**  
   - **Students**: Track and view Pomfret Card balances and transactions.  
   - **Faculty**: For personal use, if needed.

4. **Reason for Creation**  
   - Address the limitations of legacy systems by providing a secure, user-friendly, read-only interface.

5. **Main Functions**  
   - **Read-Only Data Access**: Balances, transaction history.  
   - **Card Scanning**: Ability to scan Pomfret Cards at authorized on-campus points.

6. **Key Definitions**  
   - **Pomfret Card**: School-issued card for campus purchases/services.  
   - **Read-Only Interface**: Data can be viewed but not modified.  
   - **Scan Functionality**: Physical card scanning at authorized campus locations.

7. **Emphasis on Read-Only Functionality**  
   - No ability to add/transfer funds or modify data.  
   - Maintains security and boundary with parental controls.

### 2. Security Statement (Extended)
The **Pomfret Card App** is built around robust security and privacy measures:

1. **Encryption**  
   - Sensitive data (passwords, PINs, verification codes) is encrypted (SHA-256, AES-256).  
   - Data in transit is secured over HTTPS/TLS.

2. **Secure Database Hosting**  
   - Google Cloud SQL ensures SSL/TLS encryption, automated backups, and restricted IP ranges.

3. **Backend Architecture**  
   - **Pomfret Card Backend**: Handles authentication. No financial data is processed or stored.  
   - **Integration Backend**: Hosted on a secure, school-managed server. Directly handles financial data and communicates it to the user’s device.

4. **Data Collected**  
   - **PII**: Name, last name, graduation year, Pomfret email (directory information).  
   - **Sensitive Data**: Passwords, PINs, and email verification codes (encrypted and hashed).  
   - **Transaction Data**: Balances and history (only seen by the Integration Backend).  
   - **Technical Data**: Device info and usage metrics for debugging.

5. **Data Visibility**  
   - **Developer**: Can see minimal directory data only.  
   - **Financial Data**: Handled exclusively by the Integration Backend with zero-knowledge to the developer.

6. **Data Retention and Deletion**  
   - Verification codes are deleted once used.  
   - Upon user request, all data is removed from both backends.

7. **Commitment to Continuous Security Improvement**  
   - Regular audits, vulnerability assessments, and adherence to industry best practices.

---

## License
This project is a **non-commercial, school-focused application**.  
Unless otherwise noted, all documentation and code are released under an appropriate open-source or permissive license chosen by Pomfret School or the developer. Please refer to the repository’s license file (if provided) for exact terms.

---

**© 2025 Pomfret Card App | Developed by Ilia Eremin ’25**  
_All rights reserved where applicable. For questions or further information, please contact the developer._




