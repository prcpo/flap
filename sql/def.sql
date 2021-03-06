SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA def;
COMMENT ON SCHEMA def IS 'Определения объектов, справочников, действий, правил и т.д.';
SET search_path = def, pg_catalog;
CREATE FUNCTION otablename(_p anyelement) RETURNS text
    LANGUAGE sql
    AS $_$select 'obj.n_' || replace($1::text,'.','_');$_$;
CREATE FUNCTION otables_create() RETURNS void
    LANGUAGE plpgsql
    AS $$declare
	_cur refcursor;
	_stmt	text;
begin
	open _cur for select 'drop table ' || schemaname ||'.'|| tablename from obj.otables;
	loop 
		fetch _cur into _stmt;
		if _stmt is null then exit; end if;
		raise notice 'Exec: %', _stmt;
		execute _stmt;
	end loop;
	close _cur;
	open _cur for 
		select 'CREATE TABLE ' || def.otablename(p) || ' (
		 "uuid" uuid NOT NULL DEFAULT uuid_generate_v4(), 
		 ' 
		|| array_to_string(array_agg( '"'||c::text || '" ' || t::text || iif(isarray,'[]'::text,''::text)),',
		 ') 
		|| ',  
			CONSTRAINT pk_n_' || replace(p::text,'.','_') || ' PRIMARY KEY ("uuid")
		);'
		from (
		select r.parent p, r.code c, t.db_type t, isarray from def.requisites r, def.types t
		where t.code = r.type
		and nlevel(r.code) = 1
		) q1
		group by p;
	loop
		fetch _cur into _stmt;
		if _stmt is null then exit; end if;
		raise notice 'Exec: %', _stmt;
		begin
			execute _stmt;
		end;
	end loop;
	close _cur;
end;
$$;
CREATE FUNCTION settings_company(_code ext.ltree) RETURNS uuid
    LANGUAGE sql SECURITY DEFINER
    AS $_$select coalesce(iif(iscompany, set.company_get(), null), uuid_null())
from def.settings
where code = $1;$_$;
COMMENT ON FUNCTION settings_company(_code ext.ltree) IS 'Возвращает организацию для параметра';
CREATE FUNCTION settings_user(_user ext.ltree) RETURNS text
    LANGUAGE sql SECURITY DEFINER
    AS $_$select coalesce(iif(isuser, session_user::text, null), '')
from def.settings
where code = $1;$_$;
COMMENT ON FUNCTION settings_user(_user ext.ltree) IS 'Возвращает пользователя параметра';
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE types (
    code ext.ltree NOT NULL,
    disp text,
    note text,
    db_type name
);
COMMENT ON TABLE types IS 'Определения используемых типов объектов, справочников и т.д.
Зарезервированы ветви:
dic - справочники;
doc - документы;
act - действия;
fld - типы полей.
Ветви dic и doc отображаются в дереве навигации.';
COMMENT ON COLUMN types.code IS 'Код типа';
COMMENT ON COLUMN types.disp IS 'Отображаемое имя';
COMMENT ON COLUMN types.note IS 'Описание типа';
COMMENT ON COLUMN types.db_type IS 'Соответствующий тип БД';
CREATE VIEW navtree AS
    SELECT types.code, types.disp, types.note FROM types WHERE ((types.code OPERATOR(ext.<@) 'dic'::ext.ltree) OR (types.code OPERATOR(ext.<@) 'doc'::ext.ltree));
SET default_with_oids = true;
CREATE TABLE requisites (
    parent ext.ltree NOT NULL,
    code ext.ltree NOT NULL,
    seq integer,
    type ext.ltree,
    disp text,
    isarray boolean DEFAULT false NOT NULL,
    ishistory boolean DEFAULT false NOT NULL
);
COMMENT ON TABLE requisites IS 'Описания реквизитов объектов, справочников';
COMMENT ON COLUMN requisites.parent IS 'Тип объекта, которому принадлежит этот реквизит';
COMMENT ON COLUMN requisites.code IS 'Код реквизита';
COMMENT ON COLUMN requisites.seq IS 'Порядок отображения по умолчанию';
COMMENT ON COLUMN requisites.type IS 'Тип';
COMMENT ON COLUMN requisites.disp IS 'Отображаемое имя';
COMMENT ON COLUMN requisites.isarray IS 'Является массивом';
COMMENT ON COLUMN requisites.ishistory IS 'Хранить историю изменений';
CREATE VIEW object_structure AS
    WITH r2 AS (SELECT requisites.parent, json.element(((requisites.code)::text || tools.iif(requisites.isarray, '[]'::text, ''::text)), (requisites.type)::text) AS element FROM requisites ORDER BY requisites.seq) SELECT r2.parent, json.get(array_agg(r2.element)) AS get FROM r2 GROUP BY r2.parent;
COMMENT ON VIEW object_structure IS 'Структура объектов';
CREATE VIEW pg_types AS
    SELECT pg_type.typname FROM pg_type;
COMMENT ON VIEW pg_types IS 'Системные типы данных';
SET default_with_oids = false;
CREATE TABLE settings (
    code ext.ltree NOT NULL,
    disp text,
    note text,
    default_value text,
    isuser boolean DEFAULT false NOT NULL,
    iscompany boolean DEFAULT false NOT NULL,
    ishistory boolean DEFAULT false NOT NULL,
    type ext.ltree,
    val text
);
COMMENT ON TABLE settings IS 'Определения настроек.
Если default_value начинается со знака =, то дальнейшее выражение будет вычислено на SQL (вызвана фунция calculate()).
Не следует забывать знак % для вычислений, требующих привязки ко времени!
Результаты вычислений преобразуются к текстовому формату.
См. примечание к функции calculate()
';
COMMENT ON COLUMN settings.code IS 'Код настройки';
COMMENT ON COLUMN settings.disp IS 'Отображаемое наименование';
COMMENT ON COLUMN settings.note IS 'Пояснения';
COMMENT ON COLUMN settings.default_value IS 'Значение по умолчанию';
COMMENT ON COLUMN settings.isuser IS 'Может быть индивидуальной для каждого пользователя';
COMMENT ON COLUMN settings.iscompany IS 'Может быть индивидуальной для каждой организации';
COMMENT ON COLUMN settings.ishistory IS 'Сохранять значения, действующие в разные периоды времени';
COMMENT ON COLUMN settings.val IS 'Значение настройки';
CREATE TABLE tests (
    tree ext.ltree NOT NULL,
    command text NOT NULL,
    result text
);
COMMENT ON TABLE tests IS 'Тесты';
COMMENT ON COLUMN tests.tree IS 'Код теста';
COMMENT ON COLUMN tests.command IS 'Команда';
COMMENT ON COLUMN tests.result IS 'Ожидаемый результат';
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'num', 1, 'fld.num', 'Номер', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'date', 2, 'fld.date', 'Дата', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sm', 3, 'fld.money', 'Сумма', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'note', 6, 'fld.text', 'Назначение платежа', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sender', 4, 'dic.account', 'Счёт отправителя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'reciever', 5, 'dic.account', 'Счёт получателя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'num', 1, 'fld.text', 'Номер счёта', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'code', 1, 'fld.text', 'Код', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'fullname', 3, 'fld.text', 'Полное наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'inn', 4, 'fld.numeric', 'ИНН', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'kpp', 5, 'fld.numeric', 'КПП', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.agent', 'shortname', 2, 'fld.text', 'Краткое наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'name', 2, 'fld.text', 'Наименование', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'bic', 1, 'fld.numeric', 'БИК', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.bank', 'account', 3, 'fld.numeric', 'Коррсчёт', false, true);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'period', 4, 'fld.period', 'Период действия', true, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sender.name', 4, 'fld.text', 'Отправитель', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'reciever.bank', 5, 'fld.text', 'Банк получателя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'sender.bank', 4, 'fld.text', 'Банк отправителя', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'nds_rate', 31, 'fld.percent', 'Ставка НДС', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'nds_sm', 30, 'fld.money', 'Сумма НДС', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('doc.pay', 'reciever.agent.code', 5, 'fld.text', 'Получатель', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'bank', 2, 'dic.bank', 'Банк', false, false);
INSERT INTO requisites (parent, code, seq, type, disp, isarray, ishistory) VALUES ('dic.account', 'agent', 3, 'dic.agent', 'Владелец счета', true, false);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('name', 'Наименование платформы', NULL, 'Учётная платформа FLAP', false, false, false, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('note', 'Описание', NULL, 'Свежую версию вы можете взять на https://github.com/prcpo/flap', false, false, false, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('version', 'Версия платформы', NULL, '12.11', false, false, false, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('work.company', 'Организация, с которой работать', NULL, '=uuid_null()', true, false, false, 'fld.uuid', NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('work.date', 'Рабочая дата', NULL, '=now()', true, true, false, 'fld.date', NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('company.name', 'Наименование организации', NULL, 'Моя организация', false, true, true, 'fld.text', NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('user.shortname', 'Фамилия, инициалы пользователя', NULL, '=setting(''user.fullname'',%)', true, false, true, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('user.position', 'Должность', NULL, '_______________________', true, true, true, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('user.fullname', 'Фамилия, имя и отчество пользователя', NULL, '_____________________', true, false, true, NULL, NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('work.period', 'Расчётный период', NULL, '=this_year(%)', true, true, false, 'fld.period', NULL);
INSERT INTO settings (code, disp, note, default_value, isuser, iscompany, ishistory, type, val) VALUES ('work.notification_time', 'Время последнего полученного сообщения', NULL, '-infinity', true, true, false, NULL, NULL);
INSERT INTO tests (tree, command, result) VALUES ('settings.01.set', 'setting_set(''work.date'',''01.01.12'')::text', 'false');
INSERT INTO tests (tree, command, result) VALUES ('settings.02.set', 'setting_set(''work.date'',''02.01.12''::text)::text', 'true');
INSERT INTO tests (tree, command, result) VALUES ('settings.03.set', 'setting_set(''work_date'',''03.01.12''::text)::text', 'false');
INSERT INTO tests (tree, command, result) VALUES ('settings.11.get', 'setting_get(''work_date'')', 'false');
INSERT INTO tests (tree, command, result) VALUES ('settings.12.get', 'setting_get(''work.date'')', '02.01.12');
INSERT INTO types (code, disp, note, db_type) VALUES ('act.open', 'Открыть', NULL, NULL);
INSERT INTO types (code, disp, note, db_type) VALUES ('act.print', 'Печать', NULL, NULL);
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.date', 'Дата', NULL, 'date');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.money', 'Сумма', NULL, 'numeric');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld', 'Поле', NULL, 'text');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.num', 'Номер', NULL, 'text');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.numeric', 'Число', NULL, 'integer');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.percent', 'Процент', NULL, 'numeric');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.period', 'Период дат', NULL, 'daterange');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.text', 'Текст', NULL, 'text');
INSERT INTO types (code, disp, note, db_type) VALUES ('act', 'Действи', NULL, NULL);
INSERT INTO types (code, disp, note, db_type) VALUES ('dic', 'Справочник', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('doc', 'Документ', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('doc.pay', 'Платёжное поручение', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('dic.account', 'Расчётный счёт', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('dic.agent', 'Контрагент', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('dic.bank', 'Банк', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.uuid', 'UUID', NULL, 'uuid');
INSERT INTO types (code, disp, note, db_type) VALUES ('fld.datetime', 'Время', NULL, 'timestamp');
ALTER TABLE ONLY requisites
    ADD CONSTRAINT pk_requisites PRIMARY KEY (parent, code);
ALTER TABLE ONLY settings
    ADD CONSTRAINT pk_settings PRIMARY KEY (code);
ALTER TABLE ONLY tests
    ADD CONSTRAINT pk_tests PRIMARY KEY (tree);
ALTER TABLE ONLY types
    ADD CONSTRAINT pk_types PRIMARY KEY (code);
CREATE INDEX fki_settings ON settings USING btree (type);
CREATE INDEX fki_structures_parent ON requisites USING btree (parent);
CREATE INDEX fki_structures_type ON requisites USING btree (type);
ALTER TABLE ONLY settings
    ADD CONSTRAINT fk_settings FOREIGN KEY (type) REFERENCES types(code) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_parent FOREIGN KEY (parent) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY requisites
    ADD CONSTRAINT fk_structures_type FOREIGN KEY (type) REFERENCES types(code) ON UPDATE CASCADE ON DELETE CASCADE;
