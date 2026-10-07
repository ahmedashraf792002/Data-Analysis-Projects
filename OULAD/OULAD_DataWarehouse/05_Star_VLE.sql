/*=========================================================
  Project : OULAD Data Warehouse
  File    : 05_Star_VLE.sql
  Purpose : Create Student VLE Fact Table
=========================================================*/

USE oulad_dw;

------------------------------------------------------------
-- Fact : Student VLE Interaction
-- Source : studentVle.csv
------------------------------------------------------------

CREATE TABLE fact_student_vle(

    vle_interaction_key BIGINT AUTO_INCREMENT PRIMARY KEY,

    student_key INT NOT NULL,

    course_key INT NOT NULL,

    vle_key INT NOT NULL,

    date_key INT NOT NULL,

    sum_click INT,

    FOREIGN KEY(student_key)
        REFERENCES dim_student(student_key),

    FOREIGN KEY(course_key)
        REFERENCES dim_course(course_key),

    FOREIGN KEY(vle_key)
        REFERENCES dim_vle(vle_key),

    FOREIGN KEY(date_key)
        REFERENCES dim_date(date_key)

);

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX idx_reg_student
ON fact_registration(student_key);

CREATE INDEX idx_reg_course
ON fact_registration(course_key);

CREATE INDEX idx_assessment_student
ON fact_assessment(student_key);

CREATE INDEX idx_assessment_course
ON fact_assessment(course_key);

CREATE INDEX idx_vle_student
ON fact_student_vle(student_key);

CREATE INDEX idx_vle_course
ON fact_student_vle(course_key);

CREATE INDEX idx_vle_date
ON fact_student_vle(date_key);