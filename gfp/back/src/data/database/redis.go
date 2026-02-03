package database

import (
	"context"
	"github.com/go-redis/redis/v8"
)

var (
	RDB *redis.Client
	Ctx = context.Background()
)

func InitRedis(addr string) error {
	RDB = redis.NewClient(&redis.Options{
		Addr: addr,
	})
	return RDB.Ping(Ctx).Err()
}
