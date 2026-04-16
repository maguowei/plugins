package main

import (
	"context"
	"log"

	"github.com/test/mysql-test/internal/app/infrastructure/config"
	"github.com/test/mysql-test/internal/ent"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	cfg, err := config.Load("configs/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer client.Close()

	log.Println("开始数据库迁移...")
	if err := client.Schema.Create(context.Background()); err != nil {
		log.Fatalf("迁移失败: %v", err)
	}
	log.Println("数据库迁移完成")
}
