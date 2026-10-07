/*=========================================================
  File : 09_Load_Fact_VLE.sql
=========================================================*/

USE oulad_dw;

INSERT INTO fact_student_vle
(
student_key,
course_key,
vle_key,
date_key,
sum_click
)

SELECT

ds.student_key,

dc.course_key,

dv.vle_key,

dd.date_key,

sv.sum_click

FROM oulad.studentVle sv

JOIN dim_student ds
ON ds.id_student=sv.id_student
AND ds.code_module=sv.code_module
AND ds.code_presentation=sv.code_presentation

JOIN dim_course dc
ON dc.code_module=sv.code_module
AND dc.code_presentation=sv.code_presentation

JOIN dim_vle dv
ON dv.id_site=sv.id_site
AND dv.code_module=sv.code_module
AND dv.code_presentation=sv.code_presentation

LEFT JOIN dim_date dd
ON dd.day_offset=sv.date;