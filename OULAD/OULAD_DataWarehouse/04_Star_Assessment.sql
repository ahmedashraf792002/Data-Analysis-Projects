/*=========================================================
  Project : OULAD Data Warehouse
  File    : 04_Star_Assessment.sql
  Purpose : Create Assessment Fact Table
=========================================================*/

USE oulad_dw;

------------------------------------------------------------
-- Fact : Student Assessment
-- Source : studentAssessment.csv
------------------------------------------------------------

CREATE TABLE fact_assessment(

    assessment_result_key INT AUTO_INCREMENT PRIMARY KEY,

    student_key INT NOT NULL,

    course_key INT NOT NULL,

    assessment_key INT NOT NULL,

    submitted_day_key INT,

    score DECIMAL(5,2),

    is_banked BOOLEAN,

    days_early_late INT,

    FOREIGN KEY(student_key)
        REFERENCES dim_student(student_key),

    FOREIGN KEY(course_key)
        REFERENCES dim_course(course_key),

    FOREIGN KEY(assessment_key)
        REFERENCES dim_assessment(assessment_key),

    FOREIGN KEY(submitted_day_key)
        REFERENCES dim_date(date_key)

);