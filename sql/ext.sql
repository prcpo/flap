-- Schema: ext

-- DROP SCHEMA ext;

CREATE SCHEMA ext
--  AUTHORIZATION postgres
;

COMMENT ON SCHEMA ext
  IS 'Пакеты расширений устанавливаются сюда.';


CREATE EXTENSION ltree
   SCHEMA ext;
