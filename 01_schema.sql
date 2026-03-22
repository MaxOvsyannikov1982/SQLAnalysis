-- Таблица пользователей
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY, -- SERIAL сам инкрементирует ID
    reg_date DATE NOT NULL,
    city VARCHAR(50) NOT NULL,
	last_order_date DATE NULL
);

-- Таблица товаров
CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL -- Точность до 2 знаков после запятой
);

-- Таблица заказов
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE, -- Внешний ключ на Users
    product_id INT REFERENCES Products(product_id) ON DELETE CASCADE, -- Внешний ключ на Products
    order_date DATE NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0), -- Проверка, что штук > 0
    status VARCHAR(20) DEFAULT 'Completed' -- Статус для фильтрации
);