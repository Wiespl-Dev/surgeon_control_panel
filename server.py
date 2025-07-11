from flask import Flask, jsonify
from obsws_python import ReqClient
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow requests from Flutter if needed

host = "192.168.1.103"
port = 4455
password = "helloa"

try:
    ws = ReqClient(host=host, port=port, password=password)
except Exception as e:
    print("Connection error:", e)
    ws = None

@app.route("/status")
def status():
    try:
        ws.get_version()
        return jsonify({"connected": True})
    except:
        return jsonify({"connected": False})

@app.route("/start_recording")
def start_recording():
    try:
        ws.start_record()
        return jsonify({"status": "recording_started"})
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route("/stop_recording")
def stop_recording():
    try:
        ws.stop_record()
        return jsonify({"status": "recording_stopped"})
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route("/toggle_source/<scene>/<source>")
def toggle_source(scene, source):
    try:
        res = ws.get_scene_item_list(sceneName=scene)
        item = next((i for i in res["sceneItems"] if i["sourceName"] == source), None)
        if item:
            visible = not item["sceneItemEnabled"]
            ws.set_scene_item_enabled(sceneName=scene, sceneItemId=item["sceneItemId"], sceneItemEnabled=visible)
            return jsonify({"status": "toggled", "visible": visible})
        else:
            return jsonify({"error": "source not found"})
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route("/scenes")
def scenes():
    try:
        res = ws.get_scene_list()
        scene_names = [scene["sceneName"] for scene in res["scenes"]]
        return jsonify(scene_names)
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route("/switch_scene/<scene_name>")
def switch_scene(scene_name):
    try:
        ws.set_current_program_scene(scene_name)
        return jsonify({"status": "scene_switched"})
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
