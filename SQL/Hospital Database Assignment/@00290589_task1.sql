-- make full script rerunnable
IF DB_ID('SalfordHospitalDatabase') IS NOT NULL
BEGIN
use [master]
ALTER DATABASE [SalfordHospitalDatabase] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
END
GO

DROP DATABASE IF EXISTS [SalfordHospitalDatabase]
GO

CREATE DATABASE SalfordHospitalDatabase
GO

USE SalfordHospitalDatabase
GO

-- Question1 - create tables
CREATE TABLE Address (
	AddressID int IDENTITY NOT NULL PRIMARY KEY,
	AddressLine1 nvarchar(100) NOT NULL,
	AddressLine2 nvarchar(50) NULL,
	City nvarchar(50) NOT NULL,
	County nvarchar(50) NOT NULL,
	PostCode nvarchar(15) NOT NULL,
	Country nvarchar(30) NULL,
	CONSTRAINT Uniq_Address UNIQUE (AddressLine1, PostCode));

CREATE TABLE Hospital (
	HospitalID int IDENTITY NOT NULL PRIMARY KEY,
	HospitalName nvarchar(50) NOT NULL,
	HospitalReceptionTelNum nvarchar(20) NOT NULL,
	HospitalAddressID int NOT NULL);

CREATE TABLE Department (
	DepartmentID int IDENTITY NOT NULL PRIMARY KEY,
	DepartmentName nvarchar(100) NOT NULL,
	BuildingName nvarchar(50) NOT NULL,
	DepartmentTelNum nvarchar(20) NOT NULL,
	DepartmentEmail nvarchar(200) UNIQUE NOT NULL CHECK (DepartmentEmail LIKE '%_@_%.%'),
	HeadDepartmentID int NULL,
	DepartmentHospitalID int NOT NULL);

CREATE TABLE Doctor (
	DoctorID int IDENTITY NOT NULL PRIMARY KEY,
	DoctorTitle nvarchar(20) NULL,
	DoctorFirstName nvarchar(50) NOT NULL,
	DoctorMiddleName nvarchar(50) NULL,
	DoctorLastName nvarchar(50) NOT NULL,
	DoctorDOB date NOT NULL,
	DoctorAddressID int NOT NULL,
	DoctorGender nvarchar(20) NOT NULL CONSTRAINT Doctor_Gender 
		CHECK (DoctorGender LIKE 'Male' OR DoctorGender LIKE 'Female' OR DoctorGender LIKE 'Non-binary' OR 
		DoctorGender LIKE 'Prefer not to say'),
	DoctorMaritalStatus nvarchar(50) CONSTRAINT Doctor_MaritalStatus
		CHECK (DoctorMaritalStatus LIKE 'Single' OR DoctorMaritalStatus LIKE 'Married' OR DoctorMaritalStatus LIKE 'Civil Partnership' OR
			DoctorMaritalStatus LIKE 'Prefer not to say' OR DoctorMaritalStatus LIKE 'Divorced'),
	DoctorEmail nvarchar(200) UNIQUE NOT NULL CHECK (DoctorEmail LIKE '%_@_%.%'),
	DoctorTelNum nvarchar(20) NOT NULL ,
	EmploymentStartDate date NOT NULL DEFAULT CONVERT(DATE, GETDATE()),
	EmploymentEndDate date NULL,
	Specialty nvarchar(100),
	DoctorDepartmentID int NOT NULL,
	StartWorkHours time NOT NULL,
	EndWorkHours time NOT NULL);

CREATE TABLE Patient (
	PatientID int IDENTITY NOT NULL PRIMARY KEY,
	PatientTitle nvarchar(20) NULL,
	PatientFirstName nvarchar(50) NOT NULL,
	PatientMiddleName nvarchar(50) NULL,
	PatientLastName nvarchar(50) NOT NULL,
	PatientDOB date NOT NULL,
	PatientAddressID int NOT NULL,
	PatientGender nvarchar(20) NOT NULL CONSTRAINT Patient_Gender 
		CHECK (PatientGender LIKE 'Male' OR PatientGender LIKE 'Female' OR PatientGender LIKE 'Non-binary' OR PatientGender LIKE 'Prefer not to say'),
	PatientMaritalStatus nvarchar(50) CONSTRAINT Patient_MaritalStatus
		CHECK (PatientMaritalStatus LIKE 'Single' OR PatientMaritalStatus LIKE 'Married' OR PatientMaritalStatus LIKE 'Civil Partnership' OR
			PatientMaritalStatus LIKE 'Prefer not to say' OR PatientMaritalStatus LIKE 'Divorced'),
	PatientEmail nvarchar(200) UNIQUE NULL CHECK (PatientEmail LIKE '%_@_%.%'),
	PatientTelNum nvarchar(20) NULL ,
	PatientGPID int NOT NULL,
	PatientJoinDate date NOT NULL DEFAULT CONVERT(DATE, GETDATE()),
	PatientInsuranceProvider nvarchar(100) NOT NULL,
	PatientInsuranceStartDate date NOT NULL,
	PatientInsuranceEndDate date NOT NULL,
	PatientInsuranceType nvarchar(100) NOT NULL,
	PatientUsername nvarchar(40) UNIQUE NOT NULL,
	PatientPasswordHash binary(64) NOT NULL,
	Salt UNIQUEIDENTIFIER);

CREATE TABLE ArchivedPatient (
	ArchivedPatientID int NOT NULL PRIMARY KEY,
	ArchivedPatientTitle nvarchar(20) NULL,
	ArchivedPatientFirstName nvarchar(50) NOT NULL,
	ArchivedPatientMiddleName nvarchar(50) NULL,
	ArchivedPatientLastName nvarchar(50) NOT NULL,
	ArchivedPatientDOB date NOT NULL,
	ArchivedPatientAddressID int NOT NULL,
	ArchivedPatientGender nvarchar(20) NOT NULL CONSTRAINT ArchivedPatient_Gender 
		CHECK (ArchivedPatientGender LIKE 'Male' OR ArchivedPatientGender LIKE 'Female' OR ArchivedPatientGender LIKE 'Non-binary' OR ArchivedPatientGender LIKE 'Prefer not to say'),
	ArchivedPatientMaritalStatus nvarchar(50) CONSTRAINT ArchivedPatient_MaritalStatus
		CHECK (ArchivedPatientMaritalStatus LIKE 'Single' OR ArchivedPatientMaritalStatus LIKE 'Married' OR ArchivedPatientMaritalStatus LIKE 'Civil Partnership' OR
			ArchivedPatientMaritalStatus LIKE 'Prefer not to say' OR ArchivedPatientMaritalStatus LIKE 'Divorced'),
	ArchivedPatientEmail nvarchar(200) UNIQUE NULL CHECK (ArchivedPatientEmail LIKE '%_@_%.%'),
	ArchivedPatientTelNum nvarchar(20) NULL ,
	ArchivedPatientGPID int NOT NULL,
	ArchivedPatientJoinDate date NOT NULL,
	ArchivedPatientLeaveDate date NOT NULL,
	ArchivedPatientInsuranceProvider nvarchar(100) NOT NULL,
	ArchivedPatientInsuranceStartDate date NOT NULL,
	ArchivedPatientInsuranceEndDate date NOT NULL,
	ArchivedPatientInsuranceType nvarchar(100) NOT NULL,
	ArchivedPatientUsername nvarchar(40) UNIQUE NOT NULL,
	ArchivedPatientPasswordHash binary(64) NOT NULL,
	ArchivedSalt UNIQUEIDENTIFIER);

CREATE TABLE Appointment (
	AppointmentID int IDENTITY NOT NULL PRIMARY KEY,
	AppointmentPatientID int NOT NULL,
	AppointmentDoctorID int NOT NULL,
	AppointmentDepartmentID int NOT NULL,
	AppointmentDateTime datetime NOT NULL,
	AppointmentStatus nvarchar(15) NOT NULL CONSTRAINT Appointment_AppointmentStatus
		CHECK (AppointmentStatus LIKE 'Pending' OR AppointmentStatus LIKE 'Completed' OR AppointmentStatus LIKE 'Cancelled') DEFAULT 'Pending',
	AppointmentPurpose nvarchar(200) NOT NULL,
	AppointmentAvailable int NOT NULL CONSTRAINT Appointment_AvailableBoolean
		CHECK (AppointmentAvailable = 0 OR AppointmentAvailable = 1) DEFAULT 0,
	CONSTRAINT Appointment_TimeMinutes
		CHECK (DATEPART(MI, AppointmentDateTime) = 0 OR DATEPART(MI, AppointmentDateTime) = 15 OR 
			DATEPART(MI, AppointmentDateTime) = 30 OR DATEPART(MI, AppointmentDateTime) = 45),
	CONSTRAINT Appointment_Weekday
		CHECK (DATENAME(WEEKDAY, AppointmentDateTime) != 'Saturday' AND DATENAME(WEEKDAY, AppointmentDateTime) != 'Sunday'),
	CONSTRAINT Appointment_WorkDayTime
		CHECK (DATEPART(HH, AppointmentDateTime) BETWEEN 8 AND 18));

-- Question 2 - add constraint to check appointment date is not in the past
ALTER TABLE Appointment 
	ADD CONSTRAINT Appointment_FutureDateCheck
		CHECK (DATEDIFF(DD, GETDATE(), AppointmentDateTime) >= 0);
GO

-- Question 6 - trigger to change the current state of an appointment to available when it is cancelled
CREATE OR ALTER TRIGGER t_AppointmentCancelled ON Appointment
AFTER UPDATE
AS BEGIN
	UPDATE Appointment SET AppointmentAvailable = 1
	FROM Appointment AS a
	INNER JOIN INSERTED AS i
	ON a.AppointmentID = i.AppointmentID
	WHERE	i.AppointmentStatus = 'Cancelled'
END;
GO

CREATE TABLE CompletedAppointment (
	CompletedAppointmentID int NOT NULL PRIMARY KEY,
	CompletedAppointmentPatientID int NOT NULL,
	CompletedAppointmentDoctorID int NOT NULL,
	CompletedAppointmentDepartmentID int NOT NULL,
	CompletedAppointmentDateTime datetime NOT NULL,
	CompletedAppointmentStatus nvarchar(15) NOT NULL CONSTRAINT CompletedAppointment_AppointmentStatus
		CHECK (CompletedAppointmentStatus LIKE 'Completed') DEFAULT 'Completed',
	CompletedAppointmentPurpose nvarchar(200) NOT NULL,
	PatientFeedback nvarchar(500) NULL,
	CONSTRAINT CompletedAppointment_TimeMinutes
		CHECK (DATEPART(MI, CompletedAppointmentDateTime) = 0 OR DATEPART(MI, CompletedAppointmentDateTime) = 15 OR 
			DATEPART(MI, CompletedAppointmentDateTime) = 30 OR DATEPART(MI, CompletedAppointmentDateTime) = 45),
	CONSTRAINT CompletedAppointment_Weekday
		CHECK (DATENAME(WEEKDAY, CompletedAppointmentDateTime) != 'Saturday' AND DATENAME(WEEKDAY, CompletedAppointmentDateTime) != 'Sunday'),
	CONSTRAINT CompletedAppointment_WorkDayTime
		CHECK (DATEPART(HH, CompletedAppointmentDateTime) BETWEEN 8 AND 18));
GO

-- trigger to copy appointment to CompletedAppointment when its status is changed to 'completed'
CREATE OR ALTER TRIGGER t_AppointmentCompleted On Appointment
AFTER UPDATE
AS BEGIN
	INSERT INTO CompletedAppointment (
	CompletedAppointmentID,
	CompletedAppointmentPatientID,
	CompletedAppointmentDoctorID,
	CompletedAppointmentDepartmentID,
	CompletedAppointmentDateTime,
	CompletedAppointmentStatus,
	CompletedAppointmentPurpose)
	SELECT 
	a.AppointmentID,
	a.AppointmentPatientID,
	a.AppointmentDoctorID,
	a.AppointmentDepartmentID,
	a.AppointmentDateTime,
	a.AppointmentStatus,
	a.AppointmentPurpose
	FROM Appointment AS a
	INNER JOIN INSERTED AS i
	ON a.AppointmentID = i.AppointmentID
	WHERE	i.AppointmentStatus = 'Completed'
END;
GO

CREATE TABLE MedicalRecord (
	MedicalRecordDiagnosisID int IDENTITY PRIMARY KEY,
	MedicalRecordDiagnosisDate date NOT NULL,
	MedicalRecordPatientID int NOT NULL,
	MedicalRecordConditionID int NOT NULL);

CREATE TABLE Condition (
	ConditionID int IDENTITY NOT NULL PRIMARY KEY,
	ConditionName nvarchar(200) UNIQUE NOT NULL,
	ConditionCategory nvarchar(100) NOT NULL)

CREATE TABLE Medicine (
	MedicineID int IDENTITY NOT NULL PRIMARY KEY,
	MedicineName nvarchar(200) UNIQUE NOT NULL,
	MedicineType nvarchar(150) NOT NULL);

CREATE TABLE Allergen (
	AllergenID int IDENTITY NOT NULL PRIMARY KEY,
	AllergenName nvarchar(100) UNIQUE NOT NULL);

CREATE TABLE Prescription (
	DiagnosisID int NOT NULL FOREIGN KEY (DiagnosisID)
		REFERENCES MedicalRecord (MedicalRecordDiagnosisID) ON DELETE CASCADE,
	MedicineID int NOT NULL FOREIGN KEY (MedicineID)
		REFERENCES Medicine (MedicineID),
	Dosage nvarchar(100) NOT NULL,
	PrescriptionReviewDate date NOT NULL,
	PRIMARY KEY (DiagnosisID, MedicineID));

CREATE TABLE Allergy (
	PatientID int NOT NULL FOREIGN KEY (PatientID)
		REFERENCES Patient (PatientID) ON DELETE CASCADE,
	AllergenID int NOT NULL FOREIGN KEY (AllergenID)
		REFERENCES Allergen (AllergenID),
	Severity nvarchar(100) NOT NULL,
	PRIMARY KEY(PatientID, AllergenID));

-- add foreign keys
ALTER TABLE Patient
	ADD FOREIGN KEY (PatientAddressID)
		REFERENCES Address (AddressID);

ALTER TABLE Patient
	ADD FOREIGN KEY (PatientGPID)
		REFERENCES Doctor (DoctorID);

ALTER TABLE Doctor
	ADD FOREIGN KEY (DoctorAddressID)
		REFERENCES Address (AddressID);

ALTER TABLE Doctor
	ADD FOREIGN KEY (DoctorDepartmentID)
		REFERENCES Department (DepartmentID);

ALTER TABLE Department
	ADD FOREIGN KEY (HeadDepartmentID)
		REFERENCES Doctor (DoctorID);

ALTER TABLE Department
	ADD FOREIGN KEY (DepartmentHospitalID)
		REFERENCES Hospital (HospitalID);

ALTER TABLE Hospital
	ADD FOREIGN KEY (HospitalAddressID)
		REFERENCES Address (AddressID);

ALTER TABLE Appointment
	ADD FOREIGN KEY (AppointmentPatientID)
		REFERENCES Patient (PatientID)
			ON DELETE CASCADE;

ALTER TABLE Appointment
	ADD FOREIGN KEY (AppointmentDoctorID)
		REFERENCES Doctor (DoctorID);

ALTER TABLE Appointment
	ADD FOREIGN KEY (AppointmentDepartmentID)
		REFERENCES Department (DepartmentID);

ALTER TABLE MedicalRecord
	ADD FOREIGN KEY (MedicalRecordPatientID)
		REFERENCES Patient (PatientID)
			ON DELETE CASCADE;

ALTER TABLE MedicalRecord
	ADD FOREIGN KEY (MedicalRecordConditionID)
		REFERENCES Condition (ConditionID);
GO

-- create Schemas
CREATE SCHEMA Addresses;
GO
ALTER SCHEMA Addresses TRANSFER dbo.Address
GO

CREATE SCHEMA HospitalInfo;
GO
ALTER SCHEMA HospitalInfo TRANSFER dbo.Hospital
ALTER SCHEMA HospitalInfo TRANSFER dbo.Department
GO

CREATE SCHEMA Employee
GO
ALTER SCHEMA Employee TRANSFER dbo.Doctor
GO

CREATE SCHEMA PatientInfo;
GO
ALTER SCHEMA PatientInfo TRANSFER dbo.Patient
ALTER SCHEMA PatientInfo TRANSFER dbo.ArchivedPatient
ALTER SCHEMA PatientInfo TRANSFER dbo.MedicalRecord
ALTER SCHEMA PatientInfo TRANSFER dbo.Prescription
ALTER SCHEMA PatientInfo TRANSFER dbo.Allergy
GO

CREATE SCHEMA PatientAccess;
GO

CREATE SCHEMA MedicalInfo;
GO
ALTER SCHEMA MedicalInfo TRANSFER dbo.Condition
ALTER SCHEMA MedicalInfo TRANSFER dbo.Medicine
ALTER SCHEMA MedicalInfo TRANSFER dbo.Allergen
GO

CREATE SCHEMA Appointments
GO
ALTER SCHEMA Appointments TRANSFER dbo.Appointment
ALTER SCHEMA Appointments TRANSFER dbo.CompletedAppointment
GO

 -- Insert Hospital Address
 INSERT INTO Addresses.Address(
	AddressLine1,
	AddressLine2,
	City,
	County,
	PostCode)
VALUES (
	'120-220 Salford Road',
	'Eccles',
	'Salford',
	'Greater Manchester',
	'M6 4AJ')
GO

-- Insert Hospital
INSERT INTO HospitalInfo.Hospital (
	HospitalName,
	HospitalReceptionTelNum,
	HospitalAddressID)
VALUES (
	'Salford Hospital',
	'0161 542 8960',
	1)
GO

-- Add Hospital Departments to Department table
INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Department of Hayfever',
	'Allergies and Neuroscience Building',
	'0161 542 8962',
	'departmentofhayfever@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Department of Cardiology',
	'Heart and Cardiovascular Building',
	'0161 542 8963',
	'departmentofcardiology@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Department of Gastroenterology',
	'Gastroenterology Building',
	'0161 542 8964',
	'departmentofgastroenterology@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Maternity & Childcare Department',
	'Childcare Building',
	'0161 542 8964',
	'maternityandchildcaredepartment@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Department of Oncology',
	'Oncology Building',
	'0161 542 8965',
	'departmentofoncology@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Department of Orthopaedics',
	'Bones Building',
	'0161 542 8966',
	'departmentoforthopaedics@salfordhospital.gov.uk',
	1)
GO

INSERT INTO HospitalInfo.Department (
	DepartmentName,
	BuildingName,
	DepartmentTelNum,
	DepartmentEmail,
	DepartmentHospitalID)
VALUES (
	'Radiotherapy',
	'Radiotherapy Building',
	'0161 542 8967',
	'radiotherapy@salfordhospital.gov.uk',
	1)
GO

-- stored procedure to add new Doctor
CREATE OR ALTER PROCEDURE HospitalInfo.AddNewDoctor
	@DoctorTitle nvarchar(20),
	@DoctorFirstName nvarchar(50),
	@DoctorMiddleName nvarchar(50) = NULL,
	@DoctorLastName nvarchar(50),
	@DoctorDOB date,
	@DoctorAddressID int,
	@DoctorGender nvarchar(20),
	@DoctorMaritalStatus nvarchar(50),
	@DoctorEmail nvarchar(200),
	@DoctorTelNum nvarchar(20) ,
	@EmploymentStartDate date,
	@EmploymentEndDate date = NULL,
	@Specialty nvarchar(100),
	@DoctorDepartmentID int,
	@StartWorkHours time,
	@EndWorkHours time
AS BEGIN
INSERT INTO Employee.Doctor (
	DoctorTitle,
	DoctorFirstName,
	DoctorMiddleName,
	DoctorLastName,
	DoctorDOB,
	DoctorAddressID,
	DoctorGender,
	DoctorMaritalStatus,
	DoctorEmail,
	DoctorTelNum,
	EmploymentStartDate,
	EmploymentEndDate,
	Specialty,
	DoctorDepartmentID,
	StartWorkHours,
	EndWorkHours)
VALUES (
	@DoctorTitle,
	@DoctorFirstName,
	@DoctorMiddleName,
	@DoctorLastName,
	@DoctorDOB,
	@DoctorAddressID,
	@DoctorGender,
	@DoctorMaritalStatus,
	@DoctorEmail,
	@DoctorTelNum,
	@EmploymentStartDate,
	@EmploymentEndDate,
	@Specialty,
	@DoctorDepartmentID,
	@StartWorkHours,
	@EndWorkHours)
END
GO

-- execute stored procedure to add new Doctors and populate Doctor table
EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Marshall',
@DoctorLastName = 'Boggswothy',
@DoctorDOB = '1970-01-01',
@DoctorAddressID = 1,
@DoctorGender = 'Male',
@DoctorMaritalStatus = 'Married',
@DoctorEmail = 'm.boggsworthy@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8962',
@EmploymentStartDate = '1996-01-01',
@Specialty = 'Allergies',
@DoctorDepartmentID = 1,
@StartWorkHours = '09:00',
@EndWorkHours = '17:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Alison',
@DoctorLastName = 'Chapman',
@DoctorDOB = '1985-12-10',
@DoctorAddressID = 1,
@DoctorGender = 'Female',
@DoctorMaritalStatus = 'Single',
@DoctorEmail = 'a.chapman@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8992',
@EmploymentStartDate = '2015-06-12',
@Specialty = 'Gastroenterologist',
@DoctorDepartmentID = 3,
@StartWorkHours = '08:00',
@EndWorkHours = '18:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Prof',
@DoctorFirstName = 'Marcus',
@DoctorMiddleName = 'James',
@DoctorLastName = 'Endswain',
@DoctorDOB = '1955-02-7',
@DoctorAddressID = 1,
@DoctorGender = 'Male',
@DoctorMaritalStatus = 'Married',
@DoctorEmail = 'm.endswain@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8985',
@EmploymentStartDate = '2015-06-12',
@Specialty = 'Gastroenterologist',
@DoctorDepartmentID = 3,
@StartWorkHours = '10:00',
@EndWorkHours = '14:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Mark',
@DoctorLastName = 'Jones',
@DoctorDOB = '1970-10-25',
@DoctorAddressID = 1,
@DoctorGender = 'Male',
@DoctorMaritalStatus = 'Married',
@DoctorEmail = 'm.jones@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8955',
@EmploymentStartDate = '2004-01-31',
@Specialty = 'Cardiologist',
@DoctorDepartmentID = 2,
@StartWorkHours = '09:00',
@EndWorkHours = '17:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Rita',
@DoctorMiddleName = 'Marie',
@DoctorLastName = 'Rogers',
@DoctorDOB = '1965-04-21',
@DoctorAddressID = 1,
@DoctorGender = 'Female',
@DoctorMaritalStatus = 'Divorced',
@DoctorEmail = 'r.rogers@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8945',
@EmploymentStartDate = '2004-01-31',
@Specialty = 'Maternity Care',
@DoctorDepartmentID = 4,
@StartWorkHours = '06:00',
@EndWorkHours = '18:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Betty',
@DoctorLastName = 'Reshma',
@DoctorDOB = '1983-05-31',
@DoctorAddressID = 1,
@DoctorGender = 'Female',
@DoctorMaritalStatus = 'Single',
@DoctorEmail = 'b.reshma@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8932',
@EmploymentStartDate = '2014-06-30',
@Specialty = 'Oncologist',
@DoctorDepartmentID = 5,
@StartWorkHours = '11:00',
@EndWorkHours = '16:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Prof',
@DoctorFirstName = 'Stephen',
@DoctorLastName = 'Googen',
@DoctorDOB = '1985-01-02',
@DoctorAddressID = 1,
@DoctorGender = 'Male',
@DoctorMaritalStatus = 'Single',
@DoctorEmail = 's.googen@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8952',
@EmploymentStartDate = '2023-04-01',
@Specialty = 'Orthopaedic Surgeon',
@DoctorDepartmentID = 6,
@StartWorkHours = '09:00',
@EndWorkHours = '18:00'
GO

EXEC HospitalInfo.AddNewDoctor
@DoctorTitle = 	'Dr',
@DoctorFirstName = 'Alex',
@DoctorMiddleName = 'Mowgli',
@DoctorLastName = 'Trigg',
@DoctorDOB = '1991-05-03',
@DoctorAddressID = 1,
@DoctorGender = 'Male',
@DoctorMaritalStatus = 'Single',
@DoctorEmail = 'a.trigg@salfordhospital.gov.uk',
@DoctorTelNum = '0161 542 8978',
@EmploymentStartDate = '2024-03-01',
@Specialty = 'Radiotherapist',
@DoctorDepartmentID = 6,
@StartWorkHours = '07:00',
@EndWorkHours = '17:00'
GO

-- set HeadDepartmentID for each Department
UPDATE HospitalInfo.Department
SET HeadDepartmentID = 1
WHERE DepartmentID = 1
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 4
WHERE DepartmentID = 2
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 2
WHERE DepartmentID = 3
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 5
WHERE DepartmentID = 4
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 6
WHERE DepartmentID = 5
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 7
WHERE DepartmentID = 6
GO

UPDATE HospitalInfo.Department
SET HeadDepartmentID = 8
WHERE DepartmentID = 7
GO

-- stored procedure to add new patients, insert patient information into Patient & Address tables
CREATE OR ALTER PROCEDURE PatientAccess.PatientPortalRegistration 
	@AddressLine1 nvarchar(100),
	@AddressLine2 nvarchar(50),
	@City nvarchar(50),
	@County nvarchar(50),
	@PostCode nvarchar(15),
	@Country nvarchar(30),
	@PatientTitle nvarchar(20),
	@PatientFirstName nvarchar(50),
	@PatientMiddleName nvarchar(50),
	@PatientLastName nvarchar(50),
	@PatientDOB date,
	@PatientGender nvarchar(20),
	@PatientMaritalStatus nvarchar(50),
	@PatientEmail nvarchar(200),
	@PatientTelNum nvarchar(20),
	@PatientGPID int,
	@PatientJoinDate date,
	@PatientUsername nvarchar(40),
	@PatientPassword nvarchar(50),
	@InsuranceProvider nvarchar(100),
	@InsuranceStartDate date,
	@InsuranceEndDate date,
	@InsuranceType nvarchar(100)
AS BEGIN TRANSACTION
BEGIN TRY
	DECLARE @PatientAddressID int;
	BEGIN TRY
		INSERT INTO Addresses.Address (
			AddressLine1,
			AddressLine2,
			City,
			County,
			PostCode,
			Country)
		VALUES (
			@AddressLine1,
			@AddressLine2,
			@City,
			@County,
			@PostCode,
			@Country)
			SET @PatientAddressID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
	SET @PatientAddressID = (SELECT AddressID
													FROM Addresses.Address
													WHERE (AddressLine1 LIKE @AddressLine1 AND
																		PostCode LIKE @PostCode))
	END CATCH;
		-- check password valid
		IF (@PatientPassword like '%[0-9]%' AND @PatientPassword LIKE '%[A-Z]%' COLLATE Latin1_General_BIN2 AND
		@PatientPassword LIKE '%[!@#$%^&*()_+=.,;:~]%' AND LEN(@PatientPassword)>=8)
			BEGIN
				DECLARE @salt UNIQUEIDENTIFIER = NEWID()
				INSERT INTO PatientInfo.Patient (
					PatientTitle,
					PatientFirstName,
					PatientMiddleName,
					PatientLastName,
					PatientDOB,
					PatientAddressID,
					PatientGender,
					PatientMaritalStatus,
					PatientEmail,
					PatientTelNum,
					PatientGPID,
					PatientJoinDate,
					PatientInsuranceProvider,
					PatientInsuranceStartDate,
					PatientInsuranceEndDate,
					PatientInsuranceType,
					PatientUsername,
					PatientPasswordHash,
					Salt)
				VALUES (
					@PatientTitle,
					@PatientFirstName,
					@PatientMiddleName,
					@PatientLastName,
					@PatientDOB,
					@PatientAddressID,
					@PatientGender,
					@PatientMaritalStatus,
					@PatientEmail,
					@PatientTelNum,
					@PatientGPID,
					@PatientJoinDate,
					@InsuranceProvider,
					@InsuranceStartDate,
					@InsuranceEndDate,
					@InsuranceType,
					@PatientUsername,
					HASHBYTES('SHA2_512', @PatientPassword+CAST(@salt AS nvarchar(36))),
					@salt)
			END
		ELSE
			BEGIN
			-- password not valid
				RAISERROR('Invalid password', 16, 1);
			END
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	-- if error inserting data to tables
	ROLLBACK TRANSACTION
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
					@ErrSeverity = ERROR_SEVERITY()
	RAISERROR (@ErrMsg, @ErrSeverity,1)
END CATCH
GO

-- add patients
EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '29 Beckley Avenue',
	@AddressLine2 = NULL,
	@City = 'Manchester',
	@County = 'Greater Manchester',
	@PostCode = 'M25 9GY',
	@Country = 'United Kingdom',
	@PatientTitle = 'Mr',
	@PatientFirstName = 'Jamie',
	@PatientMiddleName = NULL,
	@PatientLastName = 'Penhale-Jones',
	@PatientDOB = '1993-04-29',
	@PatientGender = 'Male',
	@PatientMaritalStatus = 'Single',
	@PatientEmail = 'j.penhale-jones@edu.salford.ac.uk',
	@PatientTelNum = '07891639455',
	@PatientGPID = '1',
	@PatientJoinDate = '2024-03-12',
	@PatientUsername = 'JamiePJ',
	@PatientPassword = 'Password1!',
	@InsuranceProvider = 'AVIVA',
	@InsuranceStartDate = '2024-01-1',
	@InsuranceEndDate = '2024-12-31',
	@InsuranceType = 'Fully comprehensive';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '14 Alphington Avenue',
	@AddressLine2 = NULL,
	@City = 'Camberley',
	@County = 'Surrey',
	@PostCode = 'GU1 6IL',
	@Country = 'United Kingdom',
	@PatientTitle = 'Miss',
	@PatientFirstName = 'Kirsty',
	@PatientMiddleName = 'Anne',
	@PatientLastName = 'Adams',
	@PatientDOB = '1992-09-15',
	@PatientGender = 'Female',
	@PatientMaritalStatus = 'Single',
	@PatientEmail = 'kirstyadams92@gmail.com',
	@PatientTelNum = '01276 548985',
	@PatientGPID = '2',
	@PatientJoinDate = '2024-03-12',
	@PatientUsername = 'KirstyA',
	@PatientPassword = 'strOng_passW0rd"3',
	@InsuranceProvider = 'AVIVA',
	@InsuranceStartDate = '2024-01-01',
	@InsuranceEndDate = '2024-12-31',
	@InsuranceType = 'Fully comprehensive';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '5 High Street',
	@AddressLine2 = NULL,
	@City = 'Manchester',
	@County = 'Greater Manchester',
	@PostCode = 'M46 0BP',
	@Country = 'United Kingdom',
	@PatientTitle = 'Mrs',
	@PatientFirstName = 'Joyce',
	@PatientMiddleName = NULL,
	@PatientLastName = 'James',
	@PatientDOB = '1970-01-01',
	@PatientGender = 'Female',
	@PatientMaritalStatus = 'Married',
	@PatientEmail = 'JoyceJames@gmail.com',
	@PatientTelNum = '0161 588 9685',
	@PatientGPID = '3',
	@PatientJoinDate = '2024-03-12',
	@PatientUsername = 'JoyceJ2',
	@PatientPassword = '12P@ssword£',
	@InsuranceProvider = 'Direct Line',
	@InsuranceStartDate = '2023-01-01',
	@InsuranceEndDate = '2024-12-31',
	@InsuranceType = 'Third party fire and theft';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '5 High Street',
	@AddressLine2 = NULL,
	@City = 'Manchester',
	@County = 'Greater Manchester',
	@PostCode = 'M46 0BP',
	@Country = 'United Kingdom',
	@PatientTitle = 'Mr',
	@PatientFirstName = 'Charles',
	@PatientMiddleName = NULL,
	@PatientLastName = 'James',
	@PatientDOB = '1970-01-01',
	@PatientGender = 'Male',
	@PatientMaritalStatus = 'Married',
	@PatientEmail = 'charlesjames@gmail.com',
	@PatientTelNum = '0161 588 9685',
	@PatientGPID = '3',
	@PatientJoinDate = '2024-03-12',
	@PatientUsername = 'CharlesJ',
	@PatientPassword = '12P@ssword£',
	@InsuranceProvider = 'Direct Line',
	@InsuranceStartDate = '2023-01-01',
	@InsuranceEndDate = '2024-12-31',
	@InsuranceType = 'Third party fire and theft';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '14 Alphington Avenue',
	@AddressLine2 = NULL,
	@City = 'Camberley',
	@County = 'Surrey',
	@PostCode = 'GU1 6IL',
	@Country = 'United Kingdom',
	@PatientTitle = 'Miss',
	@PatientFirstName = 'Dolly',
	@PatientMiddleName = NULL,
	@PatientLastName = 'Price',
	@PatientDOB = '2021-11-01',
	@PatientGender = 'Female',
	@PatientMaritalStatus = 'Single',
	@PatientEmail = 'dolly_price@gmail.com',
	@PatientTelNum = '07891639455',
	@PatientGPID = '4',
	@PatientJoinDate = '2024-03-12',
	@PatientUsername = 'DollyP',
	@PatientPassword = '12P@ssword£',
	@InsuranceProvider = 'AVIVA',
	@InsuranceStartDate = '2022-04-01',
	@InsuranceEndDate = '2025-03-31',
	@InsuranceType = 'Fully comprehensive';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '1 Prestwich Road',
	@AddressLine2 = NULL,
	@City = 'Manchester',
	@County = 'Greater Manchester',
	@PostCode = 'M25 9HG',
	@Country = 'United Kingdom',
	@PatientTitle = 'Mr',
	@PatientFirstName = 'John',
	@PatientMiddleName = 'Jonathon',
	@PatientLastName = 'Johnson',
	@PatientDOB = '1980-01-01',
	@PatientGender = 'Male',
	@PatientMaritalStatus = 'Divorced',
	@PatientEmail = 'johnjohnson80@live.co.uk',
	@PatientTelNum = '08005498750',
	@PatientGPID = '5',
	@PatientJoinDate = '2022-01-25',
	@PatientUsername = 'JJJ5678',
	@PatientPassword = '4goodPasswod&',
	@InsuranceProvider = 'GoCompare',
	@InsuranceStartDate = '2022-04-01',
	@InsuranceEndDate = '2025-03-31',
	@InsuranceType = 'Most things covered';
GO

EXEC PatientAccess.PatientPortalRegistration
	@AddressLine1 = '1 Prestwich Road',
	@AddressLine2 = NULL,
	@City = 'Manchester',
	@County = 'Greater Manchester',
	@PostCode = 'M25 9HG',
	@Country = 'United Kingdom',
	@PatientTitle = 'Mrs',
	@PatientFirstName = 'Jane',
	@PatientMiddleName = 'Janison',
	@PatientLastName = 'Johnson',
	@PatientDOB = '1980-04-01',
	@PatientGender = 'Female',
	@PatientMaritalStatus = 'Divorced',
	@PatientEmail = 'janejohnson80@live.co.uk',
	@PatientTelNum = '08005498750',
	@PatientGPID = '6',
	@PatientJoinDate = '2022-01-25',
	@PatientUsername = 'JJJ5679',
	@PatientPassword = '4goodPasswod&',
	@InsuranceProvider = 'GoCompare',
	@InsuranceStartDate = '2022-04-01',
	@InsuranceEndDate = '2025-03-31',
	@InsuranceType = 'Most things covered';
GO

-- stored procedure for booking appointment
CREATE OR ALTER PROCEDURE PatientAccess.BookingAppointment
	@AppointmentPatientID int,
	@AppointmentDoctorID int,
	@AppointmentDate date,
	@AppointmentTime time,
	@AppointmentPurpose nvarchar(200) AS BEGIN
DECLARE @AppointmentDateTime datetime
SET @AppointmentDateTime = CAST(@AppointmentDate AS datetime) + CAST(@AppointmentTime AS datetime)
-- check appointment date is a weekday
IF (DATENAME(WEEKDAY, @AppointmentDateTime) != 'Saturday' AND DATENAME(WEEKDAY, @AppointmentDateTime) != 'Sunday')
BEGIN
	-- check appointment time is in doctor's working hours and more than 15 mins before doctor's end hours
	DECLARE @DoctorStartWorkHour time
	DECLARE @DoctorEndWorkHour time	
	SET @DoctorStartWorkHour = (
		SELECT StartWorkHours
		FROM Employee.Doctor
		WHERE DoctorID = @AppointmentDoctorID)
	SET @DoctorEndWorkHour = (
		SELECT EndWorkHours
		FROM Employee.Doctor
		WHERE DoctorID = @AppointmentDoctorID)
	IF (@AppointmentTime BETWEEN @DoctorStartWorkHour AND @DoctorEndWorkHour) AND
		(DATEDIFF(MI, @AppointmentTime, @DoctorEndWorkHour) >= 15)
		BEGIN
			-- check appointment datetime is available
			IF @AppointmentDateTime NOT IN (SELECT AppointmentDateTime
																		FROM Appointments.Appointment
																		WHERE AppointmentDoctorID = @AppointmentDoctorID AND
																			AppointmentAvailable = 0)
				BEGIN
					INSERT INTO Appointments.Appointment (
						AppointmentPatientID,
						AppointmentDoctorID,
						AppointmentDepartmentID,
						AppointmentDateTime,
						AppointmentPurpose)
						VALUES (
						@AppointmentPatientID,
						@AppointmentDoctorID,
						(SELECT DoctorDepartmentID
						FROM Employee.Doctor
						WHERE DoctorID = @AppointmentDoctorID),
						@AppointmentDateTime,
						@AppointmentPurpose)
				END
			ELSE
				BEGIN
					PRINT 'This appointment time is not available, please try another time'
				END
		END
	-- ELSE for doctor working hours check
	ELSE
		BEGIN
			PRINT 'Please choose a time between the doctor''s working hours of ' + CAST(@DoctorStartWorkHour AS nvarchar(5))  + ' and ' + CAST(@DoctorEndWorkHour AS nvarchar(5)) 
		END
END
-- ELSE for weekday check
ELSE
	BEGIN
		PRINT 'Please select date that is a weekday'
	END
END
GO

-- execute stored procedure to book appointments and populate Appointment table
EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 1,
	@AppointmentDoctorID = 1,
	@AppointmentDate = '2024-07-01',
	@AppointmentTime = '12:00',
	@AppointmentPurpose = 'Hayfever'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 1,
	@AppointmentDoctorID = 2,
	@AppointmentDate = '2024-07-31',
	@AppointmentTime = '09:00',
	@AppointmentPurpose = 'Gastroenteritis'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 2,
	@AppointmentDoctorID = 2,
	@AppointmentDate = '2024-08-01',
	@AppointmentTime = '15:00',
	@AppointmentPurpose = 'Gastroenteritis'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 7,
	@AppointmentDoctorID = 4,
	@AppointmentDate = '2024-06-03',
	@AppointmentTime = '16:45',
	@AppointmentPurpose = 'Suspected broken arm'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 5,
	@AppointmentDoctorID = 8,
	@AppointmentDate = '2024-05-31',
	@AppointmentTime = '09:00',
	@AppointmentPurpose = 'X-Ray of broken leg'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 6,
	@AppointmentDoctorID = 6,
	@AppointmentDate = '2024-06-03',
	@AppointmentTime = '12:30',
	@AppointmentPurpose = 'Potential cancer diagnosis'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 7,
	@AppointmentDoctorID = 5,
	@AppointmentDate = '2024-06-11',
	@AppointmentTime = '13:15',
	@AppointmentPurpose = 'Prenatal appointment'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 2,
	@AppointmentDoctorID = 4,
	@AppointmentDate = '2024-06-19',
	@AppointmentTime = '16:00',
	@AppointmentPurpose = 'Heart Palpitations'
GO

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 4,
	@AppointmentDoctorID = 7,
	@AppointmentDate = '2024-05-24',
	@AppointmentTime = '15:45',
	@AppointmentPurpose = 'Foot pain'
GO

-- cancel appointment 4, trigger has fired and set appointment as available
UPDATE Appointments.Appointment
SET AppointmentStatus = 'Cancelled'
WHERE AppointmentID = 4
GO

SELECT *
FROM Appointments.Appointment

-- check cancelled appointment can be rebooked
EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 1,
	@AppointmentDoctorID = 1,
	@AppointmentDate = '2024-06-03',
	@AppointmentTime = '16:45',
	@AppointmentPurpose = 'Motion sickness'
GO

-- stored procedure for when appointment is completed (change appointment status from pending to completed)
CREATE OR ALTER PROCEDURE Appointments.SetAppointmentCompleted
	@AppointmentID int
AS BEGIN
	UPDATE Appointments.Appointment
	SET AppointmentStatus = 'Completed'
	WHERE AppointmentID = @AppointmentID
END
GO

-- execute stored procedure for completing appointment
EXEC Appointments.SetAppointmentCompleted
	@AppointmentID = 1;
GO

EXEC Appointments.SetAppointmentCompleted
	@AppointmentID = 2;
GO

EXEC Appointments.SetAppointmentCompleted
	@AppointmentID = 3;
GO

EXEC Appointments.SetAppointmentCompleted
	@AppointmentID = 5;
GO

-- question 4d) stored procedure for deleting appointment with completed status
CREATE OR ALTER PROCEDURE HospitalInfo.DeleteCompletedAppointment
	@AppointmentID int
AS BEGIN
	IF (SELECT AppointmentStatus
			FROM Appointments.Appointment
			WHERE AppointmentID = @AppointmentID) = 'Completed'
		BEGIN
			DELETE FROM Appointments.Appointment
			WHERE AppointmentID = @AppointmentID
		END
	ELSE
		BEGIN
			PRINT 'Only completed appointments can be deleted from Appointments'
		END
END;
GO

-- execute stored procedure for deleting completed appointments - SELECT table for before SP executed
SELECT *
FROM Appointments.Appointment
GO

-- delete completed appointments
EXEC HospitalInfo.DeleteCompletedAppointment
	@AppointmentID = 1;
GO

EXEC HospitalInfo.DeleteCompletedAppointment
	@AppointmentID = 2;
GO

EXEC HospitalInfo.DeleteCompletedAppointment
	@AppointmentID = 3;
GO

EXEC HospitalInfo.DeleteCompletedAppointment
	@AppointmentID = 5;
GO

-- SELECT table for after SP executed and appointments deleted
SELECT *
FROM Appointments.Appointment
GO

-- deleted completed appointments are present in CompletedAppointment table
SELECT *
FROM Appointments.CompletedAppointment
GO

-- stored procedure to update/add patient allergies
CREATE OR ALTER PROCEDURE PatientInfo.UpdatePatientAllergies
	@PatientID int,
	@AllergenName nvarchar(100),
	@Severity nvarchar(100)
AS BEGIN TRANSACTION
BEGIN TRY
	BEGIN TRY
	DECLARE @AllergenID int;
		INSERT INTO MedicalInfo.Allergen (AllergenName)
		VALUES (@AllergenName)
		SET @AllergenID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
		SET @AllergenID = (SELECT AllergenID
											FROM MedicalInfo.Allergen
											WHERE AllergenName = @AllergenName)
	END CATCH
		INSERT INTO PatientInfo.Allergy (
			PatientID, 
			AllergenID, 
			Severity)
		VALUES (
			@PatientID,
			@AllergenID,
			@Severity)
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	-- if error inserting data to tables
	ROLLBACK TRANSACTION
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		@ErrSeverity = ERROR_SEVERITY()
	RAISERROR (@ErrMsg, @ErrSeverity,1)
END CATCH
GO

-- execute stored procedure to add allergies for patients
EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 1,
	@AllergenName = 'Hayfever',
	@Severity = 'Moderate symptoms, doesn''t affect daily life'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 2,
	@AllergenName = 'Hayfever',
	@Severity = 'Severe, patient avoids trees at all costs'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 2,
	@AllergenName = 'Cow milk',
	@Severity = 'Moderate symptoms, patient avoids products containing cow''s milk'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 3,
	@AllergenName = 'Peanuts',
	@Severity = 'Mild to moderate. Patient cannot consume peanuts but is able to be in same room as them'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 4,
	@AllergenName = 'Peanuts',
	@Severity = 'Severe, cannot board plane containing peanuts.'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 5,
	@AllergenName = 'Chilli powder',
	@Severity = 'Mild, patient avoids foods containing chilli.'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 6,
	@AllergenName = 'Alcohol',
	@Severity = 'Severe, patient cannot be within 100m of establishments serving alcohol.'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 6,
	@AllergenName = 'Cow milk',
	@Severity = 'Moderate symptoms, patient avoids products containing cow''s milk'
GO

EXEC PatientInfo.UpdatePatientAllergies
	@PatientID = 7,
	@AllergenName = 'Bio-based laundry detergent',
	@Severity = 'Moderate, skin becomes itchy.'
GO

-- stored procedure to update patient's medical record
CREATE OR ALTER PROCEDURE PatientInfo.UpdatePatientMedicalRecord
	@PatientID int,
	@date date,
	@ConditionName nvarchar(200),
	@ConditionCategory nvarchar(100),
	@MedicineName nvarchar(200),
	@MedicineType nvarchar(150) = NULL,
	@Dosage nvarchar(100),
	@PrescriptionReviewDate date
AS BEGIN TRANSACTION
BEGIN TRY
	-- insert new Condition and save ConditionID
	DECLARE @ConditionID int;
	BEGIN TRY
		INSERT INTO MedicalInfo.Condition (
			ConditionName,
			ConditionCategory)
		VALUES (
			@ConditionName,
			@ConditionCategory)
		SET @ConditionID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
	-- return ConditionID for existing Condition
		SET @ConditionID = (SELECT ConditionID
											FROM MedicalInfo.Condition
											WHERE ConditionName = @ConditionName)
	END CATCH
	-- insert new MedicalRecord and save MedicalRecordID
	DECLARE @MedicalRecordID int;
		INSERT INTO PatientInfo.MedicalRecord (
			MedicalRecordDiagnosisDate, 
			MedicalRecordPatientID, 
			MedicalRecordConditionID)
		VALUES (
			@date,
			@PatientID,
			@ConditionID)
	SET @MedicalRecordID = SCOPE_IDENTITY()
	-- insert new Medicine and save MedicineID
	BEGIN TRY
	DECLARE @MedicineID int;
		INSERT INTO MedicalInfo.Medicine (
			MedicineName,
			MedicineType)
		VALUES (
			@MedicineName,
			@MedicineType)
	SET @MedicineID = SCOPE_IDENTITY()
	END TRY
	BEGIN CATCH
	-- return MedicineID for existing Medicine
	SET @MedicineID = (SELECT MedicineID
										FROM MedicalInfo.Medicine
										WHERE MedicineName = @MedicineName)
	END CATCH
		INSERT INTO PatientInfo.Prescription (
			DiagnosisID, 
			MedicineID, 
			Dosage, 
			PrescriptionReviewDate)
		VALUES (
			@MedicalRecordID,
			@MedicineID,
			@Dosage,
			@PrescriptionReviewDate)
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	-- if error inserting data to tables
	ROLLBACK TRANSACTION
	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(),
		@ErrSeverity = ERROR_SEVERITY()
	RAISERROR (@ErrMsg, @ErrSeverity,1)
END CATCH
GO

-- execute stored procedure to update Patient Medical Records with diagnosis & prescriptions of medicines
EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 7,
	@date = '2024-03-22',
	@ConditionName = 'Bowel Cancer',
	@ConditionCategory = 'Cancer',
	@MedicineName = 'Chemotherapy Drug',
	@MedicineType = 'Chemotherapy',
	@Dosage = '500mg',
	@PrescriptionReviewDate = '2024-06-22'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 6,
	@date = '2024-04-02',
	@ConditionName = 'Toe Cancer',
	@ConditionCategory = 'Cancer',
	@MedicineName = 'Chemotherapy Drug',
	@MedicineType = 'Chemotherapy',
	@Dosage = '6 weeks treatment',
	@PrescriptionReviewDate = '2024-05-31'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 4,
	@date = '2024-03-22',
	@ConditionName = 'Anxiety',
	@ConditionCategory = 'Mental Disorder',
	@MedicineName = 'Prozac',
	@MedicineType = 'Anti-depressant',
	@Dosage = '200mg',
	@PrescriptionReviewDate = '2024-03-31'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 3,
	@date = '2024-03-22',
	@ConditionName = 'Broken leg',
	@ConditionCategory = 'Broken Bone',
	@MedicineName = 'Paracetamol',
	@MedicineType = 'Painkiller',
	@Dosage = '600mg',
	@PrescriptionReviewDate = '2024-06-30'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 2,
	@date = '2024-04-01',
	@ConditionName = 'Short-sightedness',
	@ConditionCategory = 'Sight deficiency',
	@MedicineName = 'Increased Glasses prescription',
	@MedicineType = 'Glasses',
	@Dosage = 'Increased glasses prescription',
	@PrescriptionReviewDate = '2025-04-01'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 1,
	@date = '2024-04-10',
	@ConditionName = 'Stress',
	@ConditionCategory = 'Mental Disorder',
	@MedicineName = 'Time Off Work',
	@MedicineType = 'Time Off Work',
	@Dosage = '1 week off work',
	@PrescriptionReviewDate = '2024-04-18'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 5,
	@date = '2024-04-02',
	@ConditionName = 'ADHD',
	@ConditionCategory = 'Mental Disorder',
	@MedicineName = 'Ritalin',
	@MedicineType = 'ADHD Medication',
	@Dosage = '50mg',
	@PrescriptionReviewDate = '2024-04-18'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 1,
	@date = '2024-07-31',
	@ConditionName = 'Gastroenteritis',
	@ConditionCategory = 'Gastroenterological',
	@MedicineName = 'Immodium',
	@MedicineType = 'Gastroenteritis Medication',
	@Dosage = '50mg',
	@PrescriptionReviewDate = '2024-08-31'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 2,
	@date = '2024-08-01',
	@ConditionName = 'Gastroenteritis',
	@ConditionCategory = 'Gastroenterological',
	@MedicineName = 'Immodium',
	@MedicineType = 'Gastroenteritis Medication',
	@Dosage = '50mg',
	@PrescriptionReviewDate = '2024-09-30'
GO

EXEC PatientInfo.UpdatePatientMedicalRecord
	@PatientID = 6,
	@date = '2024-04-30',
	@ConditionName = 'Toe Cancer',
	@ConditionCategory = 'Cancer',
	@MedicineName = 'Stronger Chemotherapy Drug ',
	@MedicineType = 'Chemotherapy',
	@Dosage = '10 weeks treatment',
	@PrescriptionReviewDate = '2024-07-16'
GO

-- stored procedure for patient to add feedback for Doc after appointment
CREATE OR ALTER PROCEDURE PatientAccess.AddPatientFeedback
	@CompletedAppointmentID int,
	@Feedback nvarchar (500)
AS BEGIN
UPDATE Appointments.CompletedAppointment
SET PatientFeedback = @Feedback
WHERE CompletedAppointmentID = @CompletedAppointmentID
END
GO

-- add feedback for completed appointments
EXEC PatientAccess.AddPatientFeedback
@CompletedAppointmentID = 1,
	@Feedback = 'Was not offered tea or coffee, very disappointing.'
GO

EXEC PatientAccess.AddPatientFeedback
@CompletedAppointmentID = 2,
	@Feedback = 'Doctor was very professional, appointment was quick and the prescribed medicine has reduced my symptoms..'
GO

EXEC PatientAccess.AddPatientFeedback
@CompletedAppointmentID = 3,
	@Feedback = 'Feel much better after appointment. Reception team made me feel very at ease and prescription has improved my symptoms.'
GO

EXEC PatientAccess.AddPatientFeedback
@CompletedAppointmentID = 5,
	@Feedback = 'Doctor was great but appointment was delayed by 45 minutes.'
GO

-- view CompletedAppointment table with added feedback
SELECT *
FROM Appointments.CompletedAppointment
GO

-- stored procedure for when patient leaves hospital system, to delete patient from Patient and move to ArchivedPatient
CREATE OR ALTER PROCEDURE HospitalInfo.PatientLeavesHospital
	@PatientID int,
	@PatientLeaveDate date
AS BEGIN
	INSERT INTO PatientInfo.ArchivedPatient (
		ArchivedPatientID,
		ArchivedPatientTitle,
		ArchivedPatientFirstName,
		ArchivedPatientMiddleName,
		ArchivedPatientLastName,
		ArchivedPatientDOB,
		ArchivedPatientAddressID,
		ArchivedPatientGender,
		ArchivedPatientMaritalStatus,
		ArchivedPatientEmail,
		ArchivedPatientTelNum,
		ArchivedPatientGPID,
		ArchivedPatientJoinDate,
		ArchivedPatientInsuranceProvider,
		ArchivedPatientInsuranceStartDate,
		ArchivedPatientInsuranceEndDate,
		ArchivedPatientInsuranceType,
		ArchivedPatientUsername,
		ArchivedPatientPasswordHash,
		ArchivedSalt,
		ArchivedPatientLeaveDate)
	SELECT PatientID,
					PatientTitle,
					PatientFirstName,
					PatientMiddleName,
					PatientLastName,
					PatientDOB,
					PatientAddressID,
					PatientGender,
					PatientMaritalStatus,
					PatientEmail,
					PatientTelNum,
					PatientGPID,
					PatientJoinDate,
					PatientInsuranceProvider,
					PatientInsuranceStartDate,
					PatientInsuranceEndDate,
					PatientInsuranceType,
					PatientUsername,
					PatientPasswordHash,
					Salt,
					@PatientLeaveDate
		FROM PatientInfo.Patient
		WHERE PatientID = @PatientID
	DELETE FROM PatientInfo.Patient
	WHERE PatientID = @PatientID
END
GO

-- view Patient details for PatientID = 2
SELECT * FROM PatientInfo.Patient WHERE PatientID = 2
GO

-- execute stored procedure for PatientID = 2 to leave hospital system
EXEC HospitalInfo.PatientLeavesHospital
	@PatientID = 2,
	@PatientLeaveDate = '2024-03-25'
GO

-- view Patient details for PatientID = 2 after stored procedure executed
SELECT * FROM PatientInfo.Patient WHERE PatientID = 2

-- view ArchivedPatient table after PatientID = 2 has left hospital system
SELECT * FROM PatientInfo.ArchivedPatient

-- question 3) list all patients older than 40 and have "cancer" in diagnosis
SELECT p.PatientID,
				p.PatientTitle,
				p.PatientFirstName + ' ' + ISNULL(p.PatientMiddleName + ' ', '') + p.PatientLastName AS PatientFullName,
				DATEDIFF(YY, p.PatientDOB, GETDATE()) AS PatientAge,
				c.ConditionName,
				c.ConditionCategory,
				m.MedicalRecordDiagnosisDate
FROM PatientInfo.Patient AS p
INNER JOIN PatientInfo.MedicalRecord AS m
ON p.PatientID = m.MedicalRecordPatientID
INNER JOIN MedicalInfo.Condition AS c
ON m.MedicalRecordConditionID = c.ConditionID
WHERE (DATEDIFF(YY, p.PatientDOB, GETDATE()) > 40) AND
				c.ConditionCategory LIKE '%cancer%'
GO

-- question 4a) function to search for medicine by string. results sorted by most recently prescribed medicine first
CREATE FUNCTION MedicalInfo.MedicineSearch
	(@MedicineSearchString AS nvarchar(100))
RETURNS TABLE AS
RETURN 
	(SELECT mr.MedicalRecordDiagnosisDate,
					m.MedicineName
	FROM PatientInfo.MedicalRecord AS mr
	INNER JOIN PatientInfo.Prescription AS p
	ON mr.MedicalRecordDiagnosisID = p.DiagnosisID
	INNER JOIN MedicalInfo.Medicine AS m
	ON p.MedicineID = m.MedicineID
	WHERE m.MedicineName LIKE '%' + @MedicineSearchString + '%'
	ORDER BY mr.MedicalRecordDiagnosisDate DESC OFFSET 0 ROWS)
GO

-- execute function for searching for medicine by character string
SELECT *
FROM MedicalInfo.MedicineSearch ('Chemo')
GO

SELECT *
FROM MedicalInfo.MedicineSearch ('Immo')
GO

-- question 4b) function to return full list of diagnosis and allergies for a specific patient who has an appointment on the day the query is run
CREATE OR ALTER PROCEDURE PatientInfo.ReturnDiagnosesAllergiesAppointmentToday
	@PatientID int
AS BEGIN
	IF @PatientID IN (SELECT AppointmentPatientID 
									FROM Appointments.Appointment 
									WHERE DATEPART(dd, AppointmentDateTime) = DATEPART(dd, GETDATE()))
		BEGIN
			SELECT p.PatientID,
						p.PatientFirstName + ' ' + ISNULL(p.PatientMiddleName + ' ', '') + p.PatientLastName AS PatientFullName,
						mr.MedicalRecordDiagnosisDate,
						c.ConditionName
			FROM PatientInfo.MedicalRecord AS mr
			INNER JOIN PatientInfo.Patient AS p
			ON mr.MedicalRecordPatientID = p.PatientID
			INNER JOIN MedicalInfo.Condition AS c
			ON c.ConditionID = mr.MedicalRecordConditionID
			WHERE mr.MedicalRecordPatientID = @PatientID

			SELECT	p.PatientID,
							p.PatientFirstName + ' ' + ISNULL(p.PatientMiddleName + ' ', '') + p.PatientLastName AS PatientFullName,
							al.AllergenName,
							a.Severity
			FROM PatientInfo.Allergy AS a
			INNER JOIN MedicalInfo.Allergen AS al
			ON al.AllergenID = a.AllergenID
			INNER JOIN PatientInfo.Patient AS p
			ON a.PatientID = p.PatientID
			WHERE a.PatientID = @PatientID
		END
	ELSE
		BEGIN
			PRINT 'This patient does not have an appointment today.'
		END
END
GO

-- create appointment for today's date at 16:45
DECLARE @CurrentDate date;
SET @CurrentDate = GETDATE()

EXEC PatientAccess.BookingAppointment
	@AppointmentPatientID = 6,
	@AppointmentDoctorID = 4,
	@AppointmentDate = @CurrentDate,
	@AppointmentTime = '16:45',
	@AppointmentPurpose = 'Heart problem'
GO

-- execute stored procedure to return list of diagnoses and allergies for patient who has an appointment today
EXEC PatientInfo.ReturnDiagnosesAllergiesAppointmentToday
	@PatientID = 6
GO

-- execute same stored procedure, with patient who does not have an appointment today
EXEC PatientInfo.ReturnDiagnosesAllergiesAppointmentToday
	@PatientID = 1
GO

-- question 4c) stored procedure to update details for an existing doctor
CREATE OR ALTER PROCEDURE Employee.UpdateDoctorDetails
	@DoctorID int = NULL,
	@DoctorTitle nvarchar(20) = NULL,
	@DoctorFirstName nvarchar(50) = NULL,
	@DoctorMiddleName nvarchar(50) = NULL,
	@DoctorLastName nvarchar(50) = NULL,
	@DoctorDOB date = NULL,
	@DoctorAddressID int = NULL,
	@DoctorGender nvarchar(20) = NULL,
	@DoctorMaritalStatus nvarchar(50) = NULL,
	@DoctorEmail nvarchar(200) = NULL,
	@DoctorTelNum nvarchar(20) = NULL,
	@EmploymentStartDate date = NULL,
	@EmploymentEndDate date = NULL,
	@Specialty nvarchar(100) = NULL,
	@DoctorDepartmentID int = NULL,
	@StartWorkHours time = NULL,
	@EndWorkHours time = NULL
AS BEGIN
	UPDATE Employee.Doctor
		SET DoctorTitle = ISNULL(@DoctorTitle, (SELECT DoctorTitle FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorFirstName = ISNULL(@DoctorFirstName, (SELECT DoctorFirstName FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorMiddleName = ISNULL(@DoctorMiddleName, (SELECT DoctorMiddleName FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorLastName = ISNULL(@DoctorLastName, (SELECT DoctorLastName FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorDOB = ISNULL(@DoctorDOB, (SELECT DoctorDOB FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorAddressID = ISNULL(@DoctorAddressID, (SELECT DoctorAddressID FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorGender = ISNULL(@DoctorGender, (SELECT DoctorGender FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorMaritalStatus = ISNULL(@DoctorMaritalStatus, (SELECT DoctorMaritalStatus FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorEmail = ISNULL(@DoctorEmail, (SELECT DoctorEmail FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorTelNum = ISNULL(@DoctorTelNum, (SELECT DoctorTelNum FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				EmploymentStartDate = ISNULL(@EmploymentStartDate, (SELECT EmploymentStartDate FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				EmploymentEndDate = ISNULL(@EmploymentEndDate, (SELECT EmploymentEndDate FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				Specialty = ISNULL(@Specialty, (SELECT Specialty FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				DoctorDepartmentID = ISNULL(@DoctorDepartmentID, (SELECT DoctorDepartmentID FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				StartWorkHours = ISNULL(@StartWorkHours, (SELECT StartWorkHours FROM Employee.Doctor WHERE DoctorID = @DoctorID)),
				EndWorkHours = ISNULL(@EndWorkHours, (SELECT EndWorkHours FROM Employee.Doctor WHERE DoctorID = @DoctorID))
		WHERE DoctorID = @DoctorID
END
GO

-- view Doctor details before update for DoctorID = 2
SELECT * 
FROM Employee.Doctor
WHERE DoctorID = 2
GO

-- execute stored procedure to update Doctor details for DoctorID = 2
EXEC Employee.UpdateDoctorDetails
	@DoctorID = 2,
	@DoctorLastName = 'Jones',
	@DoctorMaritalStatus = 'Married'
GO

-- view Doctor details after update for DoctorID = 2
SELECT * 
FROM Employee.Doctor
WHERE DoctorID = 2
GO

-- question 5) create view for appointment date and time, showing all previous and current appointments for all doctors, 
-- include details of doc's department, doc's specialty and any feedback given for a doc
CREATE OR ALTER VIEW HospitalInfo.v_AllAppointmentsWithFeedback (
	AppointmentDateTime, AppointmentStatus, DoctorFullName,
	DocSpecialty, DocDepartmentName, DepartmentTelNum,
	DepartmentEmail, PatientFeedback)
AS
SELECT a.AppointmentDateTime,
				a.AppointmentStatus,
				d.DoctorTitle + ' ' + d.DoctorFirstName + ' ' + ISNULL(d.DoctorMiddleName + ' ', '') + d.DoctorLastName,
				d.Specialty,
				de.DepartmentName + ', ' + de.BuildingName,
				de.DepartmentTelNum,
				de.DepartmentEmail,
				PatientFeedback = 'No feedback for pending or cancelled appointments'
FROM Appointments.Appointment AS a
INNER JOIN Employee.Doctor AS d
ON a.AppointmentDoctorID = d.DoctorID
INNER JOIN HospitalInfo.Department AS de
ON d.DoctorDepartmentID = de.DepartmentID
UNION 
SELECT c.CompletedAppointmentDateTime AS AppointmentDateTime,
				c.CompletedAppointmentStatus,
				d.DoctorTitle + ' ' + d.DoctorFirstName + ' ' + ISNULL(d.DoctorMiddleName + ' ', '') + d.DoctorLastName AS DoctorFullName,
				d.Specialty AS DocSpecialty,
				de.DepartmentName + ', ' + de.BuildingName AS DocDepartmentName,
				de.DepartmentTelNum,
				de.DepartmentEmail,
				c.PatientFeedback
FROM Appointments.CompletedAppointment AS c
INNER JOIN Employee.Doctor AS d
ON c.CompletedAppointmentDoctorID = d.DoctorID
INNER JOIN HospitalInfo.Department AS de
ON d.DoctorDepartmentID = de.DepartmentID
ORDER BY AppointmentDateTime OFFSET 0 ROWS
GO

-- view the AllAppointmentsWithFeedback view
SELECT *
FROM HospitalInfo.v_AllAppointmentsWithFeedback
GO

-- question 7) SELECT query to identify number of completed appointments with docs whose specialty is 'Gastroenterologist'
SELECT COUNT(*) AS NumberCompletedAppointmentsGastroDoc
FROM Appointments.CompletedAppointment AS c
INNER JOIN Employee.Doctor AS D
ON c.CompletedAppointmentDoctorID  = d.DoctorID
WHERE d.Specialty = 'Gastroenterologist'
GO

-- Question 8) database security - create roles to restrict access to unnecessary information for each user
CREATE ROLE HospitalAdministrator
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: Addresses TO HospitalAdministrator
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: HospitalInfo TO HospitalAdministrator
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: Appointments TO HospitalAdministrator
GRANT SELECT ON SCHEMA :: Employee TO HospitalAdministrator
GO

CREATE ROLE HospitalHR
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: Employee TO HospitalHR
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: Addresses TO HospitalHR
GO

CREATE ROLE Doctor
GRANT SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: MedicalInfo TO Doctor
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: PatientInfo TO Doctor
GRANT SELECT, UPDATE ON SCHEMA :: Appointments TO Doctor
GO

CREATE ROLE Patient
GRANT SELECT, INSERT ON SCHEMA :: PatientAccess TO Patient
GRANT SELECT ON MedicalInfo.Condition TO Patient
GRANT SELECT ON MedicalInfo.Medicine TO Patient
GRANT SELECT ON MedicalInfo.Allergen TO Patient
GO

-- create functions for Patients to view their own information only
-- Function for Patient to view own MedicalRecord and Presciptions. In production @PatientID would be set by the patient's login and lock the results to themselves only
CREATE OR ALTER FUNCTION PatientAccess.f_ReturnPatientMedicalRecord(
	@PatientID int)
RETURNS TABLE AS
RETURN (
	SELECT mr.MedicalRecordDiagnosisDate,
					c.ConditionName,
					c.ConditionCategory,
					m.MedicineName,
					p.Dosage,
					m.MedicineType,
					p.PrescriptionReviewDate
	FROM PatientInfo.MedicalRecord AS mr
	INNER JOIN MedicalInfo.Condition AS c
	ON mr.MedicalRecordConditionID = c.ConditionID
	INNER JOIN PatientInfo.Prescription AS p
	ON mr.MedicalRecordDiagnosisID = p.DiagnosisID
	INNER JOIN MedicalInfo.Medicine AS m
	ON p.MedicineID = m.MedicineID
	WHERE mr.MedicalRecordPatientID = @PatientID)
GO

-- execute function for Patient to view their own MedicalRecord only. In production @PatientID would be set by the patient's login and lock the results to themselves only
SELECT * 
FROM PatientAccess.f_ReturnPatientMedicalRecord(1)
GO

-- Function for Patient to view their own Allergies only. In production @PatientID would be set by the patient's login and lock the results to themselves only
CREATE OR ALTER FUNCTION PatientAccess.f_ReturnPatientAllergies(
	@PatientID int)
RETURNS TABLE AS
RETURN (
	SELECT al.AllergenName,
					a.Severity
	FROM PatientInfo.Allergy AS a
	INNER JOIN MedicalInfo.Allergen AS al
	ON a.AllergenID = al.AllergenID
	WHERE a.PatientID = @PatientID)
GO

-- execute function for Patient to view their own Allergies only. In production @PatientID would be set by the patient's login and lock the results to themselves only
SELECT *
FROM PatientAccess.f_ReturnPatientAllergies(1)
GO