CREATE DATABASE Hospital;

USE Hospital;

CREATE TABLE patients(
PatientID INT Primary Key auto_increment,
FirstName VARCHAR(25),
LastName VARCHAR (25),
DateOfBirth DATE,
Gender ENUM('Male', 'Female', 'Other'),
Phone VARCHAR (15),
Email VARCHAR (50),
Address TEXT);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PatientID.csv'
INTO TABLE patients
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(PatientID, FirstName, LastName, DateOfBirth, Gender, Phone, Email, Address);

CREATE TABLE doctors(
DoctorID INT Primary Key auto_increment,
FirstName VARCHAR (25),
LastName VARCHAR (25),
Specialization VARCHAR (100),
Phone VARCHAR (15),
Email VARCHAR(50),
Availability TEXT);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/DoctorID.csv'
INTO TABLE doctors
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(DoctorID, FirstName, LastName, Specialization, Phone, Email, Availability);

CREATE TABLE appointments(
AppointmentID INT Primary Key auto_increment,
PatientID INT NOT NULL,
DoctorID INT NOT NULL,
AppointmentDate DATETIME NOT NULL,
AppointmentType ENUM('Checkup','Consultation', 'Follow-up', 'Emergency', 'Routine'),
Duration INT CHECK(Duration>0),
Status ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
FOREIGN KEY (PatientID) REFERENCES patients(patientID) ON DELETE CASCADE,
FOREIGN KEY (DoctorID) REFERENCES doctors(DoctorID) ON DELETE CASCADE);

CREATE TABLE MedicalRecords(
RecordID INT Primary Key auto_increment,
PatientID INT NOT NULL,
DoctorID INT NOT NULL,
Diagnosis TEXT,
Prescription TEXT,
TreatmentPlan TEXT,
RecordDate DATETIME DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (PatientID) REFERENCES patients(patientID) ON DELETE CASCADE,
FOREIGN KEY (DoctorID) REFERENCES doctors(DoctorID) ON DELETE CASCADE);

CREATE TABLE Billing(
InvoiceID INT Primary Key auto_increment,
PatientID INT NOT NULL,
AppointmentID INT NOT NULL,
Amount DECIMAL(10,2),
PaymentStatus ENUM('Paid', 'Unpaid', 'Pending') DEFAULT 'Pending',
PaymentDate DATE NULL,
FOREIGN KEY (PatientID) REFERENCES patients(patientID) ON DELETE CASCADE,
FOREIGN KEY (AppointmentID) REFERENCES appointments(AppointmentID) ON DELETE CASCADE);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Hospital.csv'
INTO TABLE appointments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(AppointmentID, PatientID, DoctorID, AppointmentDate, AppointmentType, Duration, Status);

ALTER TABLE Billing MODIFY COLUMN PaymentDate DATE NULL;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Billing.csv'
INTO TABLE billing
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(InvoiceID, PatientID, AppointmentID, Amount, PaymentStatus, @PaymentDate) 
SET PaymentDate = NULLIF(@PaymentDate, '');

Select * FROM MedicalRecords;

-- 1. Scheduling a New Appointment for an existing patient

INSERT INTO appointments (PatientID, DoctorID, AppointmentDate, AppointmentType, Duration, Status)
SELECT P.PatientID, D.DoctorID, '2025-03-18 10:00:00', 'Routine', 30, 'Scheduled'
FROM patients P, doctors D
WHERE P.PatientID = 1014 AND D.DoctorID = 4
AND NOT EXISTS(
   SELECT 1 FROM appointments
   WHERE DoctorID = 4 
   AND AppointmentDate = '2025-03-18 10:00:00');

-- 2. Updating an Appointment (Reschedule)

CREATE TEMPORARY TABLE Doctors_booked AS
SELECT DISTINCT DoctorID FROM appointments
WHERE AppointmentDate = '2025-03-19 10:00:00';

UPDATE appointments
SET AppointmentDate = '2025-03-19 10:00:00' 
WHERE PatientID = 1014 and AppointmentDate = '2025-03-18 10:00:00'
AND DoctorID NOT IN (
   SELECT DoctorID FROM Doctors_booked);
   
DROP TEMPORARY TABLE Doctors_booked;

-- 3. Canceling an Appointment

UPDATE appointments
SET Status = 'Cancelled'
WHERE AppointmentID = 102 ;

-- 4. Retrieving all past and upcoming appointments of a patient:

SELECT * FROM appointments
WHERE PatientID = 1014
ORDER BY AppointmentDate;

-- 5. Daily Appointment Report

SELECT A.AppointmentID, P.Firstname as Patient_name, P.Lastname as Patient_Surname, 
D.FirstName as Doctor_name, D.LastName as Doctor_Surname,
A.AppointmentDate, A.AppointmentType, A.Status
FROM appointments A
JOIN patients P on A.PatientID = P.PatientID
JOIN Doctors D on A.PatientID = D.DoctorID
WHERE DATE(A.AppointmentID) = CURDATE()
ORDER BY A.AppointmentDate ASC;

-- 6. Finding Available Doctors for a Given Time

SELECT DoctorID, FirstName, LastName FROM doctors
WHERE DoctorID NOT IN (
    SELECT DoctorID FROM appointments
    WHERE AppointmentDate = '2023-10-07 03:30:00');

-- 7. Most Frequent Patients (Loyal Patients)

SELECT P.PatientID, P.Firstname as Patient_name, P.Lastname as Patient_Surname, COUNT(A.AppointmentID) AS NoOfAppointments
FROM appointments A
JOIN patients P on A.PatientID = P.PatientID
GROUP BY P.PatientID, Patient_name, Patient_Surname
ORDER BY NoOfAppointments DESC
LIMIT 5;

-- 8. Doctor with Most Appointments

SELECT D.DoctorID, D.FirstName as Doctor_name, D.LastName as Doctor_Surname, COUNT(A.AppointmentID) AS NoOfAppointments
FROM appointments A
JOIN doctors D on A.DoctorID = D.DoctorID
GROUP BY D.DoctorID, Doctor_name, Doctor_Surname
ORDER BY NoOfAppointments DESC
LIMIT 5;

-- 9. Count of Appointments by Status

SELECT Status, COUNT(AppointmentID) AS NoOfAppointments
FROM appointments 
GROUP BY Status;

-- 10. Revenue Estimation (If Appointments are Chargeable)

SELECT SUM(AMOUNT) FROM billing;

-- 11. Finding Appointments Scheduled in the Next 7 Days

SELECT AppointmentID, PatientID, DoctorID, AppointmentDate
FROM appointments
WHERE AppointmentDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 Day) AND STATUS = 'Scheduled'
ORDER BY AppointmentDate ASC;
   
-- 12. Finding Appointments That Were Missed (Not Marked as Completed)

SELECT AppointmentID, PatientID, DoctorID, AppointmentDate
FROM appointments
WHERE AppointmentDate < CURDATE() AND STATUS = 'Scheduled'
ORDER BY AppointmentDate ASC;

-- 13. Getting the First and Last Appointment of the Day

SELECT MIN(AppointmentDate) AS FirstAppointment, MAX(AppointmentDate) as LastAppointment
FROM appointments
WHERE DATE(AppointmentDate) = CURDATE();

-- 14. Finding the Most Popular Appointment Type

SELECT COUNT(AppointmentID) AS TotalAppointments, AppointmentType 
FROM appointments
GROUP BY AppointmentType
ORDER BY TotalAppointments DESC
LIMIT 1;

-- 15. Finding Patients Who Have Not Visited in the Last 6 Months

SELECT P.PatientID, P.Firstname as Patient_name, P.Lastname as Patient_Surname, A.AppointmentDate
FROM patients P 
JOIN appointments A on P.PatientID = A.PatientID
WHERE AppointmentDate NOT IN (
   SELECT AppointmentDate 
   FROM appointments 
   WHERE AppointmentDate >= DATE_SUB(CURDATE(), INTERVAL 6 Month))
   GROUP BY P.PatientID, Patient_name, Patient_Surname, A.AppointmentDate;

-- 16. Finding Doctors Who Have No Appointments Today

SELECT DISTINCT DoctorID, FirstName, LastName
FROM doctors
WHERE DoctorID NOT IN (
   SELECT DISTINCT DoctorID
   FROM appointments
   WHERE AppointmentDate = CURDATE());
   
-- 17. Finding the Average Appointment Duration Per Doctor

SELECT D.DoctorID, D.FirstName as Doctor_name, D.LastName as Doctor_Surname, AVG(A.Duration) AS AvgDuration
FROM appointments A
JOIN doctors D on A.DoctorID = D.DoctorID
GROUP BY D.DoctorID, Doctor_name, Doctor_Surname
ORDER BY AvgDuration DESC;

-- 18. Finding the Most Overbooked Day in the Hospital

SELECT COUNT(*) AS TotalAppointments,  DATE(AppointmentDate) AS DATE
FROM appointments
GROUP BY DATE
ORDER BY TotalAppointments DESC
LIMIT 1;

-- 19. Checking the Earliest Available Slot for a Doctor

SELECT a1.AppointmentDate AS Current_Appointment, 
       a2.AppointmentDate AS Next_Appointment,
       TIMESTAMPDIFF(MINUTE, a1.AppointmentDate, a2.AppointmentDate) AS Gap_Minutes
FROM appointments a1
JOIN appointments a2 
    ON a1.DoctorID = a2.DoctorID 
    AND a1.AppointmentDate < a2.AppointmentDate
WHERE a1.DoctorID = 5 AND a1.AppointmentDate > NOW()
HAVING Gap_Minutes >= 30
ORDER BY a1.AppointmentDate
LIMIT 1;

-- 20. Finding Patients with the Longest Appointment Durations

SELECT P.PatientID, P.Firstname as Patient_name, P.Lastname as Patient_Surname, SUM(A.Duration) AS TotalDuration
FROM patients P
JOIN appointments A ON P.PatientID = A.PatientID
GROUP BY P.PatientID, Patient_name, Patient_Surname
ORDER BY TotalDuration DESC
LIMIT 5;
