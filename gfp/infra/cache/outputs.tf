output "redis_endpoint" {
  value = length(aws_elasticache_cluster.gfp_cache.cache_nodes) > 0 ? aws_elasticache_cluster.gfp_cache.cache_nodes[0].address : aws_elasticache_cluster.gfp_cache.cluster_address
}
