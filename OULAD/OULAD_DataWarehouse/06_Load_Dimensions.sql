/*=========================================================
  Project : OULAD Data Warehouse
  File    : 06_Load_Dimensions.sql
  Purpose : Load Dimension Tables
=========================================================*/

USE oulad_dw;

-- =========================================================
-- Load Student Dimension
-- Source : oulad.studentInfo
-- =========================================================

INSERT INTO dim_student
(
    id_student,
    code_module,
    code_presentation,
    gender,
    region,
    highest_education,
    imd_band,
    age_band,
    num_of_prev_attempts,
    studied_credits,
    disability,
    final_result
)

SELECT DISTINCT

    id_student,
    code_module,
    code_presentation,
    gender,
    region,
    highest_education,
    imd_band,
    age_band,
    num_of_prev_attempts,
    studied_credits,
    disability,
    final_result

FROM oulad.studentinfo;


-- =========================================================
-- Load Course Dimension
-- Source : oulad.courses
-- =========================================================

INSERT INTO dim_course
(
    code_module,
    code_presentation,
    module_presentation_length
)

SELECT DISTINCT

    code_module,
    code_presentation,
    module_presentation_length

FROM oulad.courses;


-- =========================================================
-- Load Assessment Dimension
-- Source : oulad.assessments
-- =========================================================

INSERT INTO dim_assessment
(
    id_assessment,
    code_module,
    code_presentation,
    assessment_type,
    due_date_offset,
    weight
)

SELECT DISTINCT

    id_assessment,
    code_module,
    code_presentation,
    assessment_type,
    NULLIF(date,''),
    weight

FROM oulad.assessments;


-- =========================================================
-- Load VLE Dimension
-- Source : oulad.vle
-- =========================================================

INSERT INTO dim_vle
(
    id_site,
    code_module,
    code_presentation,
    activity_type,
    week_from,
    week_to
)

SELECT DISTINCT

    id_site,
    code_module,
    code_presentation,
    activity_type,
    NULLIF(week_from,''),
    NULLIF(week_to,'')

FROM oulad.vle;


-- =========================================================
-- Load Date Dimension
-- Source :
-- assessments
-- studentRegistration
-- studentVle
-- =========================================================

INSERT INTO dim_date
(
    day_offset,
    week_number,
    month_number,
    quarter_number,
    course_phase
)

SELECT

    day_offset,

    FLOOR(day_offset/7)+1,

    FLOOR(day_offset/30)+1,

    FLOOR(day_offset/90)+1,

    CASE
        WHEN day_offset < 0 THEN 'Pre-Course'
        WHEN day_offset BETWEEN 0 AND 30 THEN 'Early'
        WHEN day_offset BETWEEN 31 AND 90 THEN 'Middle'
        ELSE 'Late'
    END

FROM
(

    SELECT DISTINCT NULLIF(date,'') AS day_offset
    FROM oulad.assessments

    UNION

    SELECT DISTINCT NULLIF(date_registration,'')
    FROM oulad.studentregistration

    UNION

    SELECT DISTINCT NULLIF(date_unregistration,'')
    FROM oulad.studentregistration

    UNION

    SELECT DISTINCT NULLIF(date,'')
    FROM oulad.studentvle

) d

WHERE day_offset IS NOT NULL

ORDER BY day_offset;


-- =========================================================
-- Verify Data
-- =========================================================

SELECT COUNT(*) AS Students FROM dim_student;

SELECT COUNT(*) AS Courses FROM dim_course;

SELECT COUNT(*) AS Assessments FROM dim_assessment;

SELECT COUNT(*) AS VLE FROM dim_vle;

SELECT COUNT(*) AS Dates FROM dim_date;