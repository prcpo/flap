SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA s_uk;
COMMENT ON SCHEMA s_uk IS 'Нормализованные данные';
SET search_path = s_uk, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE building_props (
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    props json
);
CREATE TABLE buildings (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    parent uuid
);
COMMENT ON TABLE buildings IS 'Здания, сооружения';
COMMENT ON COLUMN buildings.disp IS 'Адрес';
COMMENT ON COLUMN buildings.period IS 'Период';
CREATE TABLE c_staff_person (
    person uuid NOT NULL,
    "position" uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL
);
CREATE TABLE contracts (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    period daterange,
    work uuid NOT NULL
);
CREATE TABLE departments (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    disp text,
    parent uuid
);
COMMENT ON TABLE departments IS 'Подразделения';
CREATE TABLE payrates (
    "position" uuid NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    type text NOT NULL
);
COMMENT ON TABLE payrates IS 'Ставки ЗП';
CREATE TABLE personnel (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text
);
CREATE TABLE plots (
    person uuid NOT NULL,
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL
);
CREATE TABLE positions (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text
);
CREATE TABLE staffing (
    comp uuid DEFAULT set.company_get() NOT NULL,
    department uuid NOT NULL,
    "position" uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    count integer DEFAULT 1 NOT NULL
);
CREATE TABLE tariffs (
    work uuid NOT NULL,
    amount numeric,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL
);
CREATE TABLE works (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text,
    unit text,
    parent uuid
);
ALTER TABLE ONLY building_props
    ADD CONSTRAINT pk_building_props PRIMARY KEY (building, period);
ALTER TABLE ONLY buildings
    ADD CONSTRAINT pk_buildings PRIMARY KEY (uuid);
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT pk_c_staff_person PRIMARY KEY (uuid);
ALTER TABLE ONLY departments
    ADD CONSTRAINT pk_departments PRIMARY KEY (uuid);
ALTER TABLE ONLY payrates
    ADD CONSTRAINT pk_payrates PRIMARY KEY ("position", amount, period, type);
ALTER TABLE ONLY personnel
    ADD CONSTRAINT pk_personnel PRIMARY KEY (uuid);
ALTER TABLE ONLY plots
    ADD CONSTRAINT pk_plots PRIMARY KEY (person, building, period);
ALTER TABLE ONLY positions
    ADD CONSTRAINT pk_positions PRIMARY KEY (uuid);
ALTER TABLE ONLY staffing
    ADD CONSTRAINT pk_staffing PRIMARY KEY (uuid);
ALTER TABLE ONLY works
    ADD CONSTRAINT pk_works PRIMARY KEY (uuid);
ALTER TABLE ONLY buildings
    ADD CONSTRAINT uk_buildings_disp UNIQUE (disp, period);
CREATE INDEX fki_buildings_parent ON buildings USING btree (parent);
CREATE INDEX fki_c_staff_person_position ON c_staff_person USING btree ("position");
CREATE INDEX fki_plots_buildings ON plots USING btree (building);
CREATE INDEX fki_staffing_department ON staffing USING btree (department);
CREATE INDEX fki_staffing_position ON staffing USING btree ("position");
CREATE INDEX fki_works_parent ON works USING btree (parent);
ALTER TABLE ONLY building_props
    ADD CONSTRAINT fk_building_props_building FOREIGN KEY (building) REFERENCES buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY buildings
    ADD CONSTRAINT fk_buildings_parent FOREIGN KEY (parent) REFERENCES buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_person FOREIGN KEY (person) REFERENCES personnel(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_position FOREIGN KEY ("position") REFERENCES staffing(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY departments
    ADD CONSTRAINT fk_departments_parent FOREIGN KEY (parent) REFERENCES departments(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY plots
    ADD CONSTRAINT fk_plots_buildings FOREIGN KEY (building) REFERENCES buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY plots
    ADD CONSTRAINT fk_plots_person FOREIGN KEY (person) REFERENCES c_staff_person(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY staffing
    ADD CONSTRAINT fk_staffing_comp FOREIGN KEY (comp) REFERENCES sec.companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY staffing
    ADD CONSTRAINT fk_staffing_department FOREIGN KEY (department) REFERENCES departments(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY staffing
    ADD CONSTRAINT fk_staffing_position FOREIGN KEY ("position") REFERENCES positions(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY works
    ADD CONSTRAINT fk_works_parent FOREIGN KEY (parent) REFERENCES works(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
