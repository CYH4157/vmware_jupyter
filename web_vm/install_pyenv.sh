sudo apt update
sudo apt install -y python3-venv

python3 -m venv venv
source venv/bin/activate
pip install flask mysql-connector-python
python -c "import flask, mysql.connector; print('OK')"

