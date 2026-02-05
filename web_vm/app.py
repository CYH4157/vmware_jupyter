from flask import Flask
import mysql.connector

app = Flask(__name__)

DB_HOST = "x.x.145.x"      # 改成 DB VM 私網 IP
DB_NAME = "demo"
DB_USER = "demo"
DB_PASS = ""			# 設定密碼
DB_PORT = 3306

'''
def query_rows():
    conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        connection_timeout=5,
    )
    cur = conn.cursor(dictionary=True)
    cur.execute("SELECT id, msg FROM test ORDER BY id DESC LIMIT 50;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows
'''

def query_rows():
    conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        connection_timeout=5,
    )
    cur = conn.cursor(dictionary=True)

    # 先查你連到哪台 DB
    cur.execute("SELECT @@hostname AS host, @@port AS port, DATABASE() AS db;")
    dbinfo = cur.fetchone()

    # 查資料：明確指定欄位（包含 created_at）
    cur.execute("SELECT id, msg, created_at FROM test ORDER BY id DESC LIMIT 50;")
    rows = cur.fetchall()

    cur.close()
    conn.close()
    return dbinfo, rows

'''
@app.get("/")
def index():
    rows = query_rows()
    html = ["<h2>DB rows (demo.test)</h2>", "<ul>"]
    for r in rows:
        html.append(f"<li>#{r['id']} - {r['msg']} ({r['created_at']})</li>")
    html.append("</ul>")
    return "\n".join(html)
'''

@app.get("/")
def index():
    dbinfo, rows = query_rows()

    html = [
        "<h2>DB Info</h2>",
        f"<pre>{dbinfo}</pre>",
        "<h2>Rows</h2><ul>",
    ]

    if rows:
        html.append(f"<pre>row_keys={list(rows[0].keys())}</pre>")

    for r in rows:
        html.append(f"<li>#{r.get('id')} - {r.get('msg')} ({r.get('created_at')})</li>")

    html.append("</ul>")
    return "\n".join(html)





if __name__ == "__main__":
    # 讓同網段可連（只測試用）
    app.run(host="0.0.0.0", port=8080, debug=True)
