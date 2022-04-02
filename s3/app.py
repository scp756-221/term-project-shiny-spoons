"""
SFU CMPT 756
Metadata micro service
"""

# Standard library modules
import logging
import sys
import time

# Installed packages
from flask import Blueprint
from flask import Flask
from flask import request
from flask import Response

import jwt

from prometheus_flask_exporter import PrometheusMetrics

import requests

import simplejson as json

# The application

app = Flask(__name__)

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'User process')

bp = Blueprint('app', __name__)

db = {
    "name": "http://cmpt756db:30002/api/v1/datastore",
    "endpoint": [
        "read",
        "write",
        "delete",
        "update"
    ]
}


@bp.route('/', methods=['GET'])
@metrics.do_not_track()
def hello_world():
    return ("If you are reading this in a browser, your service is "
            "operational. Switch to curl/Postman/etc to interact using the "
            "other HTTP verbs.")


@bp.route('/health')
@metrics.do_not_track()
def health():
    return Response("HEALTH OK", status=200, mimetype="application/json")


@bp.route('/readiness')
@metrics.do_not_track()
def readiness():
    return Response("", status=200, mimetype="application/json")


@bp.route('/update_metadata/<music_id>', methods=['PUT'])
def update_metadata(music_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}),
                        status=401,
                        mimetype='application/json')
    try:
        content = request.get_json()
        link = content['video_link']
        country = content['artist_country']
        duration = content['song_duration']
    except Exception:
        return json.dumps({"message": "error reading arguments"})
    payload = {"objtype": "music", "objkey": music_id}
    url = db['name'] + '/' + db['endpoint'][3]
    response = requests.put(
        url,
        params=payload,
        json={
            "VideoLink": link,
            "ArtistCountry": country,
            "SongDuration": duration},
        headers={'Authorization': headers['Authorization']})
    return (response.json())

@bp.route('/update_metadata/<music_id>, methods=['DELETE'])
def delete_metadata(music_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}),
                        status=401,
                        mimetype='application/json')
    payload = {"objtype": "music", "objkey": music_id}
    url = db['name'] + '/' + db['endpoint'][3]
    response = requests.delete(
        url,
        params=payload,
        headers={'Authorization': headers['Authorization']})
    return (response.json())

@bp.route('/update_metadata/<music_id>, methods=['GET'])
def get_metadata(music_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}),
                        status=401,
                        mimetype='application/json')
    payload = {"objtype": "music", "objkey": music_id}
    url = db['name'] + '/' + db['endpoint'][3]
    response = requests.get(
        url,
        params=payload,
        headers={'Authorization': headers['Authorization']})
    return (response.json())


# @bp.route('/update_metadata/<music_id>', methods=['PUT'])
# def update_metadata(music_id):
#     headers = request.headers
#     # check header here
#     if 'Authorization' not in headers:
#         return Response(json.dumps({"error": "missing auth"}),
#                         status=401,
#                         mimetype='application/json')
#     try:
#         content = request.get_json()
#         link = content['video_link']
#         country = content['artist_country']
#         duration = content['song_duration']
#     except Exception:
#         return json.dumps({"message": "error reading arguments"})
#     payload = {"objtype": "music", "objkey": music_id}
#     url = db['name'] + '/load'  # + db['endpoint'][3]
#     response = requests.post(
#         url,
#         # params=payload,
#         json={
#             "objtype": "music",
#             "VideoLink": link,
#             "ArtistCountry": country,
#             "SongDuration": duration,
#             "uuid": music_id
#         },
#         headers={'Authorization': headers['Authorization']})
#     print(response)
#     return (response.json())


# All database calls will have this prefix.  Prometheus metric
# calls will not---they will have route '/metrics'.  This is
# the conventional organization.
app.register_blueprint(bp, url_prefix='/api/v1/metadata/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("Usage: app.py <service-port>")
        sys.exit(-1)

    p = int(sys.argv[1])
    # Do not set debug=True---that will disable the Prometheus metrics
    app.run(host='0.0.0.0', port=p, threaded=True)
