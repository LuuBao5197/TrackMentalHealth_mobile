from flask import Flask, request, jsonify
from flask_cors import CORS
import face_recognition
import numpy as np
import cv2
import pyodbc
import base64

app = Flask(__name__)
CORS(app)

# SQL Server connection (chỉnh theo config của bạn)
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=REQUIN\\MSSQLSERVER01;"
    "DATABASE=TMH1;"
    "UID=sa;"
    "PWD=123;"
)
conn = pyodbc.connect(conn_str)


# ===============================
# 1. Generate embedding khi đăng ký
# ===============================
@app.route("/generate-embedding", methods=["POST"])
def generate_embedding():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files["image"].read()
    nparr = np.frombuffer(file, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    face_locations = face_recognition.face_locations(img)
    if not face_locations:
        return jsonify({"error": "No face detected"}), 400

    embedding = face_recognition.face_encodings(img, face_locations)[0]

    # Trả về JSON (chuyển thành list float)
    return jsonify(embedding.tolist())


# ===============================
# 2. Verify face khi login
# ===============================
@app.route("/verify-face", methods=["POST"])
def verify_face():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files["image"].read()
    nparr = np.frombuffer(file, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    face_locations = face_recognition.face_locations(img)
    if not face_locations:
        return jsonify({"error": "No face detected"}), 400

    embedding = face_recognition.face_encodings(img, face_locations)[0]

    # Lấy embeddings từ DB
    cursor = conn.cursor()
    cursor.execute("SELECT id, user_id, embedding FROM user_face_embeddings")
    rows = cursor.fetchall()

    for row in rows:
        db_id, user_id, embedding_str = row
        db_embedding = np.array(eval(embedding_str))  # convert string JSON -> numpy array

        distance = np.linalg.norm(db_embedding - embedding)
        if distance < 0.45:  # threshold, có thể chỉnh
            return jsonify({"userId": user_id})

    return jsonify({"error": "No matching user"}), 401


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
