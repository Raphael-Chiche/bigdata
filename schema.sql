CREATE TABLE "User"(
    "id" UUID NOT NULL,
    "first_name" VARCHAR(255) NOT NULL,
    "mail" VARCHAR(255) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "phone_number" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "defaultAddress" UUID NULL
);
ALTER TABLE
    "User" ADD PRIMARY KEY("id");
ALTER TABLE
    "User" ADD CONSTRAINT "user_mail_unique" UNIQUE("mail");
ALTER TABLE
    "User" ADD CONSTRAINT "user_phone_number_unique" UNIQUE("phone_number");
COMMENT
ON COLUMN
    "User"."password" IS 'hash';
CREATE TABLE "Address"(
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "street_name" VARCHAR(255) NOT NULL,
    "zip_code" VARCHAR(255) NOT NULL,
    "country" VARCHAR(255) NOT NULL,
    "city" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "Address" ADD PRIMARY KEY("id");
CREATE TABLE "Product"(
    "id" UUID NOT NULL,
    "ref_commercial" TEXT NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "brand_id" UUID NOT NULL
);
ALTER TABLE
    "Product" ADD PRIMARY KEY("id");
ALTER TABLE
    "Product" ADD CONSTRAINT "product_ref_commercial_unique" UNIQUE("ref_commercial");
CREATE TABLE "Category"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "parent_id" UUID NULL
);
ALTER TABLE
    "Category" ADD PRIMARY KEY("id");
CREATE TABLE "ProductCategory"(
    "id_product" UUID NOT NULL,
    "id_category" UUID NOT NULL
);
ALTER TABLE
    "ProductCategory" ADD PRIMARY KEY("id_product", "id_category");
CREATE TABLE "Brand"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "Brand" ADD PRIMARY KEY("id");
ALTER TABLE
    "Brand" ADD CONSTRAINT "brand_name_unique" UNIQUE("name");
CREATE TABLE "Variant"(
    "id" UUID NOT NULL,
    "product_id" UUID NOT NULL,
    "ref_commercial" TEXT NOT NULL,
    "size" VARCHAR(255) NULL,
    "color" VARCHAR(255) NULL,
    "stock" INTEGER NOT NULL
);
ALTER TABLE
    "Variant" ADD CONSTRAINT "variant_product_id_size_color_unique" UNIQUE("product_id", "size", "color");
ALTER TABLE
    "Variant" ADD PRIMARY KEY("id");
ALTER TABLE
    "Variant" ADD CONSTRAINT "variant_ref_commercial_unique" UNIQUE("ref_commercial");
CREATE TABLE "Price"(
    "id" UUID NOT NULL,
    "value" BIGINT NOT NULL,
    "valid_date" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "variant_id" UUID NOT NULL,
    "currency_id" UUID NOT NULL
);
ALTER TABLE
    "Price" ADD CONSTRAINT "price_variant_id_currency_id_valid_date_unique" UNIQUE(
        "variant_id",
        "currency_id",
        "valid_date"
    );
ALTER TABLE
    "Price" ADD PRIMARY KEY("id");
CREATE TABLE "Currency"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "Currency" ADD PRIMARY KEY("id");
CREATE TABLE "Cart"(
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL
);
ALTER TABLE
    "Cart" ADD PRIMARY KEY("id");
ALTER TABLE
    "Cart" ADD CONSTRAINT "cart_user_id_unique" UNIQUE("user_id");
CREATE TABLE "CartItem"(
    "cart_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "quantity" BIGINT NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
);
ALTER TABLE
    "CartItem" ADD PRIMARY KEY("cart_id", "variant_id");
CREATE TABLE "Orders"(
    "id" UUID NOT NULL,
    "public_id" VARCHAR(255) NOT NULL,
    "user_id" UUID NULL,
    "currency_id" UUID NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "status" VARCHAR(255) CHECK
        (
            "status" IN(
                'pending',
                'paid',
                'shipped',
                'delivered',
                'cancelled'
            )
        ) NOT NULL,
        "name" TEXT NULL,
        "mail" VARCHAR(255) NULL,
        "phone_number" VARCHAR(255) NULL,
        "street_name" VARCHAR(255) NULL,
        "zip_code" VARCHAR(255) NULL,
        "city" VARCHAR(255) NULL,
        "country" VARCHAR(255) NULL,
        "promotion_id" UUID NULL
);
ALTER TABLE
    "Orders" ADD PRIMARY KEY("id");
ALTER TABLE
    "Orders" ADD CONSTRAINT "orders_public_id_unique" UNIQUE("public_id");
CREATE TABLE "OrderItem"(
    "order_id" UUID NOT NULL,
    "variant_id" UUID NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" BIGINT NOT NULL
);
ALTER TABLE
    "OrderItem" ADD PRIMARY KEY("order_id", "variant_id");
CREATE TABLE "promotion"(
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "scope" VARCHAR(255) CHECK
        (
            "scope" IN('order', 'product', 'category')
        ) NOT NULL,
        "value" BIGINT NOT NULL,
        "start_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
        "end_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
        "max_usage" INTEGER NULL,
        "code" VARCHAR(255) NULL,
        "user_id" UUID NULL,
        "limited_by_user" BOOLEAN NOT NULL DEFAULT FALSE,
        "currency_id" UUID NULL,
        "discount_type" VARCHAR(255)
    CHECK
        (
            "discount_type" IN('fixed', 'percent')
        ) NOT NULL DEFAULT 'percent'
);
ALTER TABLE
    "promotion" ADD PRIMARY KEY("id");
ALTER TABLE
    "promotion" ADD CONSTRAINT "promotion_code_unique" UNIQUE("code");
CREATE TABLE "promotion_target"(
    "id" UUID NOT NULL,
    "promotion_id" UUID NOT NULL,
    "product_id" UUID NULL,
    "category_id" UUID NULL
);
ALTER TABLE
    "promotion_target" ADD PRIMARY KEY("id");
ALTER TABLE
    "promotion_target" ADD CONSTRAINT "promotion_target_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "Category"("id");
ALTER TABLE
    "ProductCategory" ADD CONSTRAINT "productcategory_id_category_foreign" FOREIGN KEY("id_category") REFERENCES "Category"("id");
ALTER TABLE
    "OrderItem" ADD CONSTRAINT "orderitem_order_id_foreign" FOREIGN KEY("order_id") REFERENCES "Orders"("id");
ALTER TABLE
    "Orders" ADD CONSTRAINT "orders_currency_id_foreign" FOREIGN KEY("currency_id") REFERENCES "Currency"("id");
ALTER TABLE
    "CartItem" ADD CONSTRAINT "cartitem_cart_id_foreign" FOREIGN KEY("cart_id") REFERENCES "Cart"("id");
ALTER TABLE
    "ProductCategory" ADD CONSTRAINT "productcategory_id_product_foreign" FOREIGN KEY("id_product") REFERENCES "Product"("id");
ALTER TABLE
    "CartItem" ADD CONSTRAINT "cartitem_variant_id_foreign" FOREIGN KEY("variant_id") REFERENCES "Variant"("id");
ALTER TABLE
    "Orders" ADD CONSTRAINT "orders_promotion_id_foreign" FOREIGN KEY("promotion_id") REFERENCES "promotion"("id");
ALTER TABLE
    "promotion_target" ADD CONSTRAINT "promotion_target_promotion_id_foreign" FOREIGN KEY("promotion_id") REFERENCES "promotion"("id");
ALTER TABLE
    "Category" ADD CONSTRAINT "category_parent_id_foreign" FOREIGN KEY("parent_id") REFERENCES "Category"("id");
ALTER TABLE
    "promotion" ADD CONSTRAINT "promotion_currency_id_foreign" FOREIGN KEY("currency_id") REFERENCES "Currency"("id");
ALTER TABLE
    "Orders" ADD CONSTRAINT "orders_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "User"("id");
ALTER TABLE
    "Cart" ADD CONSTRAINT "cart_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "User"("id");
ALTER TABLE
    "Product" ADD CONSTRAINT "product_brand_id_foreign" FOREIGN KEY("brand_id") REFERENCES "Brand"("id");
ALTER TABLE
    "OrderItem" ADD CONSTRAINT "orderitem_variant_id_foreign" FOREIGN KEY("variant_id") REFERENCES "Variant"("id");
ALTER TABLE
    "Price" ADD CONSTRAINT "price_variant_id_foreign" FOREIGN KEY("variant_id") REFERENCES "Variant"("id");
ALTER TABLE
    "Variant" ADD CONSTRAINT "variant_product_id_foreign" FOREIGN KEY("product_id") REFERENCES "Product"("id");
ALTER TABLE
    "User" ADD CONSTRAINT "user_defaultaddress_foreign" FOREIGN KEY("defaultAddress") REFERENCES "Address"("id");
ALTER TABLE
    "Price" ADD CONSTRAINT "price_currency_id_foreign" FOREIGN KEY("currency_id") REFERENCES "Currency"("id");
ALTER TABLE
    "promotion_target" ADD CONSTRAINT "promotion_target_product_id_foreign" FOREIGN KEY("product_id") REFERENCES "Product"("id");
ALTER TABLE
    "promotion" ADD CONSTRAINT "promotion_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "User"("id");
ALTER TABLE
    "Address" ADD CONSTRAINT "address_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "User"("id");