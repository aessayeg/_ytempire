#!/usr/bin/env python3
"""
YTEmpire Database Debug Utility
Debug and analyze PostgreSQL queries with execution plans
"""

import argparse
import asyncio
import json
import sys
from datetime import datetime
from typing import Any, Dict, List, Optional

import asyncpg
import pandas as pd
from rich.console import Console
from rich.table import Table
from rich.syntax import Syntax
from rich.panel import Panel
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

console = Console()


class DatabaseDebugger:
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.engine = create_engine(database_url, echo=True)
        self.Session = sessionmaker(bind=self.engine)
        
    async def analyze_query(self, query: str, explain: bool = True) -> Dict[str, Any]:
        """Analyze a SQL query with execution plan"""
        result = {
            "query": query,
            "timestamp": datetime.now().isoformat(),
            "execution_plan": None,
            "statistics": None,
            "results": None,
            "error": None
        }
        
        try:
            with self.Session() as session:
                # Get execution plan
                if explain:
                    explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"
                    plan_result = session.execute(text(explain_query))
                    result["execution_plan"] = plan_result.fetchone()[0]
                    
                    # Extract key metrics
                    plan = result["execution_plan"][0]["Plan"]
                    result["statistics"] = {
                        "total_cost": plan.get("Total Cost"),
                        "actual_time": plan.get("Actual Total Time"),
                        "rows_returned": plan.get("Actual Rows"),
                        "planning_time": result["execution_plan"][0].get("Planning Time"),
                        "execution_time": result["execution_plan"][0].get("Execution Time")
                    }
                
                # Execute actual query
                query_result = session.execute(text(query))
                rows = query_result.fetchall()
                columns = query_result.keys()
                
                # Convert to list of dicts
                result["results"] = [
                    dict(zip(columns, row)) for row in rows[:100]  # Limit to 100 rows
                ]
                result["row_count"] = len(rows)
                
        except Exception as e:
            result["error"] = str(e)
            console.print(f"[red]Error: {e}[/red]")
            
        return result
    
    def display_results(self, analysis: Dict[str, Any]):
        """Display query analysis results in a formatted way"""
        
        # Display query
        console.print(Panel(
            Syntax(analysis["query"], "sql", theme="monokai"),
            title="SQL Query",
            border_style="blue"
        ))
        
        # Display execution statistics
        if analysis["statistics"]:
            stats_table = Table(title="Execution Statistics")
            stats_table.add_column("Metric", style="cyan")
            stats_table.add_column("Value", style="green")
            
            for key, value in analysis["statistics"].items():
                if value is not None:
                    stats_table.add_row(key.replace("_", " ").title(), str(value))
            
            console.print(stats_table)
        
        # Display results preview
        if analysis["results"]:
            results_table = Table(title=f"Results Preview (showing {min(10, len(analysis['results']))} of {analysis['row_count']} rows)")
            
            # Add columns
            for col in analysis["results"][0].keys():
                results_table.add_column(col)
            
            # Add rows (limit to 10)
            for row in analysis["results"][:10]:
                results_table.add_row(*[str(v) for v in row.values()])
            
            console.print(results_table)
        
        # Display execution plan summary
        if analysis["execution_plan"]:
            console.print("\n[yellow]Execution Plan Summary:[/yellow]")
            self._display_plan_node(analysis["execution_plan"][0]["Plan"], indent=0)
    
    def _display_plan_node(self, node: Dict[str, Any], indent: int = 0):
        """Recursively display execution plan nodes"""
        prefix = "  " * indent + "→ " if indent > 0 else ""
        node_type = node.get("Node Type", "Unknown")
        
        # Format node information
        info = f"{prefix}[cyan]{node_type}[/cyan]"
        if "Relation Name" in node:
            info += f" on [green]{node['Relation Name']}[/green]"
        if "Index Name" in node:
            info += f" using [yellow]{node['Index Name']}[/yellow]"
        if "Actual Total Time" in node:
            info += f" ({node['Actual Total Time']:.2f}ms)"
        
        console.print(info)
        
        # Display child nodes
        if "Plans" in node:
            for child in node["Plans"]:
                self._display_plan_node(child, indent + 1)
    
    async def monitor_connections(self):
        """Monitor active database connections"""
        query = """
        SELECT 
            pid,
            usename,
            application_name,
            client_addr,
            state,
            query_start,
            state_change,
            wait_event_type,
            wait_event,
            LEFT(query, 100) as query_preview
        FROM pg_stat_activity
        WHERE state != 'idle'
        ORDER BY query_start DESC
        """
        
        result = await self.analyze_query(query, explain=False)
        
        if result["results"]:
            table = Table(title="Active Database Connections")
            table.add_column("PID", style="cyan")
            table.add_column("User", style="green")
            table.add_column("Application", style="yellow")
            table.add_column("State", style="magenta")
            table.add_column("Query Preview", style="white")
            
            for conn in result["results"]:
                table.add_row(
                    str(conn.get("pid", "")),
                    str(conn.get("usename", "")),
                    str(conn.get("application_name", "")),
                    str(conn.get("state", "")),
                    str(conn.get("query_preview", ""))[:50] + "..."
                )
            
            console.print(table)
    
    async def analyze_table_stats(self, schema: str, table: str):
        """Analyze table statistics and indexes"""
        # Table size and statistics
        size_query = f"""
        SELECT 
            pg_size_pretty(pg_total_relation_size('{schema}.{table}')) as total_size,
            pg_size_pretty(pg_relation_size('{schema}.{table}')) as table_size,
            pg_size_pretty(pg_indexes_size('{schema}.{table}')) as indexes_size,
            n_live_tup as live_rows,
            n_dead_tup as dead_rows,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        FROM pg_stat_user_tables
        WHERE schemaname = '{schema}' AND relname = '{table}'
        """
        
        # Index information
        index_query = f"""
        SELECT 
            indexname,
            indexdef,
            pg_size_pretty(pg_relation_size(indexrelid)) as index_size
        FROM pg_indexes
        JOIN pg_stat_user_indexes USING (schemaname, tablename, indexname)
        WHERE schemaname = '{schema}' AND tablename = '{table}'
        """
        
        size_result = await self.analyze_query(size_query, explain=False)
        index_result = await self.analyze_query(index_query, explain=False)
        
        # Display table statistics
        if size_result["results"]:
            stats = size_result["results"][0]
            console.print(Panel(
                f"[cyan]Total Size:[/cyan] {stats['total_size']}\n"
                f"[cyan]Table Size:[/cyan] {stats['table_size']}\n"
                f"[cyan]Indexes Size:[/cyan] {stats['indexes_size']}\n"
                f"[cyan]Live Rows:[/cyan] {stats['live_rows']}\n"
                f"[cyan]Dead Rows:[/cyan] {stats['dead_rows']}\n"
                f"[cyan]Last Vacuum:[/cyan] {stats['last_vacuum']}\n"
                f"[cyan]Last Analyze:[/cyan] {stats['last_analyze']}",
                title=f"Table Statistics: {schema}.{table}",
                border_style="green"
            ))
        
        # Display index information
        if index_result["results"]:
            index_table = Table(title="Indexes")
            index_table.add_column("Index Name", style="cyan")
            index_table.add_column("Size", style="green")
            index_table.add_column("Definition", style="yellow")
            
            for idx in index_result["results"]:
                index_table.add_row(
                    idx["indexname"],
                    idx["index_size"],
                    idx["indexdef"][:80] + "..." if len(idx["indexdef"]) > 80 else idx["indexdef"]
                )
            
            console.print(index_table)


async def main():
    parser = argparse.ArgumentParser(description="YTEmpire Database Debug Utility")
    parser.add_argument("--query", "-q", help="SQL query to debug")
    parser.add_argument("--file", "-f", help="Read query from file")
    parser.add_argument("--explain", action="store_true", default=True, help="Show execution plan")
    parser.add_argument("--connections", action="store_true", help="Monitor active connections")
    parser.add_argument("--table-stats", help="Analyze table statistics (format: schema.table)")
    parser.add_argument("--database-url", help="Database URL (overrides environment variable)")
    
    args = parser.parse_args()
    
    # Get database URL
    database_url = args.database_url or os.getenv("DATABASE_URL")
    if not database_url:
        console.print("[red]Error: DATABASE_URL not found in environment or arguments[/red]")
        sys.exit(1)
    
    debugger = DatabaseDebugger(database_url)
    
    try:
        if args.connections:
            await debugger.monitor_connections()
        elif args.table_stats:
            parts = args.table_stats.split(".")
            if len(parts) != 2:
                console.print("[red]Error: Table must be specified as schema.table[/red]")
                sys.exit(1)
            await debugger.analyze_table_stats(parts[0], parts[1])
        elif args.query or args.file:
            # Get query
            if args.file:
                with open(args.file, 'r') as f:
                    query = f.read()
            else:
                query = args.query
            
            # Analyze and display
            result = await debugger.analyze_query(query, args.explain)
            debugger.display_results(result)
            
            # Save results to file
            output_file = f"query_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(output_file, 'w') as f:
                json.dump(result, f, indent=2, default=str)
            console.print(f"\n[green]Results saved to {output_file}[/green]")
        else:
            console.print("[yellow]No action specified. Use --help for options.[/yellow]")
            
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())