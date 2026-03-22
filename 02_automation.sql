CREATE OR REPLACE FUNCTION update_last_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем дату последнего заказа только если он успешно завершен
    IF (NEW.status LIKE 'Com%') THEN
        UPDATE Users
        SET last_order_date = NEW.order_date
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_user_last_order
AFTER INSERT ON Orders
FOR EACH ROW
EXECUTE FUNCTION update_last_order();