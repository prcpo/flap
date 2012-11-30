-- Database: accounting

--DROP DATABASE test;

CREATE DATABASE test
--  WITH OWNER = postgres
--       ENCODING = 'UTF8'
--       TABLESPACE = pg_default
--       LC_COLLATE = 'ru_RU.UTF-8'
--       LC_CTYPE = 'ru_RU.UTF-8'
--       CONNECTION LIMIT = -1
;

ALTER DATABASE test
  SET search_path = public, ext, tools;

COMMENT ON DATABASE test
  IS 'Свободная учётная система с полностью открытым кодом.';
