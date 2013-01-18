SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA obj;
COMMENT ON SCHEMA obj IS 'Объекты системы.
Документы, справочники, журналы, отчёты длительного хранения.';
SET search_path = obj, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE raw (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT def.company_get(),
    data json
);
COMMENT ON TABLE raw IS 'Ненормализованные данные';
COMMENT ON COLUMN raw.uuid IS 'Идентификатор объекта';
COMMENT ON COLUMN raw.comp IS 'Организация';
COMMENT ON COLUMN raw.data IS 'Содержимое объекта';
ALTER TABLE ONLY raw
    ADD CONSTRAINT pk_raw PRIMARY KEY (uuid);
