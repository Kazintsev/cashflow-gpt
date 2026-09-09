CREATE TABLE public."finance_settings" (
  "key" text NOT NULL,
  "value" jsonb NOT NULL,
  "notes" text,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
