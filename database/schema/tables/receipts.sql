CREATE TABLE public."receipts" (
  "id" bigint DEFAULT nextval('receipts_id_seq'::regclass) NOT NULL,
  "transaction_id" bigint NOT NULL,
  "merchant_name" text,
  "purchase_at" timestamp with time zone,
  "total_amount" numeric NOT NULL,
  "fiscal_drive_number" text,
  "fiscal_document_number" text,
  "fiscal_sign" text,
  "operation_type" smallint,
  "qr_payload" text,
  "source" text DEFAULT 'photo'::text NOT NULL,
  "parse_status" text DEFAULT 'category_only'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
