package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	Server     ServerConfig
	Database   DatabaseConfig
	Logging    LoggingConfig
	Sentry     SentryConfig
	Prometheus PrometheusConfig
}

type ServerConfig struct {
	Port int
	Mode string
}

type DatabaseConfig struct {
	Driver       string
	DSN          string
	MaxOpenConns int `mapstructure:"max_open_conns"`
	MaxIdleConns int `mapstructure:"max_idle_conns"`
}

type LoggingConfig struct {
	Level  string
	Format string
}

type SentryConfig struct {
	DSN         string
	Environment string
}

type PrometheusConfig struct {
	Enabled bool
	Path    string
}

// Load 从配置文件和环境变量加载配置
func Load(path string) (*Config, error) {
	viper.SetConfigFile(path)
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		return nil, err
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}
