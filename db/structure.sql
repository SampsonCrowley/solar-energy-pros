SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: exchange_rate_integer; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.exchange_rate_integer AS bigint NOT NULL DEFAULT 0;


--
-- Name: institution_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.institution_category AS ENUM (
    'business',
    'club',
    'school',
    'university'
);


--
-- Name: money_integer; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.money_integer AS integer NOT NULL DEFAULT 0;


--
-- Name: three_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.three_state AS ENUM (
    'Y',
    'N',
    'U'
);


--
-- Name: unsubscriber_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unsubscriber_category AS ENUM (
    'C',
    'E',
    'M',
    'T'
);


--
-- Name: jsonb_foreign_key(text, text, jsonb, text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jsonb_foreign_key(table_name text, foreign_key text, store jsonb, key text, type text DEFAULT 'numeric'::text, nullable boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
  does_exist BOOLEAN;
BEGIN
  IF store->>key IS NULL
  THEN
    return nullable;
  END IF;

  IF store->>key = ''
  THEN
    return FALSE;
  END IF;

  EXECUTE FORMAT('SELECT EXISTS (SELECT 1 FROM %1$I WHERE %1$I.%2$I = CAST($1 AS ' || type || '))', table_name, foreign_key)
  INTO does_exist
  USING store->>key;

  RETURN does_exist;
END;
$_$;


--
-- Name: jsonb_nested_set(jsonb, text[], jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jsonb_nested_set(target jsonb, path text[], new_value jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  new_json jsonb := '{}'::jsonb;
  does_exist BOOLEAN;
  current_path text[];
  key text;
BEGIN
  IF target #> path IS NOT NULL
  THEN
    return jsonb_set(target, path, new_value);
  ELSE
    new_json := target;

    IF array_length(path, 1) > 1
    THEN
      FOREACH key IN ARRAY path[:(array_length(path, 1) - 1)]
      LOOP
        current_path := array_append(current_path, key);
        IF new_json #> current_path IS NULL
        THEN
          new_json := jsonb_set(new_json, current_path, '{}'::jsonb, TRUE);
        END IF;
      END LOOP;
    END IF;

    return jsonb_set(new_json, path, new_value, TRUE);
  END IF;
END;
$$;


--
-- Name: logidze_compact_history(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_compact_history(log_data jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
        DECLARE
          merged jsonb;
        BEGIN
          merged := jsonb_build_object(
            'ts',
            log_data#>'{h,1,ts}',
            'v',
            log_data#>'{h,1,v}',
            'c',
            (log_data#>'{h,0,c}') || (log_data#>'{h,1,c}')
          );

          IF (log_data#>'{h,1}' ? 'm') THEN
            merged := jsonb_set(merged, ARRAY['m'], log_data#>'{h,1,m}');
          END IF;

          return jsonb_set(
            log_data,
            '{h}',
            jsonb_set(
              log_data->'h',
              '{1}',
              merged
            ) - 0
          );
        END;
      $$;


--
-- Name: logidze_exclude_keys(jsonb, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_exclude_keys(obj jsonb, VARIADIC keys text[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
        DECLARE
          res jsonb;
          key text;
        BEGIN
          res := obj;
          FOREACH key IN ARRAY keys
          LOOP
            res := res - key;
          END LOOP;
          RETURN res;
        END;
      $$;


--
-- Name: logidze_logger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_logger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        DECLARE
          changes jsonb;
          version jsonb;
          snapshot jsonb;
          new_v integer;
          size integer;
          history_limit integer;
          debounce_time integer;
          current_version integer;
          merged jsonb;
          iterator integer;
          item record;
          columns_blacklist text[];
          ts timestamp with time zone;
          ts_column text;
        BEGIN
          ts_column := NULLIF(TG_ARGV[1], 'null');
          columns_blacklist := COALESCE(NULLIF(TG_ARGV[2], 'null'), '{}');

          IF TG_OP = 'INSERT' THEN
            snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column, columns_blacklist);

            IF snapshot#>>'{h, -1, c}' != '{}' THEN
              NEW.log_data := snapshot;
            END IF;

          ELSIF TG_OP = 'UPDATE' THEN

            IF OLD.log_data is NULL OR OLD.log_data = '{}'::jsonb THEN
              snapshot = logidze_snapshot(to_jsonb(NEW.*), ts_column, columns_blacklist);
              IF snapshot#>>'{h, -1, c}' != '{}' THEN
                NEW.log_data := snapshot;
              END IF;
              RETURN NEW;
            END IF;

            history_limit := NULLIF(TG_ARGV[0], 'null');
            debounce_time := NULLIF(TG_ARGV[3], 'null');

            current_version := (NEW.log_data->>'v')::int;

            IF ts_column IS NULL THEN
              ts := statement_timestamp();
            ELSE
              ts := (to_jsonb(NEW.*)->>ts_column)::timestamp with time zone;
              IF ts IS NULL OR ts = (to_jsonb(OLD.*)->>ts_column)::timestamp with time zone THEN
                ts := statement_timestamp();
              END IF;
            END IF;

            IF NEW = OLD THEN
              RETURN NEW;
            END IF;

            IF current_version < (NEW.log_data#>>'{h,-1,v}')::int THEN
              iterator := 0;
              FOR item in SELECT * FROM jsonb_array_elements(NEW.log_data->'h')
              LOOP
                IF (item.value->>'v')::int > current_version THEN
                  NEW.log_data := jsonb_set(
                    NEW.log_data,
                    '{h}',
                    (NEW.log_data->'h') - iterator
                  );
                END IF;
                iterator := iterator + 1;
              END LOOP;
            END IF;

            changes := hstore_to_jsonb_loose(
              hstore(NEW.*) - hstore(OLD.*)
            );

            new_v := (NEW.log_data#>>'{h,-1,v}')::int + 1;

            size := jsonb_array_length(NEW.log_data->'h');
            version := logidze_version(new_v, changes, ts, columns_blacklist);

            IF version->>'c' = '{}' THEN
              RETURN NEW;
            END IF;

            IF (
              debounce_time IS NOT NULL AND
              (version->>'ts')::bigint - (NEW.log_data#>'{h,-1,ts}')::text::bigint <= debounce_time
            ) THEN
              -- merge new version with the previous one
              new_v := (NEW.log_data#>>'{h,-1,v}')::int;
              version := logidze_version(new_v, (NEW.log_data#>'{h,-1,c}')::jsonb || changes, ts, columns_blacklist);
              -- remove the previous version from log
              NEW.log_data := jsonb_set(
                NEW.log_data,
                '{h}',
                (NEW.log_data->'h') - (size - 1)
              );
            END IF;

            NEW.log_data := jsonb_set(
              NEW.log_data,
              ARRAY['h', size::text],
              version,
              true
            );

            NEW.log_data := jsonb_set(
              NEW.log_data,
              '{v}',
              to_jsonb(new_v)
            );

            IF history_limit IS NOT NULL AND history_limit = size THEN
              NEW.log_data := logidze_compact_history(NEW.log_data);
            END IF;
          END IF;

          return NEW;
        END;
        $$;


--
-- Name: logidze_snapshot(jsonb, text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_snapshot(item jsonb, ts_column text, blacklist text[] DEFAULT '{}'::text[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
        DECLARE
          ts timestamp with time zone;
        BEGIN
          IF ts_column IS NULL THEN
            ts := statement_timestamp();
          ELSE
            ts := coalesce((item->>ts_column)::timestamp with time zone, statement_timestamp());
          END IF;
          return json_build_object(
            'v', 1,
            'h', jsonb_build_array(
                   logidze_version(1, item, ts, blacklist)
                 )
            );
        END;
      $$;


--
-- Name: logidze_version(bigint, jsonb, timestamp with time zone, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.logidze_version(v bigint, data jsonb, ts timestamp with time zone, blacklist text[] DEFAULT '{}'::text[]) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
        DECLARE
          buf jsonb;
        BEGIN
          buf := jsonb_build_object(
                   'ts',
                   (extract(epoch from ts) * 1000)::bigint,
                   'v',
                    v,
                    'c',
                    logidze_exclude_keys(data, VARIADIC array_append(blacklist, 'log_data'))
                   );
          IF coalesce(current_setting('logidze.meta', true), '') <> '' THEN
            buf := jsonb_set(buf, ARRAY['m'], current_setting('logidze.meta')::jsonb);
          END IF;
          RETURN buf;
        END;
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id uuid NOT NULL,
    blob_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.address (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    country_id uuid NOT NULL,
    postal_code public.citext,
    region public.citext,
    city public.citext,
    delivery public.citext,
    backup public.citext,
    verified_for text[] DEFAULT '{}'::text[] NOT NULL,
    rejected_for text[] DEFAULT '{}'::text[] NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: country; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    alpha_2 public.citext NOT NULL,
    alpha_3 public.citext NOT NULL,
    "numeric" text NOT NULL,
    short text NOT NULL,
    name text NOT NULL,
    CONSTRAINT country_alpha_2_format CHECK ((alpha_2 OPERATOR(public.~*) '^[A-Z]{2}$'::public.citext)),
    CONSTRAINT country_alpha_3_format CHECK ((alpha_3 OPERATOR(public.~*) '^[A-Z]{3}$'::public.citext)),
    CONSTRAINT country_numeric_format CHECK (("numeric" ~* '^[0-9]{3}$'::text))
);


--
-- Name: person; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    title text,
    first_names text NOT NULL,
    middle_names text,
    last_names text NOT NULL,
    suffix text,
    email public.citext,
    password_digest text,
    single_use_digest text,
    single_use_expires_at timestamp without time zone,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    log_data jsonb
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.state (
    abbr public.citext NOT NULL,
    name public.citext NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    CONSTRAINT state_abbr_format CHECK ((abbr OPERATOR(public.~*) '^[A-Z0-9]{2}$'::public.citext))
);


--
-- Name: unsubscriber; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unsubscriber (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category public.unsubscriber_category,
    value public.citext NOT NULL,
    "all" boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_session (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    browser_id text NOT NULL,
    token_digest text NOT NULL,
    user_agent text,
    ip_address text,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: state state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (abbr);


--
-- Name: unsubscriber unsubscriber_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unsubscriber
    ADD CONSTRAINT unsubscriber_pkey PRIMARY KEY (id);


--
-- Name: user_session user_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT user_session_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_address_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_on_country_id ON public.address USING btree (country_id);


--
-- Name: index_address_on_rejected_for; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_on_rejected_for ON public.address USING gin (rejected_for);


--
-- Name: index_address_on_verified_for; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_on_verified_for ON public.address USING gin (verified_for);


--
-- Name: index_country_on_alpha_2; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_on_alpha_2 ON public.country USING btree (alpha_2);


--
-- Name: index_country_on_alpha_3; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_on_alpha_3 ON public.country USING btree (alpha_3);


--
-- Name: index_country_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_on_name ON public.country USING btree (name);


--
-- Name: index_country_on_numeric; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_on_numeric ON public.country USING btree ("numeric");


--
-- Name: index_country_on_short; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_country_on_short ON public.country USING btree (short);


--
-- Name: index_person_on_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_on_data ON public.person USING gin (data);


--
-- Name: index_person_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_on_email ON public.person USING btree (email);


--
-- Name: index_state_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_state_on_name ON public.state USING btree (name);


--
-- Name: index_unsubscriber_on_category_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unsubscriber_on_category_and_value ON public.unsubscriber USING btree (category, value);


--
-- Name: index_user_session_on_browser_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_session_on_browser_id_and_user_id ON public.user_session USING btree (browser_id, user_id);


--
-- Name: index_user_session_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_session_on_user_id ON public.user_session USING btree (user_id);


--
-- Name: person logidze_on_person; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER logidze_on_person BEFORE INSERT OR UPDATE ON public.person FOR EACH ROW WHEN ((COALESCE(current_setting('logidze.disabled'::text, true), ''::text) <> 'on'::text)) EXECUTE FUNCTION public.logidze_logger('20', 'updated_at', '{password_digest,single_use_digest,single_use_expires_at}');


--
-- Name: user_session fk_rails_b7dc8aa429; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT fk_rails_b7dc8aa429 FOREIGN KEY (user_id) REFERENCES public.person(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20200527191248'),
('20200527191329'),
('20200527194002'),
('20200527194003'),
('20200528171519'),
('20200528174009'),
('20200528174010'),
('20200528225314'),
('20200715002511'),
('20200716184312'),
('20200817174512'),
('20210109045756'),
('20210109045757');


