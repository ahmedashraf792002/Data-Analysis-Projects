/*=========================================================
  Project : OULAD Data Warehouse
  File    : 07_Load_Fact_Registration.sql
  Purpose : Load Registration Fact Table
=========================================================*/

USE oulad_dw;

------------------------------------------------------------
-- Load Fact : Student Registration
------------------------------------------------------------

INSERT INTO fact_registration
(
    student_key,
    course_key,
    registration_day_key,
    unregistration_day_key,
    is_withdrawn
)

SELECT

    ds.student_key,

    dc.course_key,

    dr.date_key,

    du.date_key,

    CASE
        WHEN ds.final_result = 'Withdrawn' THEN TRUE
        ELSE FALSE
    END AS is_withdrawn

FROM oulad.studentRegistration sr

JOIN dim_student ds
ON ds.id_student = sr.id_student
AND ds.code_module = sr.code_module
AND ds.code_presentation = sr.code_presentation

JOIN dim_course dc
ON dc.code_module = sr.code_module
AND dc.code_presentation = sr.code_presentation

LEFT JOIN dim_date dr
ON dr.day_offset = sr.date_registration

LEFT JOIN dim_date du
ON du.day_offset = sr.date_unregistration;