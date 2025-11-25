CREATE DATABASE IF NOT EXISTS steam_sale_tracker;
USE steam_sale_tracker;

CREATE TABLE IF NOT EXISTS games (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    appid INT NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS price_history (
    price_id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    checked_at DATETIME NOT NULL,
    currency CHAR(3) NOT NULL,
    initial_price INT NOT NULL,
    final_price INT NOT NULL,
    discount_percent INT NOT NULL,
    CONSTRAINT fk_price_game
        FOREIGN KEY (game_id) REFERENCES games(game_id)
);
