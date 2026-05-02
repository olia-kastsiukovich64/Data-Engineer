CREATE SCHEMA dds;


CREATE TABLE IF NOT EXISTS dds.countries (
            country_code VARCHAR(2) PRIMARY KEY,
            country_name TEXT NOT null, 
            loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

CREATE TABLE dds.users (
    user_id SERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL,
    user_email VARCHAR(255) UNIQUE NOT NULL,
    country_code CHAR(2),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_user_country 
        FOREIGN KEY (country_code) 
        REFERENCES dds.countries(country_code)
);

CREATE TABLE dds.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) UNIQUE NOT NULL,
    current_price DECIMAL(10, 2) NOT null, 
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dds.transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price DECIMAL(10, 2) NOT NULL,           
    total_amount DECIMAL(12, 2) NOT NULL,   
    transaction_date TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_trans_user 
        FOREIGN KEY (user_id) 
        REFERENCES dds.users(user_id),
        
    CONSTRAINT fk_trans_product 
        FOREIGN KEY (product_id) 
        REFERENCES dds.products(product_id)
);


DROP TABLE IF EXISTS dds.transactions;
DROP TABLE IF EXISTS dds.products;
DROP TABLE IF exists dds.users
DROP TABLE IF exists dds.countries


select * from dds.countries
limit 100;

select * from dds.users
limit 100;

select * from dds.products
limit 100;

select * from dds.transactions
limit 100;

select 
	c.country_code, 
	c.country_name,
	sum(t.total_amount) as total_sales,
	avg(t.total_amount) as avg_transactions_value,
	count(*) as transactions_count
from dds.transactions t
join dds.users u on u.user_id = t.user_id 
join dds.countries c on c.country_code = u.country_code 
group by c.country_code;


create table if not exists analytics.transaction_stats_by_country (
		country_code String,
		country_name String,
		total_sales Decimal(15, 2),
		avg_transactions_value Decimal(10, 2),
		transactions_count UInt64)
	engine = SummingMergeTree()
	order by country_code; 
	
	
	
select * from analytics.transaction_stats_by_country
order by total_sales desc; 
