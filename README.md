# IERT Hostel Management System (HMS)

This is a Flutter-based Hostel Management application integrated with Firebase Authentication and Cloud Firestore for role-based authorization, complaints filing, fee tracking, vacancy checking, and notices management.

## Seeding & Test Credentials
To simplify testing, the login home screen contains a **"Seed Firebase Test Data"** button. Clicking it initializes the following resources:

### Test Accounts (Password for all is `password123`)
* **Admin Login**:
  - **Email**: `admin@hostel.com`
* **Student Logins**:
  - **Student ID (Roll No)**: `STU001` (Email: `student1@hostel.com`)
  - **Student ID (Roll No)**: `STU002` (Email: `student2@hostel.com`)

---

## Firestore Schema & Collections

### 1. `students/{studentId}`
* ID represents the student Roll No / UID.
* Fields:
  - `rollNo`: String (e.g. `STU001`)
  - `name`: String
  - `email`: String (used for Roll No -> Email authentication lookup)
  - `branch`: String
  - `year`: String (e.g. `1st Year`, `2nd Year`)
  - `roomAllotted`: String (room number, empty when unallotted)
  - `hostelBlock`: String (academic year/block, empty when unallotted)
  - `phone`: String
  - `parentsContact`: String
  - `casteCategory`: String
  - `feeStatus`: String (`Paid` / `Due` / `Overdue`)
  - `authUid`: String (Associated Firebase Auth user UID)

### 2. `admins/{adminId}`
* ID represents the admin auth UID.
* Fields:
  - `name`: String
  - `email`: String
  - `authUid`: String

### 3. `complaints/{complaintId}`
* Fields:
  - `studentId`: String (refers to student Roll No)
  - `studentName`: String
  - `title`: String
  - `category`: String (`maintenance` / `cleaning` / `electricity` / `water` / `security` / `other`)
  - `description`: String
  - `status`: String (`Pending` / `In Progress` / `Resolved`)
  - `createdAt`: Timestamp

### 4. `fees/{feeId}`
* Fields:
  - `studentId`: String
  - `amount`: Number
  - `dueDate`: Timestamp
  - `status`: String (`Paid` / `Due` / `Overdue`)
  - `paidOn`: Timestamp (Nullable)
  - `paymentMethod`: String (`Online` / `Cash` / `Cheque` / `Pending`)

### 5. `notices/{noticeId}`
* Fields:
  - `title`: String
  - `body`: String
  - `postedBy`: String
  - `createdAt`: Timestamp

### 6. `feedback/{feedbackId}`
* Fields:
  - `studentId`: String
  - `studentName`: String
  - `roomNo`: String
  - `message`: String
  - `rating`: Number
  - `category`: String
  - `createdAt`: Timestamp

### 7. `rooms/{roomId}`
* Fields:
  - `roomNumber`: String
  - `capacity`: Number
  - `occupiedCount`: Number
  - `occupantStudentIds`: Array of String
  - `hostelBlock`: String

---

## Firestore Security Rules
Copy and paste the rules below into the **Rules** tab of your Firestore Database console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user exists in the admins collection
    function isAdmin() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Helper function to check if the student is accessing their own data (comparing rollNo)
    function isOwner(studentRollNo) {
      return isAuthenticated() && (
        get(/databases/$(database)/documents/students/$(studentRollNo)).data.authUid == request.auth.uid
      );
    }
    
    // Students collection rules
    match /students/{studentId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || (isAuthenticated() && request.auth.uid == resource.data.authUid);
      allow create: if isAuthenticated();
    }
    
    // Admins collection rules
    // Allow any authenticated user to CREATE their own admin doc (bootstrapping).
    // Only existing admins can UPDATE or DELETE admin docs.
    match /admins/{adminId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && adminId == request.auth.uid;
      allow update, delete: if isAdmin();
    }
    
    // Complaints rules
    match /complaints/{complaintId} {
      allow read: if isAdmin() || (isAuthenticated() && resource.data.studentId != null && isOwner(resource.data.studentId));
      allow create: if isAuthenticated() && request.resource.data.studentId != null && isOwner(request.resource.data.studentId);
      allow update, delete: if isAdmin();
    }
    
    // Fees rules
    match /fees/{feeId} {
      allow read: if isAdmin() || (isAuthenticated() && resource.data.studentId != null && isOwner(resource.data.studentId));
      allow write: if isAdmin();
    }
    
    // Notices rules
    match /notices/{noticeId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Feedback rules
    match /feedback/{feedbackId} {
      allow read: if isAdmin() || (isAuthenticated() && resource.data.studentId != null && isOwner(resource.data.studentId));
      allow create: if isAuthenticated() && request.resource.data.studentId != null && isOwner(request.resource.data.studentId);
      allow update, delete: if isAdmin();
    }
    
    // Rooms rules
    match /rooms/{roomId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```
