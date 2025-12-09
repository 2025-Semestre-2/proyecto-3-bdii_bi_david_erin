use BikeStoresStage;


CREATE TABLE categories (
	category_id INT NOT NULL,
	category_name VARCHAR (255) NOT NULL
);

CREATE TABLE brands (
	brand_id INT NOT NULL,
	brand_name VARCHAR (255) NOT NULL
);


CREATE TABLE products (
	product_id INT NOT NULL,
	product_name VARCHAR (255) NOT NULL,
	brand_id INT NOT NULL,
	category_id INT NOT NULL,
	model_year SMALLINT NOT NULL,
	list_price DECIMAL (10, 2) NOT NULL,
	-- FOREIGN KEY (category_id) REFERENCES production.categories (category_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (brand_id) REFERENCES production.brands (brand_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE stores (
	store_id INT NOT NULL,
	store_name VARCHAR (255) NOT NULL,
	city VARCHAR (255) NULL,
	state VARCHAR (10) NULL,
	zip_code VARCHAR (5) NULL
);


CREATE TABLE staffs (
	staff_id INT NOT NULL,
	first_name VARCHAR (50) NOT NULL,
	last_name VARCHAR (50) NOT NULL,
	-- active tinyint NOT NULL,
	store_id INT NOT NULL,
	manager_id INT NULL,
	-- FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (manager_id) REFERENCES sales.staffs (staff_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);


CREATE TABLE customers (
	customer_id INT NOT NULL,
	first_name VARCHAR (255) NOT NULL,
	last_name VARCHAR (255) NOT NULL,
	city VARCHAR (50) NULL,
	state VARCHAR (25) NULL ,
	zip_code VARCHAR (5) NULL
);

CREATE TABLE orders (
	order_id INT NOT NULL,
	customer_id INT NULL,
	order_status tinyint NOT NULL,
	-- Order status: 1 = Pending; 2 = Processing; 3 = Rejected; 4 = Completed
	order_date DATE NOT NULL,
	required_date DATE NOT NULL,
	shipped_date DATE NULL,
	store_id INT NOT NULL,
	staff_id INT NOT NULL,
	-- FOREIGN KEY (customer_id) REFERENCES sales.customers (customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (staff_id) REFERENCES sales.staffs (staff_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE order_items (
	order_id INT NOT NULL,
	item_id INT NOT NULL,
	product_id INT NOT NULL,
	quantity INT NOT NULL,
	list_price DECIMAL (10, 2) NOT NULL,
	discount DECIMAL (4, 2) NOT NULL DEFAULT 0,
	-- PRIMARY KEY (order_id, item_id),
	-- FOREIGN KEY (order_id) REFERENCES sales.orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (product_id) REFERENCES production.products (product_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE stocks (
	store_id INT NOT NULL,
	product_id INT NOT NULL,
	quantity INT NULL,
	-- PRIMARY KEY (store_id, product_id),
	-- FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	-- FOREIGN KEY (product_id) REFERENCES production.products (product_id) ON DELETE CASCADE ON UPDATE CASCADE
);