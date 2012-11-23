--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-23 12:05:31 OMST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 12 (class 2615 OID 25717)
-- Name: def; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA def;


--
-- TOC entry 2148 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA def; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA def IS 'Определения объектов, справочников, действий, правил и т.д.';


SET search_path = def, pg_catalog;

SET default_with_oids = false;

--
-- TOC entry 180 (class 1259 OID 25778)
-- Name: requisites; Type: TABLE; Schema: def; Owner: -
--

CREATE TABLE requisites (
    parent ext.ltree NOT NULL,
    code ext.ltree NOT NULL,
    seq integer,
    type ext.ltree,
    disp text,
    isarray boolean DEFAULT false NOT NULL,
    ishistory boolean DEFAULT false NOT NULL
);


--
-- TOC entry 2149 (class 0 OID 0)
-- Dependencies: 180
-- Name: TABLE requisites; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE requisites IS 'Описания реквизитов объектов, справочников';


--
-- TOC entry 2150 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.parent; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.parent IS 'Тип объекта, которому принадлежит этот реквизит';


--
-- TOC entry 2151 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.code IS 'Код реквизита';


--
-- TOC entry 2152 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.seq; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.seq IS 'Порядок отображения по умолчанию';


--
-- TOC entry 2153 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.type; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.type IS 'Тип';


--
-- TOC entry 2154 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.disp IS 'Отображаемое имя';


--
-- TOC entry 2155 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.isarray; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.isarray IS 'Является массивом';


--
-- TOC entry 2156 (class 0 OID 0)
-- Dependencies: 180
-- Name: COLUMN requisites.ishistory; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.ishistory IS 'Хранить историю изменений';


--
-- TOC entry 179 (class 1259 OID 25718)
-- Name: types; Type: TABLE; Schema: def; Owner: -
--

CREATE TABLE types (
    code ext.ltree NOT NULL,
    disp text,
    note text
);


--
-- TOC entry 2157 (class 0 OID 0)
-- Dependencies: 179
-- Name: TABLE types; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE types IS 'Определения используемых типов объектов, справочников и т.д.';


--
-- TOC entry 2158 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN types.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.code IS 'Код типа';


--
-- TOC entry 2159 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN types.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.disp IS 'Отображаемое имя';


--
-- TOC entry 2160 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN types.note; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.note IS 'Описание типа';


--
-- TOC entry 2143 (class 0 OID 25778)
-- Dependencies: 180
-- Data for Name: requisites; Type: TABLE DATA; Schema: def; Owner: -
--

INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'num', 1, 'fld.num', 'Номер', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'date', 2, 'fld.date', 'Дата', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sm', 3, 'fld.money', 'Сумма', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'nds.sm', 30, 'fld.money', 'Сумма НДС', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'nds.rate', 31, 'fld.percent', 'Ставка НДС', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'note', 6, 'fld.text', 'Назначение платежа', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sender', 4, 'dic.account', 'Счёт отправителя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'reciever', 5, 'dic.account', 'Счёт получателя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'num', 1, 'fld.text', 'Номер счёта', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'bank', 2, 'dic.bank', 'Банк', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'agent', 3, 'dic.agent', 'Владелец счёта', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'code', 1, 'fld.text', 'Код', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'period', 4, 'fld.period', 'Период действия', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'fullname', 3, 'fld.text', 'Полное наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'inn', 4, 'fld.numeric', 'ИНН', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'kpp', 5, 'fld.numeric', 'КПП', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'shortname', 2, 'fld.text', 'Краткое наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'name', 2, 'fld.text', 'Наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'bic', 1, 'fld.numeric', 'БИК', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'account', 3, 'fld.numeric', 'Коррсчёт', false, true);


--
-- TOC entry 2142 (class 0 OID 25718)
-- Dependencies: 179
-- Data for Name: types; Type: TABLE DATA; Schema: def; Owner: -
--

INSERT INTO types (code, disp, note) VALUES ('dic', 'Справочник', NULL);
INSERT INTO types (code, disp, note) VALUES ('doc', 'Документ', NULL);
INSERT INTO types (code, disp, note) VALUES ('dic.agent', 'Контрагент', NULL);
INSERT INTO types (code, disp, note) VALUES ('doc.pay', 'Платёжное поручение', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld', 'Поле', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.date', 'Дата', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.money', 'Сумма', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.num', 'Номер', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.text', 'Текст', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.percent', 'Процент', NULL);
INSERT INTO types (code, disp, note) VALUES ('dic.account', 'Расчётный счёт', NULL);
INSERT INTO types (code, disp, note) VALUES ('dic.bank', 'Банк', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.numeric', 'Число', NULL);
INSERT INTO types (code, disp, note) VALUES ('fld.period', 'Период дат', NULL);
INSERT INTO types (code, disp, note) VALUES ('act', 'Действи', NULL);
INSERT INTO types (code, disp, note) VALUES ('act.open', 'Открыть', NULL);
INSERT INTO types (code, disp, note) VALUES ('act.print', 'Печать', NULL);


--
-- TOC entry 2139 (class 2606 OID 25785)
-- Name: pk_requisites; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT pk_requisites PRIMARY KEY (parent, code);


--
-- TOC entry 2135 (class 2606 OID 25725)
-- Name: pk_types; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY types
    ADD CONSTRAINT pk_types PRIMARY KEY (code);


--
-- TOC entry 2136 (class 1259 OID 25796)
-- Name: fki_structures_parent; Type: INDEX; Schema: def; Owner: -
--

CREATE INDEX fki_structures_parent ON requisites USING btree (parent);


--
-- TOC entry 2137 (class 1259 OID 25797)
-- Name: fki_structures_type; Type: INDEX; Schema: def; Owner: -
--

CREATE INDEX fki_structures_type ON requisites USING btree (type);


--
-- TOC entry 2140 (class 2606 OID 25786)
-- Name: fk_structures_parent; Type: FK CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_parent FOREIGN KEY (parent) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2141 (class 2606 OID 25791)
-- Name: fk_structures_type; Type: FK CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_type FOREIGN KEY (type) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2012-11-23 12:05:31 OMST

--
-- PostgreSQL database dump complete
--

