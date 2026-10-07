/*=========================================================
  File : 08_Load_Fact_Assessment.sql
=========================================================*/

USE oulad_dw;
INSERT INTO fact_assessment
(
    student_key,
    course_key,
    assessment_key,
    submitted_day_key,
    score,
    is_banked,
    days_early_late
)

SELECT
    ds.student_key,
    dc.course_key,
    da.assessment_key,
    dd.date_key,
    sa.score,
    sa.is_banked,
    sa.date_submitted - a.date

FROM oulad.studentAssessment sa

JOIN oulad.assessments a
ON sa.id_assessment = a.id_assessment

JOIN oulad.studentInfo si
ON sa.id_student = si.id_student
AND si.code_module = a.code_module
AND si.code_presentation = a.code_presentation

JOIN dim_student ds
ON ds.id_student = si.id_student
AND ds.code_module = si.code_module
AND ds.code_presentation = si.code_presentation

JOIN dim_course dc
ON dc.code_module = si.code_module
AND dc.code_presentation = si.code_presentation

JOIN dim_assessment da
ON da.id_assessment = a.id_assessment

LEFT JOIN dim_date dd
ON dd.day_offset = sa.date_submitted;