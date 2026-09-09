CREATE TABLE public."transaction_category_allocations" (
  "id" bigint DEFAULT nextval('transaction_category_allocations_id_seq'::regclass) NOT NULL,
  "transaction_id" bigint NOT NULL,
  "category_id" bigint NOT NULL,
  "amount" numeric NOT NULL,
  "allocation_source" text DEFAULT 'manual'::text NOT NULL,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
