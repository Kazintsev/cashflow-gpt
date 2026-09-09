CREATE TABLE public."cash_flow_event_funding" (
  "id" bigint DEFAULT nextval('cash_flow_event_funding_id_seq'::regclass) NOT NULL,
  "cash_flow_event_id" bigint NOT NULL,
  "transaction_id" bigint NOT NULL,
  "amount" numeric NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "relation_type" text DEFAULT 'funding'::text NOT NULL,
  "allocation_source" text DEFAULT 'manual'::text NOT NULL
);
