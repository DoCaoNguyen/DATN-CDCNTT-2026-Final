--
-- PostgreSQL database dump
--

\restrict bd7BEiBBvldUdfM9WAyXWJb6gaz0Tl5GQAXV6PXyt458SCrLBw06kkamwJ74OYc

-- Dumped from database version 17.7
-- Dumped by pg_dump version 17.7

-- Started on 2026-06-30 16:49:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 61784)
-- Name: user_linked_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_linked_wallets (
    id integer NOT NULL,
    user_id integer,
    wallet_name character varying(50) NOT NULL,
    wallet_account text,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    linked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    masked_account character varying(255)
);


ALTER TABLE public.user_linked_wallets OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 61783)
-- Name: user_linked_wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_linked_wallets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_linked_wallets_id_seq OWNER TO postgres;

--
-- TOC entry 4913 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_linked_wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_linked_wallets_id_seq OWNED BY public.user_linked_wallets.id;


--
-- TOC entry 218 (class 1259 OID 61776)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    full_name character varying(100),
    phone character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 61775)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 4914 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4749 (class 2604 OID 61787)
-- Name: user_linked_wallets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_linked_wallets ALTER COLUMN id SET DEFAULT nextval('public.user_linked_wallets_id_seq'::regclass);


--
-- TOC entry 4747 (class 2604 OID 61779)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4907 (class 0 OID 61784)
-- Dependencies: 220
-- Data for Name: user_linked_wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_linked_wallets (id, user_id, wallet_name, wallet_account, status, linked_at, masked_account) FROM stdin;
2	1	Mio	tok_mio_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIwMTllZWU2NS1iNWIxLTc3NTktYjYwZS03MDdjOWU4MTM4NmEiLCJwaG9uZSI6IjAzMzIzMzAwNzIiLCJpYXQiOjE3ODI4MDk2ODcsImV4cCI6MjA5ODE2OTY4N30.uW47pv2d7ygnfyq29GUoVYMP5AyQ_fj2eg5Mupm_vrU	ACTIVE	2026-06-30 15:54:47.49513	******0072
\.


--
-- TOC entry 4905 (class 0 OID 61776)
-- Dependencies: 218
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, full_name, phone, created_at) FROM stdin;
1	Người dùng TikTok	0987654321	2026-06-30 14:01:22.089086
\.


--
-- TOC entry 4915 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_linked_wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_linked_wallets_id_seq', 2, true);


--
-- TOC entry 4916 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- TOC entry 4755 (class 2606 OID 61791)
-- Name: user_linked_wallets user_linked_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_linked_wallets
    ADD CONSTRAINT user_linked_wallets_pkey PRIMARY KEY (id);


--
-- TOC entry 4757 (class 2606 OID 61793)
-- Name: user_linked_wallets user_linked_wallets_user_id_wallet_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_linked_wallets
    ADD CONSTRAINT user_linked_wallets_user_id_wallet_name_key UNIQUE (user_id, wallet_name);


--
-- TOC entry 4753 (class 2606 OID 61782)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4758 (class 2606 OID 61794)
-- Name: user_linked_wallets user_linked_wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_linked_wallets
    ADD CONSTRAINT user_linked_wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2026-06-30 16:49:43

--
-- PostgreSQL database dump complete
--

\unrestrict bd7BEiBBvldUdfM9WAyXWJb6gaz0Tl5GQAXV6PXyt458SCrLBw06kkamwJ74OYc

