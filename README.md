# CUT Clinic Appointment Management System

## All Safe Tech

The **CUT Clinic Appointment Management System** is a Work-Integrated Learning project developed by the **All Safe Tech** group for the Central University of Technology (CUT).

The system is designed to improve the management and communication of student clinic appointments between CUT students and authorised clinic staff.

---

## Project Problem

Students currently contact the CUT Clinic through **Outlook/email or telephone** to request appointments.

The appointment date and time are assigned by clinic staff.

A major challenge identified during the requirements investigation is that only two clinic staff members receive the relevant appointment email communication. If these staff members are unavailable, students may experience delays in receiving appointment information.

The proposed system aims to centralise appointment requests, appointment management and communication.

---

## Project Aim

The aim of the project is to design and develop a clinic appointment management system that improves the management and communication of clinic appointments for CUT students and authorised clinic staff.

---

## Main Users

### CUT Students

Students will be able to:

- Register for the system
- Log in securely
- Request an appointment
- View appointment status
- View assigned appointment date and time
- Cancel an appointment
- Receive SMS and email notifications
- Receive appointment reminders

### Authorised Clinic Staff

Clinic staff will be able to:

- Log in securely
- View appointment requests
- Approve appointment requests
- Reject appointment requests
- Assign appointment dates and times
- Reschedule appointments
- Manage appointments
- Send appointment notifications

---

## Technology Stack

| Component | Technology |
|---|---|
| Student Mobile Application | Flutter / Dart |
| Clinic Staff Web Application | ASP.NET Core / C# |
| Backend | Supabase |
| Database | PostgreSQL |
| Version Control | GitHub |
| Notifications | SMS and Email |

---

## System Architecture

The proposed system consists of:

1. Flutter Student Mobile Application
2. ASP.NET Core Clinic Staff Web Application
3. Supabase Authentication
4. Supabase PostgreSQL Database
5. Notification Services

The Flutter application is intended for CUT students, while the ASP.NET Core application is intended for authorised clinic staff.

Both applications use the shared backend for appointment and user data.

---

## Core Appointment Process

The proposed appointment process is:

```text
Student
   ↓
Register / Login
   ↓
Request Appointment
   ↓
Request stored in Supabase
   ↓
Clinic Staff Review
   ↓
Approve / Reject
   ↓
Assign Appointment Date & Time
   ↓
Student receives SMS / Email
   ↓
Student views appointment
   ↓
Student may cancel
   ↓
Day-before reminder
