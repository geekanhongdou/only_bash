import time
import json
import urllib.request
import urllib.parse
import hashlib
import sys

from urllib.parse import urlparse
url="https://raw.githubusercontent.com/DATAHOARDERS/dynamic-rules/main/onlyfans.json"
dynamic_rules=json.loads(urllib.request.urlopen(urllib.request.Request(url)).read().decode('utf-8'))

def create_signed_headers(link: str, auth_id: int, dynamic_rules: dict):
    # Users: 300000 | Creators: 301000
    final_time = str(int(round(time.time()*1000)))
    path = urllib.parse.urlparse(link).path
    query = urllib.parse.urlparse(link).query
    path = path if not query else f"{path}?{query}"
    a = [dynamic_rules["static_param"], final_time, path, str(auth_id)]
    msg = "\n".join(a)
    message = msg.encode("utf-8")
    hash_object = hashlib.sha1(message)
    sha_1_sign = hash_object.hexdigest()
    sha_1_b = sha_1_sign.encode("ascii")
    checksum = (
        sum([sha_1_b[number] for number in dynamic_rules["checksum_indexes"]])
        + dynamic_rules["checksum_constant"]
    )
    return dynamic_rules["format"].format(sha_1_sign, abs(checksum)) + '|' + final_time

print(create_signed_headers(str(sys.argv[1]), str(sys.argv[2]), dynamic_rules))
