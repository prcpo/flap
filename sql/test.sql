SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA test;
COMMENT ON SCHEMA test IS 'Тесты';
SET search_path = test, pg_catalog;
CREATE FUNCTION "do"(_lquery ext.lquery, _erase_results boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$declare
  _res boolean array;
begin
  if _erase_results then 
		delete from test.results;
	end if;
	select array (
		select test.do_test(tree) from def.tests where tree ~ $1
		) into _res;
	return true;
end;$_$;
COMMENT ON FUNCTION "do"(_lquery ext.lquery, _erase_results boolean) IS 'Запускает все тесты по маске';
CREATE FUNCTION do_test(_code ext.ltree) RETURNS boolean
    LANGUAGE plpgsql
    AS $$declare
  _command text;
  _err text;
  _res text;
  _estimate text;
  _tm_b timestamp;
  _tm_e timestamp;
  _passed boolean;
begin
	_res = null;
	_passed = false;
	insert into test.results (dt, test)
		values (now(), _code);
	select command, result from def.tests where tree = _code into _command, _estimate;
	if _command is null then
		_err = 'Test "' || _code::text || '" is not found in table "test.tests"';
	ELSE
		begin
		  _tm_b = clock_timestamp();
		  _tm_e = _tm_b;
			select * FROM tools.execute_statement('select ' || _command) INTO _res, _err;
			_tm_e = clock_timestamp();
			raise notice '.res = %', _res;
			raise notice '.err = %', _err;
		EXCEPTION WHEN OTHERS THEN
			_err = SQLERRM;
		end;
	end if;
	_passed = (COALESCE(_res,'---') = _estimate);
	if (not _passed) and (_estimate = 'false') then 
		_passed = true; 
	end if;
	update test.results
		set notes = _err,
		result = _res,
		ms = EXTRACT(MILLISECONDS FROM (_tm_e - _tm_b)),
		dt = _tm_b,
		tm = _tm_e,
		passed = _passed
		where dt = now()
		and test::text = _code::text;
	RETURN _res = _estimate AND _err IS NULL;
end;$$;
CREATE FUNCTION fill_random_objects(_code ext.ltree, _cnt integer) RETURNS void
    LANGUAGE sql
    AS $_$insert into obj.raw("type","data")
select $1, test.generate_object($1) from generate_series(1,$2) idx;$_$;
COMMENT ON FUNCTION fill_random_objects(_code ext.ltree, _cnt integer) IS 'Создаёт указанное количество объектов указанного типа';
CREATE FUNCTION generate_all_object(_num integer) RETURNS void
    LANGUAGE plpgsql
    AS $$declare
	_cur cursor for select pid from (
	select pid, max(level) lvl from test.requisites_tree
	group by pid ) t1
	order by lvl;
begin
	for _code in _cur loop
		perform test.fill_random_objects(_code.pid, _num);
	end loop;
end;
$$;
CREATE FUNCTION generate_object(_code ext.ltree) RETURNS json
    LANGUAGE plpgsql
    AS $$begin
	return json.get(array_agg(val)) from (
		select  
			case when isarray then
				json.element(code::text, array_to_json(array(
					select test.generate_random("type") from generate_series(0,(random()*2)::integer)
			)))
			else
				json.element(code::text,test.generate_random("type"))
			end as val 
		from def.requisites
		where parent = _code) e1;
end;$$;
COMMENT ON FUNCTION generate_object(_code ext.ltree) IS 'Заполняет реквизиты объекта случайными данными';
CREATE FUNCTION generate_random(_type ext.ltree) RETURNS text
    LANGUAGE plpgsql
    AS $_$declare
	_res	text;
	_num integer;
	_lipsum text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam et blandit nunc. Vestibulum et massa sem, eget laoreet ipsum. Mauris eget orci quis lectus iaculis consectetur auctor ut nulla. Donec ullamcorper nisi imperdiet arcu tristique pretium vitae id eros. Maecenas condimentum urna sed arcu congue mattis. Pellentesque malesuada purus ut orci euismod feugiat. Vestibulum eu tempus odio. Donec faucibus luctus est suscipit fermentum. Phasellus vehicula semper mauris, a bibendum metus convallis quis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nam consectetur massa et felis lacinia non hendrerit tellus hendrerit. Duis mattis ultrices tellus, eget. ';
begin
	if (_type::text = 'fld.date') then
		return (now()::date - (random() * 365)::integer)::text; end if;
	if (_type::text = 'fld.money') then
		return (round((random() * 10000)::numeric,2))::text; end if;
	if (_type::text = 'fld.num') then
		return substring( 'ЯЧСМИТВАП' from (( random() * 8 )::int + 1 ) for 1 )
		||'-'||(round((random() * 100000)::numeric))::text; end if;
	if (_type::text = 'fld.text') then
		return substring(_lipsum, (random()*100)::integer+1, (random()*100)::integer+1); end if;
	if (_type::text = 'fld.numeric') then
		return (round((random() * 100000)::numeric))::text; end if;
	if (_type::text = 'fld.percent') then
		return (round((random() * 100)::numeric))::text; end if;
	if (_type::text = 'fld.period') then
		return res from(
			with dt1 as (select test.generate_random('fld.date'::ltree)::date dt),
				dt2 as (select test.generate_random('fld.date'::ltree)::date dt)
			select iif(dt1.dt > dt2.dt, 
				daterange(dt2.dt,dt1.dt),
				daterange(dt1.dt,dt2.dt))::text res from dt1,dt2) r1; 
	end if;
	if (subpath(_type,0,1)::text='dic') then
		select count(*) from obj.user_raw where "type" = _type into _num;
		_num = (random() * _num)::integer;
		execute 'select uuid from obj.user_raw where type = $1 limit 1 offset $2' 
			into _res using _type, _num;
		return _res;
	end if;
	return _type::text;
end;$_$;
COMMENT ON FUNCTION generate_random(_type ext.ltree) IS 'Возвращает случайное значение в зависимости от типа.';
CREATE VIEW requisites_tree AS
    WITH RECURSIVE tree(id, pid, code) AS (SELECT requisites.type AS id, requisites.parent AS pid, requisites.code FROM def.requisites), wp(code, id, pid, level, path) AS (SELECT s.code, s.id, s.pid, 0, (s.pid OPERATOR(ext.||) s.code) FROM tree s WHERE (NOT (EXISTS (SELECT 'x' FROM tree s1 WHERE (s1.pid OPERATOR(ext.=) s.id)))) UNION ALL SELECT tree.code, tree.id, tree.pid, (wp.level + 1), ((tree.pid OPERATOR(ext.||) tree.code) OPERATOR(ext.||) wp.path) FROM tree, wp WHERE (tree.id OPERATOR(ext.=) wp.pid)) SELECT wp.pid, wp.code, wp.id, wp.level, wp.path FROM wp;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE results (
    dt timestamp with time zone DEFAULT now() NOT NULL,
    test ext.ltree NOT NULL,
    result text,
    notes text,
    passed boolean,
    ms double precision,
    tm timestamp with time zone
);
COMMENT ON TABLE results IS 'Результаты тестов';
COMMENT ON COLUMN results.dt IS 'Дата и время теста';
COMMENT ON COLUMN results.test IS 'Код теста';
COMMENT ON COLUMN results.result IS 'Результат выполнения теста';
COMMENT ON COLUMN results.notes IS 'Примечания, вывод сообщений об ошибках';
COMMENT ON COLUMN results.passed IS 'Тест пройден успешно';
COMMENT ON COLUMN results.ms IS 'Время выполнения запроса, мс.';
ALTER TABLE ONLY results
    ADD CONSTRAINT pk_results PRIMARY KEY (dt, test);
