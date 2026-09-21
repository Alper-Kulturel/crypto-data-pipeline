CREATE TABLE IF NOT EXISTS trades (
    id BIGSERIAL PRIMARY KEY,
    symbol TEXT NOT NULL,
    trade_id BIGINT NOT NULL,
    price NUMERIC(20, 8) NOT NULL,
    quantity NUMERIC(20, 8) NOT NULL,
    is_buyer_maker BOOLEAN,
    trade_time TIMESTAMPTZ NOT NULL,
    ingested_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (symbol, trade_id)
);

CREATE INDEX idx_trades_symbol_time ON trades (symbol, trade_time DESC);
CREATE INDEX idx_trades_time ON trades (trade_time DESC);