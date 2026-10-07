/*=========================================================
  Project : OULAD Data Warehouse
  File    : 10_Analysis_Queries.sql
  Purpose : Business Analysis Queries
=========================================================*/
USE oulad_dw;

------------------------------------------------------------
-- 1. Total Students
------------------------------------------------------------

SELECT COUNT(*) AS Total_Students
FROM dim_student;

------------------------------------------------------------
-- 2. Total Courses
------------------------------------------------------------

SELECT COUNT(*) AS Total_Courses
FROM dim_course;

------------------------------------------------------------
-- 3. Students by Gender
------------------------------------------------------------

SELECT
    gender,
    COUNT(*) AS Total_Students
FROM dim_student
GROUP BY gender;

------------------------------------------------------------
-- 4. Students by Region
------------------------------------------------------------

SELECT
    region,
    COUNT(*) AS Total_Students
FROM dim_student
GROUP BY region
ORDER BY Total_Students DESC;

------------------------------------------------------------
-- 5. Students by Final Result
------------------------------------------------------------

SELECT
    final_result,
    COUNT(*) AS Total_Students
FROM dim_student
GROUP BY final_result;

------------------------------------------------------------
-- 6. Average Assessment Score
------------------------------------------------------------

SELECT
    ROUND(AVG(score),2) AS Average_Score
FROM fact_assessment;

------------------------------------------------------------
-- 7. Highest  and Lowest Assessment Score
------------------------------------------------------------

SELECT
    MAX(score) AS Highest_Score , MIN(score) AS Lowest_Score
FROM fact_assessment;

------------------------------------------------------------
-- 8. Average Score by Course
------------------------------------------------------------

SELECT

    c.code_module,

    c.code_presentation,

    ROUND(AVG(f.score),2) AS Average_Score

FROM fact_assessment f

JOIN dim_course c
ON f.course_key = c.course_key

GROUP BY
c.code_module,
c.code_presentation

ORDER BY Average_Score DESC;

------------------------------------------------------------
-- 9. Top 10 Students by Score
------------------------------------------------------------

SELECT

    s.id_student,

    MAX(f.score) AS Highest_Score

FROM fact_assessment f

JOIN dim_student s
ON f.student_key = s.student_key

GROUP BY s.id_student

ORDER BY Highest_Score DESC

LIMIT 10;

------------------------------------------------------------
-- 10. Total Clicks by Course
------------------------------------------------------------

SELECT

    c.code_module,

    SUM(v.sum_click) AS Total_Clicks

FROM fact_student_vle v

JOIN dim_course c
ON v.course_key = c.course_key

GROUP BY c.code_module

ORDER BY Total_Clicks DESC;

------------------------------------------------------------
-- 11. Top 10 Active Students
------------------------------------------------------------

SELECT

    s.id_student,

    SUM(v.sum_click) AS Total_Clicks

FROM fact_student_vle v

JOIN dim_student s
ON v.student_key = s.student_key

GROUP BY s.id_student

ORDER BY Total_Clicks DESC

LIMIT 10;

------------------------------------------------------------
-- 12. Total Withdrawn Students
------------------------------------------------------------

SELECT

COUNT(*) AS Withdrawn_Students

FROM fact_registration

WHERE is_withdrawn = 1;

------------------------------------------------------------
-- 13. Average Studied Credits
------------------------------------------------------------

SELECT

ROUND(AVG(studied_credits),2) AS Average_Credits

FROM dim_student;

------------------------------------------------------------
-- 14. Students by Education Level
------------------------------------------------------------

SELECT

highest_education,

COUNT(*) AS Total_Students

FROM dim_student

GROUP BY highest_education

ORDER BY Total_Students DESC;

------------------------------------------------------------
-- 15. Average Score by Education Level
------------------------------------------------------------

SELECT

s.highest_education,

ROUND(AVG(f.score),2) AS Average_Score

FROM fact_assessment f

JOIN dim_student s
ON f.student_key=s.student_key

GROUP BY s.highest_education

ORDER BY Average_Score DESC;

------------------------------------------------------------
-- 16. Students with Distinction
------------------------------------------------------------

SELECT

COUNT(*) AS Distinction_Students

FROM dim_student

WHERE final_result='Distinction';

------------------------------------------------------------
-- 17. Students with Pass
------------------------------------------------------------

SELECT

COUNT(*) AS Passed_Students

FROM dim_student

WHERE final_result='Pass';

------------------------------------------------------------
-- 18. Students with Fail
------------------------------------------------------------

SELECT

COUNT(*) AS Failed_Students

FROM dim_student

WHERE final_result='Fail';

------------------------------------------------------------
-- 19. Students with Disability
------------------------------------------------------------

SELECT

disability,

COUNT(*) AS Total_Students

FROM dim_student

GROUP BY disability;

------------------------------------------------------------
-- 20. Average Score by Gender
------------------------------------------------------------

SELECT

    s.gender,

    ROUND(AVG(f.score),2) AS Average_Score

FROM fact_assessment f

JOIN dim_student s
ON f.student_key = s.student_key

GROUP BY s.gender;

------------------------------------------------------------
-- 21. Average Score by Age Band
------------------------------------------------------------

SELECT

    s.age_band,

    ROUND(AVG(f.score),2) AS Average_Score

FROM fact_assessment f

JOIN dim_student s
ON f.student_key = s.student_key

GROUP BY s.age_band

ORDER BY Average_Score DESC;

------------------------------------------------------------
-- 23. Average Score by Assessment Type
------------------------------------------------------------

SELECT

    a.assessment_type,

    ROUND(AVG(f.score),2) AS Average_Score

FROM fact_assessment f

JOIN dim_assessment a
ON f.assessment_key = a.assessment_key

GROUP BY a.assessment_type

ORDER BY Average_Score DESC;

------------------------------------------------------------
-- 24. Early vs Late Submission
------------------------------------------------------------

SELECT

CASE

WHEN days_early_late < 0 THEN 'Early'

WHEN days_early_late = 0 THEN 'On Time'

ELSE 'Late'

END AS Submission_Status,

COUNT(*) AS Total_Submissions,

ROUND(AVG(score),2) AS Average_Score

FROM fact_assessment

GROUP BY Submission_Status;

------------------------------------------------------------
-- 25. Top 10 Most Used VLE Activities
------------------------------------------------------------

SELECT

    v.activity_type,

    SUM(f.sum_click) AS Total_Clicks

FROM fact_student_vle f

JOIN dim_vle v
ON f.vle_key = v.vle_key

GROUP BY v.activity_type

ORDER BY Total_Clicks DESC

LIMIT 10;

------------------------------------------------------------
-- 26. Students by Age Band
------------------------------------------------------------

SELECT

    age_band,

    COUNT(*) AS Total_Students

FROM dim_student

GROUP BY age_band

ORDER BY Total_Students DESC;

------------------------------------------------------------
-- 27. Average Clicks per Student
------------------------------------------------------------

SELECT

    ROUND(AVG(Total_Clicks),2) AS Average_Clicks

FROM
(
    SELECT

        student_key,

        SUM(sum_click) AS Total_Clicks

    FROM fact_student_vle

    GROUP BY student_key

) t;

------------------------------------------------------------
-- 28. Top 10 Courses by Average Clicks
------------------------------------------------------------

SELECT

    c.code_module,

    c.code_presentation,

    ROUND(AVG(v.sum_click),2) AS Average_Clicks

FROM fact_student_vle v

JOIN dim_course c
ON v.course_key = c.course_key

GROUP BY c.code_module, c.code_presentation

ORDER BY Average_Clicks DESC

LIMIT 10;

------------------------------------------------------------
-- 29. Score Distribution
------------------------------------------------------------

SELECT

CASE

WHEN score >= 85 THEN 'Excellent'

WHEN score >= 70 THEN 'Very Good'

WHEN score >= 50 THEN 'Pass'

ELSE 'Fail'

END AS Grade,

COUNT(*) AS Total

FROM fact_assessment

GROUP BY Grade;

------------------------------------------------------------
-- 30. Top 10 Students by Average Score
------------------------------------------------------------

SELECT

    s.id_student,

    ROUND(AVG(f.score),2) AS Average_Score,

    COUNT(*) AS Assessments

FROM fact_assessment f

JOIN dim_student s
ON f.student_key = s.student_key

GROUP BY s.id_student

HAVING COUNT(*) >= 5

ORDER BY Average_Score DESC

LIMIT 10;