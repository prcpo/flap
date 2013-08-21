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
CREATE VIEW buildings_hlist AS
 WITH RECURSIVE t(uuid, parent, disp, path, disp_path, level, cycle) AS (
                 SELECT t1.uuid, 
                    t1.parent, 
                    t1.disp, 
                    ARRAY[t1.uuid] AS "array", 
                    ARRAY[t1.disp] AS "array", 
                    1, 
                    false AS bool
                   FROM dic_buildings t1
                  WHERE (t1.parent IS NULL)
        UNION ALL 
                 SELECT t2.uuid, 
                    t2.parent, 
                    t2.disp, 
                    (t_1.path || t2.uuid), 
                    (t_1.disp_path || t2.disp), 
                    (t_1.level + 1), 
                    (t2.uuid = ANY (t_1.path))
                   FROM (dic_buildings t2
              JOIN t t_1 ON (((t_1.uuid = t2.parent) AND (NOT t_1.cycle))))
        )
 SELECT t.uuid, 
    t.parent, 
    t.disp, 
    t.path, 
    t.disp_path, 
    t.level, 
    t.cycle
   FROM t
  ORDER BY t.path;
CREATE TABLE c_staff_person (
    person uuid NOT NULL,
    "position" uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL
);
COMMENT ON TABLE c_staff_person IS 'Должности, занимаемые сотрудниками';
CREATE TABLE dic_companies (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    disp text,
    parent uuid,
    note text
);
COMMENT ON TABLE dic_companies IS 'Организации, подразделения';
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
COMMENT ON TABLE dic_personnel IS 'Сотрудники, физические лица';
CREATE TABLE dic_plots (
    person uuid NOT NULL,
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL
);
COMMENT ON TABLE dic_plots IS 'Территория, закреплённая за сотрудником';
CREATE TABLE dic_positions (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text
);
COMMENT ON TABLE dic_positions IS 'Должности';
CREATE TABLE dic_services (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    disp text NOT NULL,
    note text,
    parent uuid
);
COMMENT ON TABLE dic_services IS 'Услуги';
CREATE TABLE dic_staffing (
    comp uuid DEFAULT set.company_get() NOT NULL,
    company uuid,
    "position" uuid,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    seq integer DEFAULT 1 NOT NULL,
    note text
);
COMMENT ON TABLE dic_staffing IS 'Штатное расписание';
CREATE TABLE dic_tariffs (
    work uuid NOT NULL,
    amount numeric,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    unity name
);
COMMENT ON TABLE dic_tariffs IS 'Тариф за выполнение единицы работы';
CREATE TABLE dic_works (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    disp text,
    unit text,
    parent uuid,
    note text
);
CREATE TABLE doc_contracts (
    uuid uuid DEFAULT tools.uuid_generate_v4() NOT NULL,
    period daterange,
    service uuid NOT NULL,
    building uuid NOT NULL,
    company uuid
);
COMMENT ON TABLE doc_contracts IS 'Закрепление обслуживающих организации за домами';
CREATE TABLE doc_work_execution (
    id integer NOT NULL,
    work uuid,
    building uuid,
    person uuid,
    amount numeric,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL
);
CREATE SEQUENCE doc_work_execution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE doc_work_execution_id_seq OWNED BY doc_work_execution.id;
CREATE VIEW staffing AS
 SELECT s.uuid, 
    s."position", 
    p.disp AS position_disp, 
    s.company
   FROM dic_staffing s, 
    dic_positions p
  WHERE ((s."position" = p.uuid) AND (s.comp = set.company_get()));
CREATE VIEW personnel AS
 SELECT sp.person, 
    p.disp AS person_disp, 
    s."position", 
    s.position_disp, 
    sp."position" AS staff_position, 
    s.company
   FROM c_staff_person sp, 
    staffing s, 
    dic_personnel p
  WHERE ((s.uuid = sp."position") AND (p.uuid = sp.person));
CREATE TABLE r_building_props (
    building uuid NOT NULL,
    period daterange DEFAULT '[-infinity,infinity)'::daterange NOT NULL,
    props json
);
CREATE TABLE r_contract_works (
    id integer NOT NULL,
    comp uuid DEFAULT set.company_get() NOT NULL,
    contract uuid,
    work uuid,
    amount numeric,
    amount_interval interval,
    period daterange,
    service uuid
);
CREATE SEQUENCE r_contract_works_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE r_contract_works_id_seq OWNED BY r_contract_works.id;
CREATE VIEW services_hlist AS
 WITH RECURSIVE t(uuid, parent, disp, path, disp_path, level, cycle) AS (
                 SELECT t1.uuid, 
                    t1.parent, 
                    t1.disp, 
                    ARRAY[t1.uuid] AS "array", 
                    ARRAY[t1.disp] AS "array", 
                    1, 
                    false AS bool
                   FROM dic_services t1
                  WHERE ((t1.parent IS NULL) AND (t1.comp = set.company_get()))
        UNION ALL 
                 SELECT t2.uuid, 
                    t2.parent, 
                    t2.disp, 
                    (t_1.path || t2.uuid), 
                    (t_1.disp_path || t2.disp), 
                    (t_1.level + 1), 
                    (t2.uuid = ANY (t_1.path))
                   FROM (dic_services t2
              JOIN t t_1 ON ((((t_1.uuid = t2.parent) AND (t2.comp = set.company_get())) AND (NOT t_1.cycle))))
        )
 SELECT t.uuid, 
    t.parent, 
    t.disp, 
    t.path, 
    t.disp_path, 
    t.level, 
    t.cycle
   FROM t
  ORDER BY t.path;
CREATE VIEW services_ids_complete AS
 WITH s3 AS (
         WITH s2 AS (
                 WITH s1 AS (
                         WITH s AS (
                                 SELECT services_hlist.uuid, 
                                    services_hlist.path
                                   FROM services_hlist
                                )
                         SELECT s_1.uuid, 
                            s_1.path, 
                            t.l, 
                            s_1.path[t.l] AS service
                           FROM ( SELECT s_2.uuid, 
                                    generate_subscripts(s_2.path, 1) AS l
                                   FROM s s_2) t, 
                            s s_1
                          WHERE (s_1.uuid = t.uuid)
                        )
                 SELECT b.uuid AS building, 
                    s.uuid AS service, 
                    s.path, 
                    s1.l, 
                    s1.service AS lservice
                   FROM buildings_hlist b, 
                    services_hlist s, 
                    s1
                  WHERE (s.uuid = s1.uuid)
                )
         SELECT s2.building, 
            s2.service, 
            s2.path, 
            s2.l, 
            s2.lservice, 
            c.company
           FROM (s2
      LEFT JOIN doc_contracts c ON (((c.building = s2.building) AND (c.service = s2.lservice))))
     WHERE (NOT (c.company IS NULL))
        )
 SELECT so.building, 
    so.service, 
    so.company
   FROM ( SELECT s3.building, 
            s3.service, 
            max(s3.l) AS l
           FROM (s3
      LEFT JOIN doc_contracts c ON (((c.building = s3.building) AND (c.service = s3.lservice))))
     WHERE (NOT (c.company IS NULL))
     GROUP BY s3.building, s3.service) sc, 
    s3 so
  WHERE (((sc.building = so.building) AND (sc.service = so.service)) AND (sc.l = so.l));
COMMENT ON VIEW services_ids_complete IS 'Все услуги по домам и указанием организаций. Только ID!';
CREATE VIEW services AS
 SELECT sc.building, 
    b.disp AS building_disp, 
    b.path AS building_path, 
    b.disp_path AS building_disp_path, 
    sc.service, 
    s.disp AS service_disp, 
    s.path AS service_path, 
    s.disp_path AS service_disp_path, 
    sc.company, 
    c.disp AS company_disp
   FROM services_ids_complete sc, 
    services_hlist s, 
    buildings_hlist b, 
    dic_companies c
  WHERE (((sc.building = b.uuid) AND (sc.service = s.uuid)) AND (sc.company = c.uuid));
COMMENT ON VIEW services IS 'Все услуги по домам и указанием организаций.';
CREATE VIEW services_specified AS
 SELECT cn.uuid AS contract, 
    cn.building, 
    b.disp AS building_disp, 
    cn.service, 
    s.disp AS service_disp, 
    cn.company, 
    c.disp AS company_disp
   FROM doc_contracts cn, 
    dic_buildings b, 
    dic_services s, 
    dic_companies c
  WHERE (((cn.service = s.uuid) AND (cn.building = b.uuid)) AND (cn.company = c.uuid));
ALTER TABLE ONLY doc_work_execution ALTER COLUMN id SET DEFAULT nextval('doc_work_execution_id_seq'::regclass);
ALTER TABLE ONLY r_contract_works ALTER COLUMN id SET DEFAULT nextval('r_contract_works_id_seq'::regclass);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT pk_buildings PRIMARY KEY (uuid);
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT pk_c_staff_person PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_companies
    ADD CONSTRAINT pk_companies PRIMARY KEY (uuid);
ALTER TABLE ONLY doc_contracts
    ADD CONSTRAINT pk_dic_contracts PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_services
    ADD CONSTRAINT pk_dic_services PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_tariffs
    ADD CONSTRAINT pk_dic_tariffs PRIMARY KEY (uuid);
ALTER TABLE ONLY doc_work_execution
    ADD CONSTRAINT pk_doc_work_execution PRIMARY KEY (id);
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
ALTER TABLE ONLY r_contract_works
    ADD CONSTRAINT pk_r_contract_works PRIMARY KEY (id);
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT pk_staffing PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_works
    ADD CONSTRAINT pk_works PRIMARY KEY (uuid);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT uk_buildings_disp UNIQUE (disp, period);
CREATE INDEX fki_buildings_parent ON dic_buildings USING btree (parent);
CREATE INDEX fki_c_staff_person_position ON c_staff_person USING btree ("position");
CREATE INDEX fki_dic_contracts_building ON doc_contracts USING btree (building);
CREATE INDEX fki_dic_contracts_company ON doc_contracts USING btree (company);
CREATE INDEX fki_dic_contracts_work ON doc_contracts USING btree (service);
CREATE INDEX fki_dic_tariffs_comp ON dic_tariffs USING btree (comp);
CREATE INDEX fki_dic_tariffs_work_works ON dic_tariffs USING btree (work);
CREATE INDEX fki_pk_work_exec_person ON doc_work_execution USING btree (person);
CREATE INDEX fki_plots_buildings ON dic_plots USING btree (building);
CREATE INDEX fki_r_contract_works_contract ON r_contract_works USING btree (contract);
CREATE INDEX fki_r_contract_works_service ON r_contract_works USING btree (service);
CREATE INDEX fki_r_contract_works_work ON r_contract_works USING btree (work);
CREATE INDEX fki_staffing_department ON dic_staffing USING btree (company);
CREATE INDEX fki_staffing_position ON dic_staffing USING btree ("position");
CREATE INDEX fki_work_exec_building ON doc_work_execution USING btree (building);
CREATE INDEX fki_work_exec_work ON doc_work_execution USING btree (work);
CREATE INDEX fki_works_parent ON dic_works USING btree (parent);
ALTER TABLE ONLY dic_buildings
    ADD CONSTRAINT fk_buildings_parent FOREIGN KEY (parent) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_person FOREIGN KEY (person) REFERENCES dic_personnel(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY c_staff_person
    ADD CONSTRAINT fk_c_staff_person_position FOREIGN KEY ("position") REFERENCES dic_staffing(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY dic_companies
    ADD CONSTRAINT fk_companies_parent FOREIGN KEY (parent) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY doc_contracts
    ADD CONSTRAINT fk_dic_contracts_building FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY doc_contracts
    ADD CONSTRAINT fk_dic_contracts_company FOREIGN KEY (company) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY doc_contracts
    ADD CONSTRAINT fk_dic_contracts_service FOREIGN KEY (service) REFERENCES dic_services(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_tariffs
    ADD CONSTRAINT fk_dic_tariffs_comp FOREIGN KEY (comp) REFERENCES sec.companies(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY dic_tariffs
    ADD CONSTRAINT fk_dic_tariffs_work_works FOREIGN KEY (work) REFERENCES dic_works(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_plots
    ADD CONSTRAINT fk_plots_buildings FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_plots
    ADD CONSTRAINT fk_plots_person FOREIGN KEY (person) REFERENCES c_staff_person(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY r_building_props
    ADD CONSTRAINT fk_r_building_props_building FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY r_contract_works
    ADD CONSTRAINT fk_r_contract_works_contract FOREIGN KEY (contract) REFERENCES doc_contracts(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY r_contract_works
    ADD CONSTRAINT fk_r_contract_works_service FOREIGN KEY (service) REFERENCES dic_services(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY r_contract_works
    ADD CONSTRAINT fk_r_contract_works_work FOREIGN KEY (work) REFERENCES dic_works(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_comp FOREIGN KEY (comp) REFERENCES sec.companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_company FOREIGN KEY (company) REFERENCES dic_companies(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY dic_staffing
    ADD CONSTRAINT fk_staffing_position FOREIGN KEY ("position") REFERENCES dic_positions(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY doc_work_execution
    ADD CONSTRAINT fk_work_exec_building FOREIGN KEY (building) REFERENCES dic_buildings(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY doc_work_execution
    ADD CONSTRAINT fk_work_exec_person FOREIGN KEY (person) REFERENCES dic_personnel(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY doc_work_execution
    ADD CONSTRAINT fk_work_exec_work FOREIGN KEY (work) REFERENCES dic_works(uuid) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE ONLY dic_works
    ADD CONSTRAINT fk_works_parent FOREIGN KEY (parent) REFERENCES dic_works(uuid) ON UPDATE CASCADE ON DELETE CASCADE;
