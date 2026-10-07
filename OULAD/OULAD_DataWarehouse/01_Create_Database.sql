/*=========================================================
  Project : OULAD Data Warehouse
  File    : 01_Create_Database.sql
  Purpose : Create Data Warehouse Schema
=========================================================*/

-- Remove old warehouse if it exists
DROP DATABASE IF EXISTS oulad_dw;

-- Create Data Warehouse
CREATE DATABASE oulad_dw;

-- Use the warehouse
USE oulad_dw;