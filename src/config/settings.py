from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "FIRMADOCUMENTOS"
    APP_ENV: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str = "dev-secret"
    DATABASE_URL: str = "sqlite:///./dev.db"
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_PREFIX: str = "/api/v1"
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    class Config:
        env_file = ".env"


settings = Settings()