
USE master;
GO

-- Crear la base de datos si no existe

CREATE DATABASE BikeStoresDW;

USE BikeStoresDW;
GO

-- =============================================
-- DIMENSIÓN: DimDate (Dimensión de Tiempo)
-- =============================================
drop table if exists DimDate;
CREATE TABLE DimDate (
    date_key INT PRIMARY KEY,              -- Formato: YYYYMMDD
    date DATE NOT NULL,
    year SMALLINT NOT NULL,
    year_month INT NULL,
    quarter TINYINT NOT NULL,
    month TINYINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day TINYINT NOT NULL,
    day_of_week TINYINT NOT NULL,          -- 1=Domingo, 7=Sábado
    day_name VARCHAR(20) NOT NULL,
    week TINYINT NOT NULL,
    is_weekend BIT NOT NULL,
    is_holiday BIT NOT NULL DEFAULT 0,
    holiday_name VARCHAR(50) NULL
);
GO

-- =============================================
-- DIMENSIÓN: DimProduct (SCD Tipo 1)
-- Descripción: Productos 
-- =============================================
drop table if exists DimProduct;
CREATE TABLE DimProduct (
    product_key INT IDENTITY(1,1) NOT NULL,     -- surrogate key
    product_id INT NOT NULL,                                -- business key
    brand_id INT NOT NULL,                                  -- business key
    category_id INT NOT NULL,                               -- business key
    
    product_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255) NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DECIMAL(10, 2) NOT NULL,

    CONSTRAINT PK_Product PRIMARY KEY (product_key)
);
GO


CREATE INDEX IX_DimProduct_ProductID ON DimProduct(product_id);
GO

-- =============================================
-- DIMENSIÓN: DimCustomer (SCD Tipo 2)
-- Descripción: Clientes con historial de cambios de ubicación
-- Atributos que cambian: city, state, zip_code
-- =============================================
drop table if exists DimCustomer;
CREATE TABLE DimCustomer (
    customer_key INT IDENTITY(1,1) NOT NULL,  --  Key
    customer_id INT NOT NULL,                     -- Business Key
    full_name VARCHAR(510) NOT NULL,              -- Formato: "first_name last_name"
    city VARCHAR(50) NULL,
    state VARCHAR(25) NULL,
    zip_code VARCHAR(5) NULL,

    -- Campos SCD Tipo 2
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    is_current BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_Customer PRIMARY KEY (customer_key)
);
GO

CREATE INDEX IX_DimCustomer_CustomerID ON DimCustomer(customer_id);
CREATE INDEX IX_DimCustomer_IsCurrent ON DimCustomer(is_current);
GO

-- =============================================
-- DIMENSIÓN: DimStaff (SCD Tipo 2)
-- Descripción: Empleados que procesan las órdenes
-- Atributos que cambian: store_id, manager_id
-- =============================================
drop table if exists DimStaff;
CREATE TABLE DimStaff (
    staff_key INT IDENTITY(1,1) NOT NULL,    --  Key
    staff_id INT NOT NULL UNIQUE,                -- Business Key
    full_name VARCHAR(101) NOT NULL,             -- Formato: "first_name last_name"
    
    store_id INT NOT NULL,  

    manager_id INT NULL,
    
    -- Campos SCD Tipo 2
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    is_current BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_Staff PRIMARY KEY (staff_key)
);
GO

CREATE INDEX IX_DimStaff_StaffID ON DimStaff(staff_id);
GO

-- =============================================
-- DIMENSIÓN: DimStore (SCD Tipo 1)
-- Descripción: Tiendas/Sucursales
-- =============================================
drop table if exists DimStore;
CREATE TABLE DimStore (
    store_key INT IDENTITY(1,1) NOT NULL,    --  Key
    store_id INT NOT NULL UNIQUE,                -- Business Key
    store_name VARCHAR(255) NOT NULL,
    city VARCHAR(255) NULL,
    state VARCHAR(10) NULL,
    zip_code VARCHAR(5) NULL,

    CONSTRAINT PK_Store PRIMARY KEY (store_key)
    
);
GO

CREATE INDEX IX_DimStore_StoreID ON DimStore(store_id);
GO

-- =============================================
-- DIMENSIÓN: DimOrder (SCD Tipo 1)
-- Descripción: Información de las órdenes
-- =============================================
drop table if exists DimOrder;
CREATE TABLE DimOrder (
    order_key INT IDENTITY(1,1) NOT NULL,    --  Key
    order_id INT NOT NULL UNIQUE,                -- Business Key
    order_status TINYINT NOT NULL,
    status_description VARCHAR(50) NOT NULL,      -- Pending, Processing, Rejected, Completed
    
    CONSTRAINT PK_Order PRIMARY KEY (order_key)
);
GO

CREATE INDEX IX_DimOrder_OrderID ON DimOrder(order_id);
GO

-- =============================================
-- DIMENSIÓN: DimInventory (SCD Tipo 1)
-- Descripción: Inventario de productos por tienda
-- =============================================
drop table if exists DimStock;
CREATE TABLE DimStock (
    Stock_key INT IDENTITY(1,1) NOT NULL,           --  Key
    store_id INT NOT NULL,                        -- Business Key
    store_name VARCHAR(255) NOT NULL,
    product_id INT NOT NULL,                      -- Business Key
    product_name VARCHAR(255) NOT NULL,
    quantity INT NULL,                            -- Cantidad en stock
    
    CONSTRAINT PK_Stock PRIMARY KEY (Stock_key)
);
GO

CREATE INDEX IX_DimStock_StoreID ON DimStock(store_id);
CREATE INDEX IX_DimStock_ProductID ON DimStock(product_id);
GO

-- =============================================
-- TABLA DE HECHOS: FactSales
-- Descripción: Hechos de ventas a nivel de línea de orden
-- Granularidad: Una fila por cada item en una orden
-- =============================================
drop table if exists FactSales;
CREATE TABLE FactSales (
    sales_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Claves foráneas a dimensiones (surrogate keys)
    product_key INT NOT NULL,
    customer_key INT NOT NULL,
    staff_key INT NOT NULL,
    store_key INT NOT NULL,
    order_key INT NOT NULL,
    order_date_key INT NOT NULL,                -- Fecha de emisión de la orden
    required_date_key INT NOT NULL,             -- Fecha requerida
    shipped_date_key INT NULL,                  -- Fecha de envío (puede ser NULL)

    
    quantity INT NOT NULL,
    list_price DECIMAL(10, 2) NOT NULL,
    discount_percentage DECIMAL(4, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10, 2) NOT NULL,    -- Calculado
    net_sales_amount DECIMAL(10, 2) NOT NULL,   -- Calculado: (list_price * quantity) - discount_amount

    invoice_count INT NOT NULL DEFAULT 1,       -- Para contar órdenes únicas


    -- Constraints (FKs a dimensiones)
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (product_key) 
        REFERENCES DimProduct(product_key),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (customer_key) 
        REFERENCES DimCustomer(customer_key),
    CONSTRAINT FK_FactSales_DimStaff FOREIGN KEY (staff_key) 
        REFERENCES DimStaff(staff_key),
    CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (store_key) 
        REFERENCES DimStore(store_key),
    CONSTRAINT FK_FactSales_DimOrder FOREIGN KEY (order_key) 
        REFERENCES DimOrder(order_key),
    CONSTRAINT FK_FactSales_OrderDate FOREIGN KEY (order_date_key) 
        REFERENCES DimDate(date_key),
    CONSTRAINT FK_FactSales_RequiredDate FOREIGN KEY (required_date_key) 
        REFERENCES DimDate(date_key),
    CONSTRAINT FK_FactSales_ShippedDate FOREIGN KEY (shipped_date_key) 
        REFERENCES DimDate(date_key)
);

GO

-- Índices para optimizar consultas
CREATE INDEX IX_FactSales_ProductKey ON FactSales(product_key);
CREATE INDEX IX_FactSales_CustomerKey ON FactSales(customer_key);
CREATE INDEX IX_FactSales_StaffKey ON FactSales(staff_key);
CREATE INDEX IX_FactSales_StoreKey ON FactSales(store_key);
CREATE INDEX IX_FactSales_OrderKey ON FactSales(order_key);
CREATE INDEX IX_FactSales_OrderDateKey ON FactSales(order_date_key);
CREATE INDEX IX_FactSales_RequiredDateKey ON FactSales(required_date_key);
CREATE INDEX IX_FactSales_ShippedDateKey ON FactSales(shipped_date_key);
GO


-- =============================================
-- PROCEDIMIENTO: Población de DimDate
-- Descripción: Genera fechas desde 2016 hasta 2030 con feriados de Costa Rica
-- =============================================

CREATE PROCEDURE sp_DimDatePopulate
    @start_date DATE = '2016-01-01',
    @end_date DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @current_date DATE = @start_date;
    
    -- Paso 1: Insertar todas las fechas
    WHILE @current_date <= @end_date
    BEGIN
        INSERT INTO DimDate (
            date_key,
            date,
            year,
            year_month,
            quarter,
            month,
            month_name,
            day,
            day_of_week,
            day_name,
            week,
            is_weekend,
            is_holiday,
            holiday_name
        )
        VALUES (
            CAST(FORMAT(@current_date, 'yyyyMMdd') AS INT),                          -- date_key (ej: 20250107)
            @current_date,                                                            -- date
            YEAR(@current_date),                                                      -- year
            CAST(FORMAT(@current_date, 'yyyyMM') AS INT),                            -- year_month (ej: 202501)
            DATEPART(QUARTER, @current_date),                                         -- quarter (1-4)
            MONTH(@current_date),                                                     -- month (1-12)
            DATENAME(MONTH, @current_date),                                           -- month_name (January, February...)
            DAY(@current_date),                                                       -- day (1-31)
            DATEPART(WEEKDAY, @current_date),                                         -- day_of_week (1=Sunday, 7=Saturday)
            DATENAME(WEEKDAY, @current_date),                                         -- day_name (Sunday, Monday...)
            DATEPART(WEEK, @current_date),                                            -- week (1-53)
            CASE WHEN DATEPART(WEEKDAY, @current_date) IN (1, 7) THEN 1 ELSE 0 END,  -- is_weekend
            0,                                                                        -- is_holiday (default, se actualiza después)
            NULL                                                                      -- holiday_name (se actualiza después)
        );
        
        SET @current_date = DATEADD(DAY, 1, @current_date);
    END
    
    -- Paso 2: Actualizar feriados de Costa Rica
    
    -- Año Nuevo (1 de enero)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Año Nuevo'
    WHERE month = 1 AND day = 1;
    
    -- Día de Juan Santamaría (11 de abril)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Día de Juan Santamaría'
    WHERE month = 4 AND day = 11;
    
    -- Jueves Santo (variable - jueves antes de Semana Santa)
    -- Viernes Santo (calculado como viernes antes del Domingo de Pascua)
    -- Nota: Implementación simplificada para Semana Santa
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Semana Santa'
    WHERE month = 4 AND day_name IN ('Thursday', 'Friday') 
      AND day BETWEEN 1 AND 20;  -- Aproximación, Semana Santa suele ser en marzo-abril
    
    -- Día del Trabajo (1 de mayo)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Día del Trabajo'
    WHERE month = 5 AND day = 1;
    
    -- Anexión de Guanacaste (25 de julio)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Anexión de Guanacaste'
    WHERE month = 7 AND day = 25;
    
    -- Día de la Madre (15 de agosto)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Día de la Madre'
    WHERE month = 8 AND day = 15;
    
    -- Día de la Independencia (15 de septiembre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Independencia de Costa Rica'
    WHERE month = 9 AND day = 15;
    
    -- Día de las Culturas (12 de octubre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Día de las Culturas'
    WHERE month = 10 AND day = 12;

    -- Día de la Abolición del Ejército (1 de diciembre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Día de la Abolición del Ejército'
    WHERE month = 12 AND day = 1;
    
    -- Navidad (25 de diciembre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Navidad'
    WHERE month = 12 AND day = 25;
    
    -- Paso 3: Feriados comerciales importantes para retail
    
    -- Día del Padre (tercer domingo de junio)
    UPDATE d
    SET is_holiday = 1, holiday_name = 'Día del Padre'
    FROM DimDate d
    WHERE month = 6 
      AND day_of_week = 1  -- Domingo
      AND day BETWEEN 15 AND 21;  -- Tercer domingo
    
    -- Black Friday (último viernes de noviembre)
    UPDATE d
    SET is_holiday = 1, holiday_name = 'Black Friday'
    FROM DimDate d
    WHERE month = 11 
      AND day_of_week = 6  -- Viernes
      AND day >= 23;  -- Último viernes
    
    -- Cyber Monday (lunes después de Black Friday)
    UPDATE d
    SET is_holiday = 1, holiday_name = 'Cyber Monday'
    FROM DimDate d
    WHERE month = 11 
      AND day_of_week = 2  -- Lunes
      AND day >= 25;  -- Lunes después del último viernes
    
    -- Nochebuena (24 de diciembre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Nochebuena'
    WHERE month = 12 AND day = 24;
    
    -- Fin de Año (31 de diciembre)
    UPDATE DimDate 
    SET is_holiday = 1, holiday_name = 'Fin de Año'
    WHERE month = 12 AND day = 31;
END
GO

-- Ejecutar el procedimiento para popular DimDate
EXEC sp_DimDatePopulate;
GO



