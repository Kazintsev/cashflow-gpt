CREATE TABLE public."receipt_items" (
  "id" bigint DEFAULT nextval('receipt_items_id_seq'::regclass) NOT NULL,
  "receipt_id" bigint NOT NULL,
  "line_number" integer NOT NULL,
  "name" text NOT NULL,
  "barcode" text,
  "quantity" numeric,
  "unit_price" numeric,
  "amount" numeric NOT NULL,
  "category_id" bigint,
  "confidence" numeric,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
