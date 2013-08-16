SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
CREATE SCHEMA json;
COMMENT ON SCHEMA json IS 'Функции для работы с JSON';
SET search_path = json, pg_catalog;
CREATE FUNCTION element(text, anyelement) RETURNS text
    LANGUAGE sql
    AS $_$select '"' || $1 || '": ' || json.value($2);$_$;
CREATE FUNCTION elements(VARIADIC text[]) RETURNS text
    LANGUAGE sql
    AS $_$select json.get($1)$_$;
CREATE FUNCTION get(anyarray) RETURNS text
    LANGUAGE sql
    AS $_$select '{' || array_to_string($1, ', ') || '}'$_$;
CREATE FUNCTION parse(json) RETURNS SETOF text[]
    LANGUAGE sql
    AS $_$with recursive
	tokens as(
		select s[1] as token, row_number() over() as n
		from regexp_matches(
			$1::text,
			$RE$(
				(?:[\]\[\}\{])
				|
				(?:" (?:\\"|[^"])+ ")
				|
				\w+
				|
				\s+
				|
				[:,]
			)$RE$,
			'gx') as g(s)
		where s[1] !~ $RE$^[\s:,\s]+$$RE$
	),
parsed as(
	select n,
		token as token,
		array[token] as stack,
		array['$']::text[] as path,
		'' as jsp,
		array[0]::integer[] as poses
	from tokens t where n=1
	union all
	select t.n,
		t.token as token,
		case when t.token in (']','}') then p.stack[1:array_upper(p.stack,1)-1]
			when t.token in ('[','{') then p.stack || t.token
			else p.stack
		end,
		case when t.token in ('[','{') then p.path ||
		case when p.stack[array_upper(p.stack,1)]='{'
			then regexp_replace(p.token,'^"|"$','','g')
		else '[' || (p.poses[array_upper(p.poses,1)]+1)::text || ']'
		end
		when t.token in (']','}') then p.path[1:array_upper(p.path,1)-1]
			else p.path
		end,
		case when p.stack[array_upper(p.stack,1)]='{' then p.token
		when p.stack[array_upper(p.stack,1)]='[' then '[' ||
				(p.poses[array_upper(p.poses,1)]+1)::text || ']'
		else ''
		end,
		case when t.token in ('[','{') then p.poses[1:array_upper(p.poses,1)-
			1]||(p.poses[array_upper(p.poses,1)]+1)||0
		when t.token in (']','}') then p.poses[1:array_upper(p.poses,1)-1]
		else p.poses[1:array_upper(p.poses,1)-1]||
			(p.poses[array_upper(p.poses,1)]+1)
		end
	from parsed p, tokens t where t.n=p.n+1),
res as(
select *
from parsed
where (stack[array_upper(stack,1)]='['
	or (stack[array_upper(stack,1)]='{'
	and poses[array_upper(poses,1)]%2=0)
	)
	and token not in ('{','[','}',']')
	)
select array[array_to_string(path,'.')||'.'||
	regexp_replace(jsp,'^"|"$','','g')
	,
	regexp_replace(token,'^"|"$','','g')
	]
from res$_$;
CREATE FUNCTION value(boolean) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;
CREATE FUNCTION value(integer) RETURNS text
    LANGUAGE sql
    AS $_$select $1::text$_$;
CREATE FUNCTION value(json) RETURNS json
    LANGUAGE sql
    AS $_$select $1$_$;
CREATE FUNCTION value(text) RETURNS text
    LANGUAGE sql
    AS $_$select regexp_replace($1,'^([^\{]*[^\}])$',E'"\\1"','g')$_$;
