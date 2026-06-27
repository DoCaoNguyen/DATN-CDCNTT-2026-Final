--
-- PostgreSQL database dump
--

\restrict A6yzeeLc78CeJImbHZLoVwQcbbeLfX44Hiw6IHS3C57NL4IZDsFJI2kN0OMaWMt

-- Dumped from database version 17.7
-- Dumped by pg_dump version 17.7

-- Started on 2026-06-26 12:52:35

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
-- TOC entry 224 (class 1259 OID 52600)
-- Name: loyalty_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loyalty_history (
    id integer NOT NULL,
    user_id integer,
    amount numeric NOT NULL,
    points_earned integer NOT NULL,
    type character varying(20) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.loyalty_history OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 52599)
-- Name: loyalty_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.loyalty_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loyalty_history_id_seq OWNER TO postgres;

--
-- TOC entry 4965 (class 0 OID 0)
-- Dependencies: 223
-- Name: loyalty_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.loyalty_history_id_seq OWNED BY public.loyalty_history.id;


--
-- TOC entry 220 (class 1259 OID 52575)
-- Name: point_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.point_rules (
    id integer NOT NULL,
    amount_per_point integer NOT NULL,
    points_earned integer NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.point_rules OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 52574)
-- Name: point_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.point_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.point_rules_id_seq OWNER TO postgres;

--
-- TOC entry 4966 (class 0 OID 0)
-- Dependencies: 219
-- Name: point_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.point_rules_id_seq OWNED BY public.point_rules.id;


--
-- TOC entry 226 (class 1259 OID 52615)
-- Name: rewards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rewards (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    points_required integer NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.rewards OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 52614)
-- Name: rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rewards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rewards_id_seq OWNER TO postgres;

--
-- TOC entry 4967 (class 0 OID 0)
-- Dependencies: 225
-- Name: rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rewards_id_seq OWNED BY public.rewards.id;


--
-- TOC entry 228 (class 1259 OID 53546)
-- Name: store_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.store_orders (
    id integer NOT NULL,
    product_name character varying(255) NOT NULL,
    amount integer NOT NULL,
    status character varying(50) DEFAULT 'PENDING'::character varying,
    qr_token character varying(255),
    merchant_order_id character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.store_orders OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 53545)
-- Name: store_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.store_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.store_orders_id_seq OWNER TO postgres;

--
-- TOC entry 4968 (class 0 OID 0)
-- Dependencies: 227
-- Name: store_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.store_orders_id_seq OWNED BY public.store_orders.id;


--
-- TOC entry 222 (class 1259 OID 52584)
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    staff_id integer,
    amount numeric NOT NULL,
    description text,
    qr_payload text,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 52583)
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO postgres;

--
-- TOC entry 4969 (class 0 OID 0)
-- Dependencies: 221
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- TOC entry 218 (class 1259 OID 52560)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    phone_number character varying(20) NOT NULL,
    password character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    role character varying(20) DEFAULT 'MEMBER'::character varying NOT NULL,
    tier character varying(20) DEFAULT 'SILVER'::character varying NOT NULL,
    total_points integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 52559)
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
-- TOC entry 4970 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 4778 (class 2604 OID 52603)
-- Name: loyalty_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_history ALTER COLUMN id SET DEFAULT nextval('public.loyalty_history_id_seq'::regclass);


--
-- TOC entry 4772 (class 2604 OID 52578)
-- Name: point_rules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.point_rules ALTER COLUMN id SET DEFAULT nextval('public.point_rules_id_seq'::regclass);


--
-- TOC entry 4780 (class 2604 OID 52618)
-- Name: rewards id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards ALTER COLUMN id SET DEFAULT nextval('public.rewards_id_seq'::regclass);


--
-- TOC entry 4782 (class 2604 OID 53549)
-- Name: store_orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store_orders ALTER COLUMN id SET DEFAULT nextval('public.store_orders_id_seq'::regclass);


--
-- TOC entry 4775 (class 2604 OID 52587)
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 52563)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 4955 (class 0 OID 52600)
-- Dependencies: 224
-- Data for Name: loyalty_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.loyalty_history (id, user_id, amount, points_earned, type, description, created_at) FROM stdin;
1	3	300000	30	EARN	Earned from wallet tx: 019ec989-c97a-777b-a5ea-0d3706df20dd	2026-06-15 11:28:31.017964
2	3	300000	30	EARN	Earned from wallet tx: 019ec990-655f-7563-8cf3-a93a443fad7d	2026-06-15 11:35:44.110289
\.


--
-- TOC entry 4951 (class 0 OID 52575)
-- Dependencies: 220
-- Data for Name: point_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.point_rules (id, amount_per_point, points_earned, active, created_at) FROM stdin;
1	10000	1	t	2026-06-15 10:49:19.57358
\.


--
-- TOC entry 4957 (class 0 OID 52615)
-- Dependencies: 226
-- Data for Name: rewards; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rewards (id, title, points_required, description, created_at) FROM stdin;
\.


--
-- TOC entry 4959 (class 0 OID 53546)
-- Dependencies: 228
-- Data for Name: store_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.store_orders (id, product_name, amount, status, qr_token, merchant_order_id, created_at) FROM stdin;
1	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449220044_721	2026-06-26 11:47:00.096258
2	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449220031_77	2026-06-26 11:47:00.09585
3	Cà Phê Sữa Đá	35000	PENDING	\N	STORE_ORD_1782449248366_609	2026-06-26 11:47:28.415374
4	Cà Phê Sữa Đá	35000	PENDING	\N	STORE_ORD_1782449248375_4	2026-06-26 11:47:28.415031
5	Cà Phê Sữa Đá	35000	PENDING	\N	STORE_ORD_1782449343588_308	2026-06-26 11:49:03.63067
6	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449345875_70	2026-06-26 11:49:05.876995
7	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449345882_362	2026-06-26 11:49:05.921974
8	Sinh Tố Dâu Tây	55000	PENDING	\N	STORE_ORD_1782449350231_595	2026-06-26 11:49:10.233002
9	Sinh Tố Dâu Tây	55000	PENDING	\N	STORE_ORD_1782449350239_318	2026-06-26 11:49:10.24027
10	Sinh Tố Dâu Tây	55000	PENDING	\N	STORE_ORD_1782449806424_604	2026-06-26 11:56:46.425318
11	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449809087_438	2026-06-26 11:56:49.088188
12	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449809095_630	2026-06-26 11:56:49.134936
13	Trà Đào Cam Sả	45000	PENDING	\N	STORE_ORD_1782449821758_186	2026-06-26 11:57:01.759093
15	Trà Đào Cam Sả	45000	PENDING	mio://pay?token=565af4b7b63a560abd883aec446ae1104c8bd901bce7b26c096aeee52e35bc82&amount=45000&description=Thanh%20to%C3%A1n%3A%20Tr%C3%A0%20%C4%90%C3%A0o%20Cam%20S%E1%BA%A3	STORE_ORD_1782449907899_628	2026-06-26 11:58:27.946156
14	Trà Đào Cam Sả	45000	PENDING	mio://pay?token=6b8a905474e846708908c80d96d086aded5badc6dcd1bf354c8d993086b76b3e&amount=45000&description=Thanh%20to%C3%A1n%3A%20Tr%C3%A0%20%C4%90%C3%A0o%20Cam%20S%E1%BA%A3	STORE_ORD_1782449907893_489	2026-06-26 11:58:27.939884
16	Cà Phê Sữa Đá	35000	PENDING	mio://pay?token=5abaaae6618c0c1f2050535f97f5281cccb0d4d59f5b72eea71ee5c2755fb48f&amount=35000&description=Thanh%20to%C3%A1n%3A%20C%C3%A0%20Ph%C3%AA%20S%E1%BB%AFa%20%C4%90%C3%A1	STORE_ORD_1782450323814_212	2026-06-26 12:05:23.849447
18	Sinh Tố Dâu Tây	55000	PENDING	mio://pay?token=fa0d3036ea270dd5e54c8c3039b2d7ae5ebd6986b524fc5ba7a723c3703b0abb&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782450624962_338	2026-06-26 12:10:24.997121
20	Sinh Tố Dâu Tây	55000	PENDING	mio://pay?token=3107dc8f9b8d3e693a355b684082b431af71001359dd133a3e29d64d92e6350f&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782451038356_498	2026-06-26 12:17:18.396212
19	Sinh Tố Dâu Tây	55000	PAID	mio://pay?token=b6c9af28708e3734df6b1afd6ea123c5e1ec17f14c0d1d21a1311a52ce2685e4&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782450624970_612	2026-06-26 12:10:25.006644
17	Cà Phê Sữa Đá	35000	PAID	mio://pay?token=d7c3e6f53fe56622c68b2cc36b81c00ec70fc095233cf81a01a8980e15ee05f5&amount=35000&description=Thanh%20to%C3%A1n%3A%20C%C3%A0%20Ph%C3%AA%20S%E1%BB%AFa%20%C4%90%C3%A1	STORE_ORD_1782450323822_282	2026-06-26 12:05:23.860377
21	Sinh Tố Dâu Tây	55000	PENDING	mio://pay?token=67d8fc4f6787564774545edf1aa6f1e9340ed872d9c39c26b24b2a0069ee3b8c&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782451134239_112	2026-06-26 12:18:54.280718
22	Sinh Tố Dâu Tây	55000	PENDING	mio://pay?token=9636ffc082345f6b0a0413f64e9124ea5ac5617a56391fd77f340b1799ac2b89&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782451141074_546	2026-06-26 12:19:01.076003
23	Sinh Tố Dâu Tây	55000	PAID	mio://pay?token=3900a0534c95eca349de7d45f82fd28121729abd87f2640b7db95ad4f6fa239a&amount=55000&description=Thanh%20to%C3%A1n%3A%20Sinh%20T%E1%BB%91%20D%C3%A2u%20T%C3%A2y	STORE_ORD_1782451141082_470	2026-06-26 12:19:01.120448
\.


--
-- TOC entry 4953 (class 0 OID 52584)
-- Dependencies: 222
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, staff_id, amount, description, qr_payload, status, created_at) FROM stdin;
1	2	300000	Tra dao cam xa	vipayment://pay?token=97e01c12d12699a25dc5b9e8dbc638bb9d2ae005322360c64df21ea03527a5b1&amount=300000&description=Tra%20dao%20cam%20xa	PENDING	2026-06-15 11:28:05.841516
2	2	300000	Tra dao cam xa	vipayment://pay?token=dd425f5e4d35586b30a37d991780129a4c9f6d4ecdb900c575406d83f09e6e06&amount=300000&description=Tra%20dao%20cam%20xa	PENDING	2026-06-15 11:35:37.813134
3	2	4000	Tra dao cam xa	vipayment://pay?token=af45626c23a05cffbdd813cc56049c9b6d78c10c18f568c23a32a7c51f35094c&amount=4000&description=Tra%20dao%20cam%20xa	PENDING	2026-06-15 11:47:58.836665
4	2	80000		vipayment://pay?token=62a303fb687a48d0d33ba14e2b89a1cc4ec4796331dd0486ff5d17f8200b81bc&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 14:53:11.993426
5	2	80000		vipayment://pay?token=ed443d358416fcfb501d3e6c289a4e295191db93e4b6526eefdd60dade4b16a0&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 14:53:19.902162
6	2	80000		vipayment://pay?token=455f2212b0fb23d58794fa5ff8e297922fa9fdb7d0378f1c6adae2b8d3c3df05&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:21.729277
7	2	80000		vipayment://pay?token=034ed0c4a84b9d467cb8a77f35f55a05d4484af64d70b93e65b74955bf3ac82d&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:22.512545
8	2	80000		vipayment://pay?token=8aca5e588631ba1e211b466193cfec3836bb8868e6c9310b372367f5a573f2ac&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:23.207588
9	2	80000		vipayment://pay?token=36d08d90034ababa63aefe66deb873f0889d6e5bcb37333ea66c4eeea4e657b6&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:23.816
10	2	80000		vipayment://pay?token=6d8424e3125f9d0c25009a971a640e66341cb3e7c7930c2efdb0c72865aaab18&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:24.355155
11	2	80000		vipayment://pay?token=3f9714cb3720a6e24b0c80a1f51beb2622303246cb32d726599f6a77263c1a7c&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:24.903061
12	2	80000		vipayment://pay?token=b508536aa8360eee2360f81cb5e80c4c079aec0bbd999064faaffc52347088dc&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:25.441519
13	2	80000		vipayment://pay?token=e4b00e31624f51408e0cd62bbef228394f0bd93dafffbc8ace006f6db3997439&amount=80000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-16 15:16:25.94435
14	2	80000	////	vipayment://pay?token=575cc9e710467fdc564b4606942a1827fbc72e2f31db9724de53bc3af220a25c&amount=80000&description=%2F%2F%2F%2F	PENDING	2026-06-16 15:16:28.961451
15	2	80000	////	vipayment://pay?token=c71930e8c976803ee0267c4027926023b694778f4b06b38bff9398e08aa619b8&amount=80000&description=%2F%2F%2F%2F	PENDING	2026-06-16 15:16:29.508608
16	2	80000	////	vipayment://pay?token=b6408df2c63799a1517714f8dd53c8522e79c3e0f3eabad0c886b404c4e93b26&amount=80000&description=%2F%2F%2F%2F	PENDING	2026-06-16 15:16:30.025459
17	2	80000	////	vipayment://pay?token=829536ad43842faba4269d431425fb28d50310b4e422766c24f144ab1dc121d2&amount=80000&description=%2F%2F%2F%2F	PENDING	2026-06-16 15:16:30.548835
18	2	80000	////	vipayment://pay?token=6ebf9e1ec582f2946461d978b6d9d97213f8d4d09384a301c8a1f4b14fa6446e&amount=80000&description=%2F%2F%2F%2F	PENDING	2026-06-16 15:16:31.004188
19	2	555000		mio://pay?token=c5bb93066f3ae82517bb9728ba9916111ebb937805b337f3fdc26f73c7fa3e7e&amount=555000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-21 12:53:24.895738
20	2	555000		mio://pay?token=32d1ec4e057139ef0ec6a5f30168bacf117fb88372a57b5de294357bc7c87e61&amount=555000&description=Thanh%20to%C3%A1n%20Loyalty	PENDING	2026-06-21 12:54:25.406286
\.


--
-- TOC entry 4949 (class 0 OID 52560)
-- Dependencies: 218
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, phone_number, password, full_name, role, tier, total_points, created_at) FROM stdin;
1	0999999999	$2b$10$8.v6OGP9aELRCJFb9nsTBOLjJv7Jox1/9napU45d/.3NT3WdMdCEm	Admin Loyalty	ADMIN	SILVER	0	2026-06-15 11:07:56.055532
3	0332330072	$2b$10$8.v6OGP9aELRCJFb9nsTBOLjJv7Jox1/9napU45d/.3NT3WdMdCEm	Nguyen Van Khach Hang	MEMBER	SILVER	60	2026-06-15 11:07:56.064846
2	0816178749	$2b$10$8.v6OGP9aELRCJFb9nsTBOLjJv7Jox1/9napU45d/.3NT3WdMdCEm	Staff Cashier	STAFF	SILVER	0	2026-06-15 11:07:56.063861
\.


--
-- TOC entry 4971 (class 0 OID 0)
-- Dependencies: 223
-- Name: loyalty_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.loyalty_history_id_seq', 2, true);


--
-- TOC entry 4972 (class 0 OID 0)
-- Dependencies: 219
-- Name: point_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.point_rules_id_seq', 1, true);


--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 225
-- Name: rewards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rewards_id_seq', 1, false);


--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 227
-- Name: store_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.store_orders_id_seq', 23, true);


--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 221
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_id_seq', 20, true);


--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 217
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- TOC entry 4794 (class 2606 OID 52608)
-- Name: loyalty_history loyalty_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_history
    ADD CONSTRAINT loyalty_history_pkey PRIMARY KEY (id);


--
-- TOC entry 4790 (class 2606 OID 52582)
-- Name: point_rules point_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.point_rules
    ADD CONSTRAINT point_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 4796 (class 2606 OID 52623)
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);


--
-- TOC entry 4798 (class 2606 OID 53557)
-- Name: store_orders store_orders_merchant_order_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store_orders
    ADD CONSTRAINT store_orders_merchant_order_id_key UNIQUE (merchant_order_id);


--
-- TOC entry 4800 (class 2606 OID 53555)
-- Name: store_orders store_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store_orders
    ADD CONSTRAINT store_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 52593)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 4786 (class 2606 OID 52573)
-- Name: users users_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_number_key UNIQUE (phone_number);


--
-- TOC entry 4788 (class 2606 OID 52571)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4802 (class 2606 OID 52609)
-- Name: loyalty_history loyalty_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_history
    ADD CONSTRAINT loyalty_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 4801 (class 2606 OID 52594)
-- Name: transactions transactions_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.users(id);


-- Completed on 2026-06-26 12:52:35

--
-- PostgreSQL database dump complete
--

\unrestrict A6yzeeLc78CeJImbHZLoVwQcbbeLfX44Hiw6IHS3C57NL4IZDsFJI2kN0OMaWMt

