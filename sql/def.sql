--
-- PostgreSQL database dump
--

-- Dumped from database version 9.2.1
-- Dumped by pg_dump version 9.2.1
-- Started on 2012-11-26 10:30:35 OMST

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
-- TOC entry 2179 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA def; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA def IS 'Определения объектов, справочников, действий, правил и т.д.';


SET search_path = def, pg_catalog;

--
-- TOC entry 282 (class 1255 OID 36372)
-- Name: const_get(text); Type: FUNCTION; Schema: def; Owner: -
--

CREATE FUNCTION const_get(text) RETURNS text
    LANGUAGE sql
    AS $_$select value from def.const 
where code ~ $1::lquery;$_$;


--
-- TOC entry 2180 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION const_get(text); Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON FUNCTION const_get(text) IS 'Получить значение константы';


--
-- TOC entry 284 (class 1255 OID 36373)
-- Name: const_set(text, text); Type: FUNCTION; Schema: def; Owner: -
--

CREATE FUNCTION const_set(_code text, _value text) RETURNS void
    LANGUAGE plpgsql
    AS $$begin
	insert into def.const (code, value)
		values (text2ltree(_code), _value);
exception
	when unique_violation then
		update def.const
			set value = _value
			where code = text2ltree(_code);
end;$$;


--
-- TOC entry 2181 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION const_set(_code text, _value text); Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON FUNCTION const_set(_code text, _value text) IS 'Сохраняет значение константы.
Первый параметр - код (ltree),
второй - значение константы, может быть только текстовым.';


--
-- TOC entry 283 (class 1255 OID 36374)
-- Name: const_set(text, text, text); Type: FUNCTION; Schema: def; Owner: -
--

CREATE FUNCTION const_set(_code text, _disp text, _value text) RETURNS void
    LANGUAGE plpgsql
    AS $$begin
  perform def.const_set(_code, _value);
  update def.const
		set disp = _disp
		where code = text2ltree(_code);
end;$$;


--
-- TOC entry 2182 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION const_set(_code text, _disp text, _value text); Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON FUNCTION const_set(_code text, _disp text, _value text) IS 'Устанавливает новую константу.';


SET default_with_oids = false;

--
-- TOC entry 184 (class 1259 OID 36361)
-- Name: const; Type: TABLE; Schema: def; Owner: -
--

CREATE TABLE const (
    code ext.ltree NOT NULL,
    disp text,
    value text
);


--
-- TOC entry 2183 (class 0 OID 0)
-- Dependencies: 184
-- Name: TABLE const; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE const IS 'Константы системы.
Значения могут быть только текстом.
Константы не преназначены для изменения пользователями.
История значений не сохраняется.';


--
-- TOC entry 2184 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN const.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN const.code IS 'Код константы';


--
-- TOC entry 2185 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN const.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN const.disp IS 'Отображаемое наименование';


--
-- TOC entry 2186 (class 0 OID 0)
-- Dependencies: 184
-- Name: COLUMN const.value; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN const.value IS 'Значение';


--
-- TOC entry 181 (class 1259 OID 25718)
-- Name: types; Type: TABLE; Schema: def; Owner: -
--

CREATE TABLE types (
    code ext.ltree NOT NULL,
    disp text,
    note text
);


--
-- TOC entry 2187 (class 0 OID 0)
-- Dependencies: 181
-- Name: TABLE types; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE types IS 'Определения используемых типов объектов, справочников и т.д.

Зарезервированы ветви:
dic - справочники;
doc - документы;
act - действия;
fld - типы полей.

Ветви dic и doc отображаются в дереве навигации.';


--
-- TOC entry 2188 (class 0 OID 0)
-- Dependencies: 181
-- Name: COLUMN types.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.code IS 'Код типа';


--
-- TOC entry 2189 (class 0 OID 0)
-- Dependencies: 181
-- Name: COLUMN types.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.disp IS 'Отображаемое имя';


--
-- TOC entry 2190 (class 0 OID 0)
-- Dependencies: 181
-- Name: COLUMN types.note; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN types.note IS 'Описание типа';


--
-- TOC entry 183 (class 1259 OID 36356)
-- Name: navtree; Type: VIEW; Schema: def; Owner: -
--

CREATE VIEW navtree AS
    SELECT types.code, types.disp, types.note FROM types WHERE ((types.code OPERATOR(ext.<@) 'dic'::ext.ltree) OR (types.code OPERATOR(ext.<@) 'doc'::ext.ltree));


--
-- TOC entry 182 (class 1259 OID 25778)
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
-- TOC entry 2191 (class 0 OID 0)
-- Dependencies: 182
-- Name: TABLE requisites; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE requisites IS 'Описания реквизитов объектов, справочников';


--
-- TOC entry 2192 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.parent; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.parent IS 'Тип объекта, которому принадлежит этот реквизит';


--
-- TOC entry 2193 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.code IS 'Код реквизита';


--
-- TOC entry 2194 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.seq; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.seq IS 'Порядок отображения по умолчанию';


--
-- TOC entry 2195 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.type; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.type IS 'Тип';


--
-- TOC entry 2196 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.disp IS 'Отображаемое имя';


--
-- TOC entry 2197 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.isarray; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.isarray IS 'Является массивом';


--
-- TOC entry 2198 (class 0 OID 0)
-- Dependencies: 182
-- Name: COLUMN requisites.ishistory; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN requisites.ishistory IS 'Хранить историю изменений';


--
-- TOC entry 185 (class 1259 OID 36378)
-- Name: settings; Type: TABLE; Schema: def; Owner: -
--

CREATE TABLE settings (
    code ext.ltree NOT NULL,
    disp text,
    note text,
    default_value text,
    isuser boolean DEFAULT false NOT NULL,
    iscompany boolean DEFAULT false NOT NULL,
    ishistory boolean DEFAULT false NOT NULL,
    type ext.ltree
);


--
-- TOC entry 2199 (class 0 OID 0)
-- Dependencies: 185
-- Name: TABLE settings; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON TABLE settings IS 'Определения настроек';


--
-- TOC entry 2200 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.code; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.code IS 'Код настройки';


--
-- TOC entry 2201 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.disp; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.disp IS 'Отображаемое наименование';


--
-- TOC entry 2202 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.note; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.note IS 'Пояснения';


--
-- TOC entry 2203 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.default_value; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.default_value IS 'Значение по умолчанию';


--
-- TOC entry 2204 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.isuser; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.isuser IS 'Может быть индивидуальной для каждого пользователя';


--
-- TOC entry 2205 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.iscompany; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.iscompany IS 'Может быть индивидуальной для каждой организации';


--
-- TOC entry 2206 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN settings.ishistory; Type: COMMENT; Schema: def; Owner: -
--

COMMENT ON COLUMN settings.ishistory IS 'Сохранять значения, действующие в разные периоды времени';


--
-- TOC entry 2173 (class 0 OID 36361)
-- Dependencies: 184
-- Data for Name: const; Type: TABLE DATA; Schema: def; Owner: -
--

INSERT INTO const (code, disp, value) VALUES ('defaults.company.name', 'Наименование организации по умолчанию', 'Моя организация');


--
-- TOC entry 2172 (class 0 OID 25778)
-- Dependencies: 182
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
-- TOC entry 2174 (class 0 OID 36378)
-- Dependencies: 185
-- Data for Name: settings; Type: TABLE DATA; Schema: def; Owner: -
--

INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('company.name', 'Наименование организации', NULL, 'Моя организация', false, true, false, 'fld.text');
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('work.period', 'Расчётный период', NULL, NULL, true, true, false, 'fld.date');
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('work.date', 'Рабочая дата', NULL, NULL, true, true, false, 'fld.period');
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('version', 'Версия платформы', NULL, '12.11.24', false, false, false, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('name', 'Наименование платформы', NULL, 'Учётная платформа FLAP', false, false, false, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type) VALUES ('note', 'Описание', NULL, 'Свежую версию вы можете взять на https://github.com/prcpo/flap', false, false, false, NULL);


--
-- TOC entry 2171 (class 0 OID 25718)
-- Dependencies: 181
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
-- TOC entry 2164 (class 2606 OID 36368)
-- Name: pk_const; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY const
    ADD CONSTRAINT pk_const PRIMARY KEY (code);


--
-- TOC entry 2162 (class 2606 OID 25785)
-- Name: pk_requisites; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT pk_requisites PRIMARY KEY (parent, code);


--
-- TOC entry 2167 (class 2606 OID 36385)
-- Name: pk_settings; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT pk_settings PRIMARY KEY (code);


--
-- TOC entry 2158 (class 2606 OID 25725)
-- Name: pk_types; Type: CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY types
    ADD CONSTRAINT pk_types PRIMARY KEY (code);


--
-- TOC entry 2165 (class 1259 OID 36395)
-- Name: fki_settings; Type: INDEX; Schema: def; Owner: -
--

CREATE INDEX fki_settings ON settings USING btree (type);


--
-- TOC entry 2159 (class 1259 OID 25796)
-- Name: fki_structures_parent; Type: INDEX; Schema: def; Owner: -
--

CREATE INDEX fki_structures_parent ON requisites USING btree (parent);


--
-- TOC entry 2160 (class 1259 OID 25797)
-- Name: fki_structures_type; Type: INDEX; Schema: def; Owner: -
--

CREATE INDEX fki_structures_type ON requisites USING btree (type);


--
-- TOC entry 2170 (class 2606 OID 36396)
-- Name: fk_settings; Type: FK CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings FOREIGN KEY (type) REFERENCES types(code) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 2168 (class 2606 OID 25786)
-- Name: fk_structures_parent; Type: FK CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_parent FOREIGN KEY (parent) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2169 (class 2606 OID 25791)
-- Name: fk_structures_type; Type: FK CONSTRAINT; Schema: def; Owner: -
--

ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_type FOREIGN KEY (type) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2012-11-26 10:30:35 OMST

--
-- PostgreSQL database dump complete
--
