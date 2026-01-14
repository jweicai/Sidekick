#!/usr/bin/env python3
"""
创建测试 Parquet 文件
"""

try:
    import pyarrow as pa
    import pyarrow.parquet as pq
    import pandas as pd
    
    # 创建示例数据
    df = pd.DataFrame({
        'id': [1, 2, 3, 4, 5],
        'name': ['张三', '李四', '王五', '赵六', '钱七'],
        'age': [25, 30, 35, 40, 45],
        'city': ['北京', '上海', '深圳', '广州', '杭州'],
        'salary': [50000.0, 60000.0, 70000.0, 80000.0, 90000.0]
    })
    
    # 转换为 Arrow Table
    table = pa.Table.from_pandas(df)
    
    # 写入 Parquet 文件
    pq.write_table(table, 'sample_data/test.parquet')
    
    print("✅ 成功创建测试 Parquet 文件: sample_data/test.parquet")
    print(f"   行数: {len(df)}")
    print(f"   列数: {len(df.columns)}")
    
except ImportError:
    print("⚠️  PyArrow 未安装，使用 DuckDB 创建测试文件...")
    print("请手动测试 Parquet 功能")
