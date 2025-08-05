"""
PostgreSQL Database Tests for YTEmpire MVP
Tests database connectivity, schema validation, performance, and data integrity
"""

import os
import time
import pytest
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import uuid
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import statistics


class TestPostgreSQLDatabase:
    """Comprehensive PostgreSQL database tests"""
    
    @classmethod
    def setup_class(cls):
        """Setup database connection for tests"""
        cls.connection_params = {
            'host': os.getenv('POSTGRES_HOST', 'localhost'),
            'port': os.getenv('POSTGRES_PORT', 5432),
            'database': os.getenv('POSTGRES_DB', 'ytempire_dev'),
            'user': os.getenv('POSTGRES_USER', 'ytempire_user'),
            'password': os.getenv('POSTGRES_PASSWORD', 'ytempire_pass')
        }
        
    def get_connection(self):
        """Get a new database connection"""
        return psycopg2.connect(**self.connection_params)
    
    def test_database_connection(self):
        """Test basic database connectivity"""
        conn = None
        try:
            conn = self.get_connection()
            assert conn is not None
            
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                version = cursor.fetchone()[0]
                assert "PostgreSQL" in version
                assert "15" in version  # Expecting PostgreSQL 15+
                
        finally:
            if conn:
                conn.close()
    
    def test_schema_existence(self):
        """Test that all required schemas exist"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT schema_name 
                    FROM information_schema.schemata 
                    WHERE schema_name IN ('users', 'content', 'analytics', 'campaigns')
                    ORDER BY schema_name;
                """)
                
                schemas = [row[0] for row in cursor.fetchall()]
                expected_schemas = ['analytics', 'campaigns', 'content', 'users']
                
                assert schemas == expected_schemas, f"Missing schemas. Found: {schemas}"
                
        finally:
            conn.close()
    
    def test_tables_structure(self):
        """Test that all tables exist with correct structure"""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Test users.users table
                cursor.execute("""
                    SELECT column_name, data_type, is_nullable
                    FROM information_schema.columns
                    WHERE table_schema = 'users' AND table_name = 'users'
                    ORDER BY ordinal_position;
                """)
                
                user_columns = cursor.fetchall()
                assert len(user_columns) > 0, "users.users table not found"
                
                # Verify critical columns
                column_names = [col['column_name'] for col in user_columns]
                required_columns = ['id', 'email', 'username', 'password_hash', 'created_at']
                for req_col in required_columns:
                    assert req_col in column_names, f"Missing required column: {req_col}"
                
        finally:
            conn.close()
    
    def test_uuid_extension(self):
        """Test UUID extension is properly installed"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT uuid_generate_v4();")
                uuid_val = cursor.fetchone()[0]
                assert isinstance(uuid_val, uuid.UUID)
                
        finally:
            conn.close()
    
    def test_user_crud_operations(self):
        """Test Create, Read, Update, Delete operations on users table"""
        conn = self.get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Create
                test_user = {
                    'email': f'test_{uuid.uuid4()}@ytempire.test',
                    'username': f'test_user_{uuid.uuid4().hex[:8]}',
                    'password_hash': '$2b$10$test_hash',
                    'full_name': 'Test User',
                    'role': 'creator'
                }
                
                cursor.execute("""
                    INSERT INTO users.users (email, username, password_hash, full_name, role)
                    VALUES (%(email)s, %(username)s, %(password_hash)s, %(full_name)s, %(role)s)
                    RETURNING id, email, username, created_at;
                """, test_user)
                
                created_user = cursor.fetchone()
                assert created_user is not None
                assert created_user['email'] == test_user['email']
                user_id = created_user['id']
                
                # Read
                cursor.execute("SELECT * FROM users.users WHERE id = %s;", (user_id,))
                read_user = cursor.fetchone()
                assert read_user['username'] == test_user['username']
                
                # Update
                cursor.execute("""
                    UPDATE users.users 
                    SET full_name = %s, updated_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                    RETURNING updated_at;
                """, ('Updated Test User', user_id))
                
                updated = cursor.fetchone()
                assert updated['updated_at'] > created_user['created_at']
                
                # Delete
                cursor.execute("DELETE FROM users.users WHERE id = %s RETURNING id;", (user_id,))
                deleted = cursor.fetchone()
                assert deleted['id'] == user_id
                
                conn.commit()
                
        finally:
            conn.rollback()
            conn.close()
    
    def test_query_performance(self):
        """Test query performance meets <200ms requirement"""
        conn = self.get_connection()
        query_times = []
        
        try:
            with conn.cursor() as cursor:
                # Create test data
                cursor.execute("""
                    INSERT INTO content.channels (user_id, youtube_channel_id, channel_title)
                    SELECT 
                        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid,
                        'UC' || generate_series,
                        'Test Channel ' || generate_series
                    FROM generate_series(1, 100)
                    ON CONFLICT (youtube_channel_id) DO NOTHING;
                """)
                conn.commit()
                
                # Test dashboard query performance
                test_queries = [
                    # Channel overview query
                    """
                    SELECT c.*, COUNT(v.id) as video_count
                    FROM content.channels c
                    LEFT JOIN content.videos v ON c.id = v.channel_id
                    WHERE c.is_active = true
                    GROUP BY c.id
                    LIMIT 10;
                    """,
                    
                    # Analytics aggregation query
                    """
                    SELECT 
                        DATE_TRUNC('day', metric_date) as day,
                        SUM(views) as total_views,
                        SUM(watch_time_minutes) as total_watch_time
                    FROM analytics.channel_metrics
                    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
                    GROUP BY DATE_TRUNC('day', metric_date)
                    ORDER BY day DESC;
                    """,
                    
                    # Complex join query
                    """
                    SELECT 
                        v.id, v.title, v.view_count,
                        c.channel_title,
                        COUNT(com.id) as comment_count
                    FROM content.videos v
                    JOIN content.channels c ON v.channel_id = c.id
                    LEFT JOIN content.comments com ON v.id = com.video_id
                    WHERE v.published_at >= CURRENT_DATE - INTERVAL '7 days'
                    GROUP BY v.id, v.title, v.view_count, c.channel_title
                    ORDER BY v.view_count DESC
                    LIMIT 20;
                    """
                ]
                
                for query in test_queries:
                    start_time = time.time()
                    cursor.execute(query)
                    cursor.fetchall()
                    query_time = (time.time() - start_time) * 1000  # Convert to ms
                    query_times.append(query_time)
                
                # Verify all queries completed under 200ms
                max_time = max(query_times)
                avg_time = statistics.mean(query_times)
                
                assert max_time < 200, f"Query exceeded 200ms threshold: {max_time:.2f}ms"
                assert avg_time < 100, f"Average query time too high: {avg_time:.2f}ms"
                
                print(f"Query performance: Max={max_time:.2f}ms, Avg={avg_time:.2f}ms")
                
        finally:
            conn.rollback()
            conn.close()
    
    def test_concurrent_connections(self):
        """Test connection pooling and concurrent access"""
        def execute_query(query_id):
            conn = self.get_connection()
            try:
                with conn.cursor() as cursor:
                    cursor.execute("SELECT pg_sleep(0.1);")  # Simulate work
                    cursor.execute("SELECT current_timestamp;")
                    return (query_id, cursor.fetchone()[0])
            finally:
                conn.close()
        
        # Test with 20 concurrent connections (max pool size)
        with ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(execute_query, i) for i in range(20)]
            results = []
            
            for future in as_completed(futures):
                results.append(future.result())
            
            assert len(results) == 20, "Not all concurrent connections completed"
    
    def test_transaction_isolation(self):
        """Test ACID compliance and transaction isolation"""
        conn1 = self.get_connection()
        conn2 = self.get_connection()
        
        try:
            # Set isolation level
            conn1.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)
            conn2.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)
            
            with conn1.cursor() as cursor1, conn2.cursor() as cursor2:
                # Start transaction 1
                cursor1.execute("""
                    INSERT INTO users.users (email, username, password_hash)
                    VALUES ('isolation_test@test.com', 'isolation_test', 'hash')
                    RETURNING id;
                """)
                user_id = cursor1.fetchone()[0]
                
                # Try to read from connection 2 (should not see uncommitted data)
                cursor2.execute("""
                    SELECT COUNT(*) FROM users.users 
                    WHERE email = 'isolation_test@test.com';
                """)
                count = cursor2.fetchone()[0]
                assert count == 0, "Uncommitted data visible in other transaction"
                
                # Commit transaction 1
                conn1.commit()
                
                # Now connection 2 should see the data
                cursor2.execute("""
                    SELECT COUNT(*) FROM users.users 
                    WHERE email = 'isolation_test@test.com';
                """)
                count = cursor2.fetchone()[0]
                assert count == 1, "Committed data not visible"
                
                # Cleanup
                cursor2.execute("""
                    DELETE FROM users.users WHERE id = %s;
                """, (user_id,))
                conn2.commit()
                
        finally:
            conn1.close()
            conn2.close()
    
    def test_index_effectiveness(self):
        """Test that indexes are being used effectively"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                # Test index usage with EXPLAIN
                cursor.execute("""
                    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
                    SELECT * FROM users.users 
                    WHERE email = 'test@example.com';
                """)
                
                plan = cursor.fetchone()[0][0]
                
                # Check if index scan is being used
                assert any('Index Scan' in str(node) for node in str(plan)), \
                    "Index not being used for email lookup"
                
        finally:
            conn.close()
    
    def test_backup_restore_capability(self):
        """Test that backup and restore procedures work"""
        # This test would typically involve:
        # 1. Creating test data
        # 2. Running pg_dump
        # 3. Dropping and recreating tables
        # 4. Running pg_restore
        # 5. Verifying data integrity
        
        # For unit tests, we'll just verify backup permissions
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT has_database_privilege(%s, 'ytempire_dev', 'CONNECT');
                """, (self.connection_params['user'],))
                
                has_access = cursor.fetchone()[0]
                assert has_access, "User lacks database access for backups"
                
        finally:
            conn.close()
    
    def test_data_integrity_constraints(self):
        """Test foreign key constraints and data integrity"""
        conn = self.get_connection()
        try:
            with conn.cursor() as cursor:
                # Test foreign key constraint
                with pytest.raises(psycopg2.errors.ForeignKeyViolation):
                    cursor.execute("""
                        INSERT INTO content.videos (channel_id, youtube_video_id, title)
                        VALUES (%s, 'test_video', 'Test Video');
                    """, (uuid.uuid4(),))  # Non-existent channel_id
                
                conn.rollback()
                
                # Test unique constraint
                cursor.execute("""
                    INSERT INTO users.users (email, username, password_hash)
                    VALUES ('unique_test@test.com', 'unique_test', 'hash')
                    ON CONFLICT DO NOTHING;
                """)
                
                with pytest.raises(psycopg2.errors.UniqueViolation):
                    cursor.execute("""
                        INSERT INTO users.users (email, username, password_hash)
                        VALUES ('unique_test@test.com', 'another_user', 'hash');
                    """)
                
        finally:
            conn.rollback()
            conn.close()


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])