CREATE TABLE public."account_balance_snapshots" (
  "id" bigint DEFAULT nextval('balance_snapshots_id_seq'::regclass) NOT NULL,
  "account_id" bigint NOT NULL,
  "balance_date" date NOT NULL,
  "balance" numeric NOT NULL,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "balance_as_of" timestamp with time zone NOT NULL
);
