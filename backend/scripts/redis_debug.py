#!/usr/bin/env python3
"""
YTEmpire Redis Cache Debug Utility
Debug and analyze Redis cache operations
"""

import argparse
import asyncio
import json
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional

import redis.asyncio as redis
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import track
import os
from dotenv import load_dotenv

load_dotenv()

console = Console()


class RedisDebugger:
    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.client = None
        
    async def connect(self):
        """Connect to Redis"""
        self.client = await redis.from_url(self.redis_url)
        await self.client.ping()
        console.print("[green]Connected to Redis[/green]")
    
    async def disconnect(self):
        """Disconnect from Redis"""
        if self.client:
            await self.client.close()
    
    async def get_key(self, key: str) -> Dict[str, Any]:
        """Get a key from Redis with metadata"""
        result = {
            "key": key,
            "exists": False,
            "type": None,
            "value": None,
            "ttl": None,
            "memory_usage": None,
            "encoding": None
        }
        
        try:
            # Check if key exists
            result["exists"] = await self.client.exists(key)
            
            if result["exists"]:
                # Get key type
                key_type = await self.client.type(key)
                result["type"] = key_type.decode() if isinstance(key_type, bytes) else key_type
                
                # Get TTL
                ttl = await self.client.ttl(key)
                result["ttl"] = ttl if ttl >= 0 else "No expiration"
                
                # Get memory usage
                memory = await self.client.memory_usage(key)
                result["memory_usage"] = f"{memory} bytes" if memory else "Unknown"
                
                # Get value based on type
                if result["type"] == "string":
                    value = await self.client.get(key)
                    result["value"] = value.decode() if isinstance(value, bytes) else value
                    # Try to parse as JSON
                    try:
                        result["value"] = json.loads(result["value"])
                    except:
                        pass
                elif result["type"] == "hash":
                    result["value"] = await self.client.hgetall(key)
                elif result["type"] == "list":
                    result["value"] = await self.client.lrange(key, 0, -1)
                elif result["type"] == "set":
                    result["value"] = await self.client.smembers(key)
                elif result["type"] == "zset":
                    result["value"] = await self.client.zrange(key, 0, -1, withscores=True)
                
        except Exception as e:
            result["error"] = str(e)
            
        return result
    
    async def set_key(self, key: str, value: str, ttl: Optional[int] = None) -> bool:
        """Set a key in Redis"""
        try:
            # Try to parse value as JSON
            try:
                value = json.dumps(json.loads(value))
            except:
                pass
            
            if ttl:
                await self.client.setex(key, ttl, value)
            else:
                await self.client.set(key, value)
            
            console.print(f"[green]Key '{key}' set successfully[/green]")
            return True
        except Exception as e:
            console.print(f"[red]Error setting key: {e}[/red]")
            return False
    
    async def delete_key(self, key: str) -> bool:
        """Delete a key from Redis"""
        try:
            result = await self.client.delete(key)
            if result:
                console.print(f"[green]Key '{key}' deleted successfully[/green]")
            else:
                console.print(f"[yellow]Key '{key}' not found[/yellow]")
            return bool(result)
        except Exception as e:
            console.print(f"[red]Error deleting key: {e}[/red]")
            return False
    
    async def search_keys(self, pattern: str) -> List[str]:
        """Search for keys matching a pattern"""
        try:
            keys = []
            async for key in self.client.scan_iter(match=pattern):
                keys.append(key.decode() if isinstance(key, bytes) else key)
            return keys
        except Exception as e:
            console.print(f"[red]Error searching keys: {e}[/red]")
            return []
    
    async def get_info(self) -> Dict[str, Any]:
        """Get Redis server information"""
        try:
            info = await self.client.info()
            return info
        except Exception as e:
            console.print(f"[red]Error getting info: {e}[/red]")
            return {}
    
    async def monitor_keys(self, pattern: str = "*", interval: int = 5):
        """Monitor keys in real-time"""
        console.print(f"[yellow]Monitoring keys matching '{pattern}' (Ctrl+C to stop)[/yellow]")
        
        try:
            while True:
                keys = await self.search_keys(pattern)
                
                # Create table
                table = Table(title=f"Redis Keys Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                table.add_column("Key", style="cyan")
                table.add_column("Type", style="green")
                table.add_column("TTL", style="yellow")
                table.add_column("Memory", style="magenta")
                table.add_column("Value Preview", style="white")
                
                for key in keys[:20]:  # Limit to 20 keys
                    key_info = await self.get_key(key)
                    
                    # Format value preview
                    value_preview = str(key_info["value"])
                    if len(value_preview) > 50:
                        value_preview = value_preview[:47] + "..."
                    
                    table.add_row(
                        key,
                        key_info["type"] or "N/A",
                        str(key_info["ttl"]) if key_info["ttl"] else "N/A",
                        key_info["memory_usage"] or "N/A",
                        value_preview
                    )
                
                console.clear()
                console.print(table)
                console.print(f"\n[cyan]Total keys: {len(keys)}[/cyan]")
                
                await asyncio.sleep(interval)
                
        except KeyboardInterrupt:
            console.print("\n[yellow]Monitoring stopped[/yellow]")
    
    async def analyze_cache_stats(self):
        """Analyze cache statistics"""
        info = await self.get_info()
        
        if not info:
            return
        
        # Server information
        server_panel = Panel(
            f"[cyan]Redis Version:[/cyan] {info.get('redis_version', 'Unknown')}\n"
            f"[cyan]Uptime:[/cyan] {info.get('uptime_in_days', 0)} days\n"
            f"[cyan]Connected Clients:[/cyan] {info.get('connected_clients', 0)}\n"
            f"[cyan]Used Memory:[/cyan] {info.get('used_memory_human', 'Unknown')}\n"
            f"[cyan]Peak Memory:[/cyan] {info.get('used_memory_peak_human', 'Unknown')}",
            title="Server Information",
            border_style="green"
        )
        console.print(server_panel)
        
        # Stats table
        stats_table = Table(title="Cache Statistics")
        stats_table.add_column("Metric", style="cyan")
        stats_table.add_column("Value", style="green")
        
        stats = {
            "Total Keys": info.get("db0", {}).get("keys", 0) if isinstance(info.get("db0"), dict) else 0,
            "Total Commands Processed": info.get("total_commands_processed", 0),
            "Instantaneous Ops/Sec": info.get("instantaneous_ops_per_sec", 0),
            "Hit Rate": f"{info.get('keyspace_hit_ratio', 0):.2%}" if 'keyspace_hit_ratio' in info else "N/A",
            "Evicted Keys": info.get("evicted_keys", 0),
            "Expired Keys": info.get("expired_keys", 0)
        }
        
        for metric, value in stats.items():
            stats_table.add_row(metric, str(value))
        
        console.print(stats_table)
        
        # Memory breakdown
        memory_table = Table(title="Memory Breakdown")
        memory_table.add_column("Category", style="cyan")
        memory_table.add_column("Size", style="green")
        
        memory_stats = {
            "Used Memory": info.get("used_memory_human", "Unknown"),
            "RSS Memory": info.get("used_memory_rss_human", "Unknown"),
            "Lua Memory": info.get("used_memory_lua_human", "Unknown"),
            "Network Buffers": info.get("mem_clients_normal", "Unknown")
        }
        
        for category, size in memory_stats.items():
            memory_table.add_row(category, str(size))
        
        console.print(memory_table)
    
    def display_key_info(self, key_info: Dict[str, Any]):
        """Display key information in a formatted way"""
        # Key metadata
        metadata_panel = Panel(
            f"[cyan]Key:[/cyan] {key_info['key']}\n"
            f"[cyan]Exists:[/cyan] {'Yes' if key_info['exists'] else 'No'}\n"
            f"[cyan]Type:[/cyan] {key_info.get('type', 'N/A')}\n"
            f"[cyan]TTL:[/cyan] {key_info.get('ttl', 'N/A')}\n"
            f"[cyan]Memory Usage:[/cyan] {key_info.get('memory_usage', 'N/A')}",
            title="Key Metadata",
            border_style="blue"
        )
        console.print(metadata_panel)
        
        # Value
        if key_info.get("value") is not None:
            console.print("\n[yellow]Value:[/yellow]")
            if isinstance(key_info["value"], (dict, list)):
                console.print_json(json.dumps(key_info["value"], indent=2))
            else:
                console.print(key_info["value"])


async def main():
    parser = argparse.ArgumentParser(description="YTEmpire Redis Cache Debug Utility")
    parser.add_argument("--operation", "-o", choices=["get", "set", "delete", "keys", "info", "monitor"], 
                       help="Operation to perform")
    parser.add_argument("--key", "-k", help="Redis key")
    parser.add_argument("--value", "-v", help="Value to set")
    parser.add_argument("--ttl", "-t", type=int, help="TTL in seconds")
    parser.add_argument("--pattern", "-p", default="*", help="Key pattern for search/monitor")
    parser.add_argument("--interval", "-i", type=int, default=5, help="Monitor interval in seconds")
    parser.add_argument("--redis-url", help="Redis URL (overrides environment variable)")
    
    args = parser.parse_args()
    
    # Get Redis URL
    redis_url = args.redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    debugger = RedisDebugger(redis_url)
    
    try:
        await debugger.connect()
        
        if args.operation == "get" and args.key:
            key_info = await debugger.get_key(args.key)
            debugger.display_key_info(key_info)
            
        elif args.operation == "set" and args.key and args.value:
            await debugger.set_key(args.key, args.value, args.ttl)
            
        elif args.operation == "delete" and args.key:
            await debugger.delete_key(args.key)
            
        elif args.operation == "keys":
            keys = await debugger.search_keys(args.pattern)
            if keys:
                table = Table(title=f"Keys matching '{args.pattern}'")
                table.add_column("Key", style="cyan")
                for key in keys:
                    table.add_row(key)
                console.print(table)
                console.print(f"\n[cyan]Total: {len(keys)} keys[/cyan]")
            else:
                console.print(f"[yellow]No keys found matching '{args.pattern}'[/yellow]")
                
        elif args.operation == "info":
            await debugger.analyze_cache_stats()
            
        elif args.operation == "monitor":
            await debugger.monitor_keys(args.pattern, args.interval)
            
        else:
            console.print("[yellow]No valid operation specified. Use --help for options.[/yellow]")
            
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        sys.exit(1)
    finally:
        await debugger.disconnect()


if __name__ == "__main__":
    asyncio.run(main())