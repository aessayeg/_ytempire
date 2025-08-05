--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13
-- Dumped by pg_dump version 15.13

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
-- Name: ytempire; Type: SCHEMA; Schema: -; Owner: ytempire_user
--

CREATE SCHEMA ytempire;


ALTER SCHEMA ytempire OWNER TO ytempire_user;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: ytempire; Owner: ytempire_user
--

CREATE FUNCTION ytempire.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION ytempire.update_updated_at_column() OWNER TO ytempire_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analytics; Type: TABLE; Schema: ytempire; Owner: ytempire_user
--

CREATE TABLE ytempire.analytics (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    video_id uuid NOT NULL,
    views integer DEFAULT 0,
    likes integer DEFAULT 0,
    comments integer DEFAULT 0,
    watch_time integer DEFAULT 0,
    date date NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ytempire.analytics OWNER TO ytempire_user;

--
-- Name: channels; Type: TABLE; Schema: ytempire; Owner: ytempire_user
--

CREATE TABLE ytempire.channels (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    youtube_channel_id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    thumbnail_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ytempire.channels OWNER TO ytempire_user;

--
-- Name: users; Type: TABLE; Schema: ytempire; Owner: ytempire_user
--

CREATE TABLE ytempire.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(255) NOT NULL,
    password_hash text NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    avatar_url text,
    email_verified boolean DEFAULT false,
    is_active boolean DEFAULT true,
    role character varying(50) DEFAULT 'user'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ytempire.users OWNER TO ytempire_user;

--
-- Name: videos; Type: TABLE; Schema: ytempire; Owner: ytempire_user
--

CREATE TABLE ytempire.videos (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    channel_id uuid NOT NULL,
    youtube_video_id character varying(255),
    title character varying(500) NOT NULL,
    description text,
    tags text[],
    status character varying(50) DEFAULT 'draft'::character varying,
    thumbnail_url text,
    video_file_path text,
    duration integer,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE ytempire.videos OWNER TO ytempire_user;

--
-- Data for Name: analytics; Type: TABLE DATA; Schema: ytempire; Owner: ytempire_user
--

COPY ytempire.analytics (id, video_id, views, likes, comments, watch_time, date, created_at) FROM stdin;
\.


--
-- Data for Name: channels; Type: TABLE DATA; Schema: ytempire; Owner: ytempire_user
--

COPY ytempire.channels (id, user_id, youtube_channel_id, name, description, thumbnail_url, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: ytempire; Owner: ytempire_user
--

COPY ytempire.users (id, email, username, password_hash, first_name, last_name, avatar_url, email_verified, is_active, role, created_at, updated_at) FROM stdin;
e09ba372-b0ed-415d-8434-c16ef5117447	admin@ytempire.local	admin	$2b$10$K6L7hPMqE.5nDrzJvTbgcuVWUwD3NjQw4I6H1SSofbVGxH8wMJZ3.	Admin	User	\N	f	t	admin	2025-08-05 13:01:58.974681+00	2025-08-05 13:01:58.974681+00
10f49369-48ae-4dc4-ae63-cc743404f76d	test@ytempire.local	testuser	$2b$10$K6L7hPMqE.5nDrzJvTbgcuVWUwD3NjQw4I6H1SSofbVGxH8wMJZ3.	Test	User	\N	f	t	user	2025-08-05 13:01:58.974681+00	2025-08-05 13:01:58.974681+00
\.


--
-- Data for Name: videos; Type: TABLE DATA; Schema: ytempire; Owner: ytempire_user
--

COPY ytempire.videos (id, channel_id, youtube_video_id, title, description, tags, status, thumbnail_url, video_file_path, duration, published_at, created_at, updated_at) FROM stdin;
\.


--
-- Name: analytics analytics_pkey; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.analytics
    ADD CONSTRAINT analytics_pkey PRIMARY KEY (id);


--
-- Name: analytics analytics_video_id_date_key; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.analytics
    ADD CONSTRAINT analytics_video_id_date_key UNIQUE (video_id, date);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (id);


--
-- Name: channels channels_youtube_channel_id_key; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.channels
    ADD CONSTRAINT channels_youtube_channel_id_key UNIQUE (youtube_channel_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: videos videos_pkey; Type: CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.videos
    ADD CONSTRAINT videos_pkey PRIMARY KEY (id);


--
-- Name: idx_analytics_date; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_analytics_date ON ytempire.analytics USING btree (date);


--
-- Name: idx_analytics_video_id; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_analytics_video_id ON ytempire.analytics USING btree (video_id);


--
-- Name: idx_channels_user_id; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_channels_user_id ON ytempire.channels USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_users_email ON ytempire.users USING btree (email);


--
-- Name: idx_users_username; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_users_username ON ytempire.users USING btree (username);


--
-- Name: idx_videos_channel_id; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_videos_channel_id ON ytempire.videos USING btree (channel_id);


--
-- Name: idx_videos_status; Type: INDEX; Schema: ytempire; Owner: ytempire_user
--

CREATE INDEX idx_videos_status ON ytempire.videos USING btree (status);


--
-- Name: channels update_channels_updated_at; Type: TRIGGER; Schema: ytempire; Owner: ytempire_user
--

CREATE TRIGGER update_channels_updated_at BEFORE UPDATE ON ytempire.channels FOR EACH ROW EXECUTE FUNCTION ytempire.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: ytempire; Owner: ytempire_user
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON ytempire.users FOR EACH ROW EXECUTE FUNCTION ytempire.update_updated_at_column();


--
-- Name: videos update_videos_updated_at; Type: TRIGGER; Schema: ytempire; Owner: ytempire_user
--

CREATE TRIGGER update_videos_updated_at BEFORE UPDATE ON ytempire.videos FOR EACH ROW EXECUTE FUNCTION ytempire.update_updated_at_column();


--
-- Name: analytics analytics_video_id_fkey; Type: FK CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.analytics
    ADD CONSTRAINT analytics_video_id_fkey FOREIGN KEY (video_id) REFERENCES ytempire.videos(id) ON DELETE CASCADE;


--
-- Name: channels channels_user_id_fkey; Type: FK CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.channels
    ADD CONSTRAINT channels_user_id_fkey FOREIGN KEY (user_id) REFERENCES ytempire.users(id) ON DELETE CASCADE;


--
-- Name: videos videos_channel_id_fkey; Type: FK CONSTRAINT; Schema: ytempire; Owner: ytempire_user
--

ALTER TABLE ONLY ytempire.videos
    ADD CONSTRAINT videos_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES ytempire.channels(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

