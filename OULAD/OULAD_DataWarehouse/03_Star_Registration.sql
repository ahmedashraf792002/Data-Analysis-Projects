/*=========================================================
  Project : OULAD Data Warehouse
  File    : 03_Star_Registration.sql
  Purpose : Create Registration Fact Table
=========================================================*/

USE oulad_dw;

------------------------------------------------------------
-- Fact : Student Registration
-- Source : studentRegistration.csv
------------------------------------------------------------

CREATE TABLE fact_registration(

    registration_key INT AUTO_INCREMENT PRIMARY KEY,

    student_key INT NOT NULL,

    course_key INT NOT NULL,

    registration_day_key INT,

    unregistration_day_key INT,

    is_withdrawn BOOLEAN,

    FOREIGN KEY (student_key)
        REFERENCES dim_student(student_key),

    FOREIGN KEY (course_key)
        REFERENCES dim_course(course_key),

    FOREIGN KEY (registration_day_key)
        REFERENCES dim_date(date_key),

    FOREIGN KEY (unregistration_day_key)
        REFERENCES dim_date(date_key)

);