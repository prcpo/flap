SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA s_uk;
COMMENT ON SCHEMA s_uk IS 'Схема "Управляющая компания ЖКХ"';
SET search_path = s_uk, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE c_staff_person (
    person uuid NOT NULL,
    "position" uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL
);
CREATE TABLE dic_buildings (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    parent uuid,
    note text
);
COMMENT ON TABLE dic_buildings IS 'Здания, сооружения';
COMMENT ON COLUMN dic_buildings.disp IS 'Адрес';
COMMENT ON COLUMN dic_buildings.period IS 'Период';
CREATE TABLE dic_companies (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    disp text,
    parent uuid,
    note text
);
COMMENT ON TABLE dic_companies IS 'Организации';
CREATE TABLE dic_contracts (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    period daterange,
    service uuid NOT NULL,
    building uuid NOT NULL,
    cnt numeric DEFAULT 0 NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    company uuid
);
CREATE TABLE dic_payrates (
    "position" uuid NOT NULL,
    amount numeric DEFAULT 0 NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    type text NOT NULL
);
COMMENT ON TABLE dic_payrates IS 'Ставки ЗП';
CREATE TABLE dic_personnel (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text
);
CREATE TABLE dic_plots (
    person uuid NOT NULL,
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL
);
CREATE TABLE dic_positions (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text
);
CREATE TABLE dic_services (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    disp text NOT NULL,
    note text,
    parent uuid
);
CREATE TABLE dic_staffing (
    comp uuid DEFAULT set.company_get() NOT NULL,
    department uuid NOT NULL,
    "position" uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    count integer DEFAULT 1 NOT NULL
);
CREATE TABLE dic_tariffs (
    work uuid NOT NULL,
    amount numeric,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL
);
CREATE TABLE dic_works (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text,
    unit text,
    parent uuid,
    note text
);
CREATE TABLE r_building_props (
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    props json
);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT pk_buildings PRIMARY KEY (uuid);
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT pk_c_staff_person PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_contracts
    ADD CONSTRAINT pk_dic_contracts PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_services
    ADD CONSTRAINT pk_dic_services PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_payrates
    ADD CONSTRAINT pk_payrates PRIMARY KEY ("position", amount, period, type);
ALTER TABLE ONLY dic_personnel
    ADD CONSTRAINT pk_personnel PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_plots
    ADD CONSTRAINT pk_plots PRIMARY KEY (person, building, period);
ALTER TABLE ONLY dic_positions
    ADD CONSTRAINT pk_positions PRIMARY KEY (uuid);
ALTER TABLE ONLY r_building_props
    ADD CONSTRAINT pk_r_building_props PRIMARY KEY (building, period);
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT pk_staffing PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_works
    ADD CONSTRAINT pk_works PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT uk_buildings_disp UNIQUE (disp, period);
CREATE INDEX fki_buildings_parent ON dic_buildings USING btree (parent);
CREATE INDEX fki_c_staff_person_position ON c_staff_person USING btree ("position");
CREATE INDEX fki_dic_contracts_building ON dic_contracts USING btree (building);
CREATE INDEX fki_dic_contracts_company ON dic_contracts USING btree (company);
CREATE INDEX fki_dic_contracts_work ON dic_contracts USING btree (service);
CREATE INDEX fki_plots_buildings ON dic_plots USING btree (building);
CREATE INDEX fki_staffing_department ON dic_staffing USING btree (department);
CREATE INDEX fki_staffing_position ON dic_staffing USING btree ("position");
CREATE INDEX fki_works_parent ON dic_works USING btree (parent);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT fk_buildings_parent FOREIGN KEY (parent) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_person FOREIGN KEY (person) REFERENCES dic_personnel(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_position FOREIGN KEY ("position") REFERENCES dic_staffing(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY dic_companies
    ADD CONSTRAINT fk_companies_parent FOREIGN KEY (parent) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_contracts
    ADD CONSTRAINT fk_dic_contracts_building FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_contracts
    ADD CONSTRAINT fk_dic_contracts_company FOREIGN KEY (company) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_contracts
    ADD CONSTRAINT fk_dic_contracts_service FOREIGN KEY (service) REFERENCES dic_services(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_plots
    ADD CONSTRAINT fk_plots_buildings FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_plots
    ADD CONSTRAINT fk_plots_person FOREIGN KEY (person) REFERENCES c_staff_person(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY r_building_props
    ADD CONSTRAINT fk_r_building_props_building FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_comp FOREIGN KEY (comp) REFERENCES sec.companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_department FOREIGN KEY (department) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_position FOREIGN KEY ("position") REFERENCES dic_positions(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_works
    ADD CONSTRAINT fk_works_parent FOREIGN KEY (parent) REFERENCES dic_works(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
