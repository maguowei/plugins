package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	_ "github.com/go-sql-driver/mysql" // MySQL driver
	_ "github.com/mattn/go-sqlite3"    // SQLite driver

	"{{ .GoModule }}/{{ .Paths.Infrastructure }}/config"
	"{{ .GoModule }}/internal/ent"
	"{{ .GoModule }}/internal/ent/migrate"
)

func main() {
	// 解析命令行参数
	var (
		drop  = flag.Bool("drop", false, "Drop all tables before migration")
		debug = flag.Bool("debug", false, "Enable debug mode")
	)
	flag.Parse()

	// 1. 加载配置
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 2. 连接数据库
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer client.Close()

	ctx := context.Background()

	// 3. 配置迁移选项
	opts := []migrate.Option{
		migrate.WithDropIndex(true),
		migrate.WithDropColumn(true),
	}

	if *debug {
		client = client.Debug()
		log.Println("Debug mode enabled")
	}

	// 4. 执行迁移
	if *drop {
		log.Println("Dropping all tables...")
		if err := client.Schema.Create(
			ctx,
			append(opts, migrate.WithDropColumn(true))...,
		); err != nil {
			log.Fatalf("Failed to drop tables: %v", err)
		}
		log.Println("All tables dropped successfully")
	}

	log.Println("Running database migrations...")
	if err := client.Schema.Create(ctx, opts...); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	log.Println("Database migrations completed successfully")

	// 5. 打印迁移统计
	printMigrationStats(ctx, client)
}

// printMigrationStats 打印迁移统计信息
func printMigrationStats(ctx context.Context, client *ent.Client) {
	{{- if .IncludeExamples }}
	// 统计表记录数
	{{ .Aggregate.Name }}Count, err := client.{{ .Entity.Name }}.Query().Count(ctx)
	if err != nil {
		log.Printf("Failed to count {{ .Aggregate.Name }}: %v", err)
	} else {
		fmt.Printf("{{ .Entity.NameCN }}表: %d 条记录\n", {{ .Aggregate.Name }}Count)
	}
	{{- else }}
	fmt.Println("No tables to count (examples not included)")
	{{- end }}
}

func init() {
	// 设置日志前缀
	log.SetPrefix("[{{ .Project.Name }}-migrate] ")
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// 打印使用说明
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\nOptions:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  %s              # Run migrations\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -drop        # Drop all tables and recreate\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -debug       # Enable debug mode\n", os.Args[0])
	}
}
