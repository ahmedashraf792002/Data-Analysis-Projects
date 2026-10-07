/*=========================================================
  Project : OULAD Data Warehouse
  File    : 02_Dimensions.sql
  Purpose : Create Dimension Tables
=========================================================*/

USE oulad_dw;

------------------------------------------------------------
-- Dimension : Student
-- Source : studentInfo.csv
------------------------------------------------------------

CREATE TABLE dim_student(

    student_key INT AUTO_INCREMENT PRIMARY KEY,

    id_student INT NOT NULL,

    code_module VARCHAR(10),

    code_presentation VARCHAR(10),

    gender CHAR(1),

    region VARCHAR(100),

    highest_education VARCHAR(100),

    imd_band VARCHAR(20),

    age_band VARCHAR(20),

    num_of_prev_attempts INT,

    studied_credits INT,

    disability CHAR(1),

    final_result VARCHAR(30)

);

------------------------------------------------------------
-- Dimension : Course
-- Source : courses.csv
------------------------------------------------------------

CREATE TABLE dim_course(

    course_key INT AUTO_INCREMENT PRIMARY KEY,

    code_module VARCHAR(10),

    code_presentation VARCHAR(10),

    module_presentation_length INT,

    UNIQUE(code_module, code_presentation)

);

------------------------------------------------------------
-- Dimension : Assessment
-- Source : assessments.csv
------------------------------------------------------------

CREATE TABLE dim_assessment(

    assessment_key INT AUTO_INCREMENT PRIMARY KEY,

    id_assessment INT,

    code_module VARCHAR(10),

    code_presentation VARCHAR(10),

    assessment_type VARCHAR(20),

    due_date_offset INT,

    weight DECIMAL(5,2),

    UNIQUE(id_assessment)

);

------------------------------------------------------------
-- Dimension : VLE
-- Source : vle.csv
------------------------------------------------------------

CREATE TABLE dim_vle(

    vle_key INT AUTO_INCREMENT PRIMARY KEY,

    id_site INT,

    code_module VARCHAR(10),

    code_presentation VARCHAR(10),

    activity_type VARCHAR(50),

    week_from INT,

    week_to INT,

    UNIQUE(id_site)

);

------------------------------------------------------------
-- Dimension : Date
-- Generated from:
-- assessments
-- studentRegistration
-- studentVle
------------------------------------------------------------

CREATE TABLE dim_date(

    date_key INT AUTO_INCREMENT PRIMARY KEY,

    day_offset INT UNIQUE,

    week_number INT,

    month_number INT,

    quarter_number INT,

    course_phase VARCHAR(20)

);