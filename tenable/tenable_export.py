"""Export summarized vulnerability counts from Tenable.io to JSON.

Usage:
  export TIO_ACCESS_KEY and TIO_SECRET_KEY as env vars.
  python tenable_export.py --out ../web/data/tenable.json

Optionally push to Azure Blob by setting AZURE_STORAGE_CONNECTION_STRING, then:
  python push_blob.py --file ../web/data/tenable.json --container '$web' --path 'data/tenable.json'
"""
import os, json, argparse, datetime
import urllib.request

API_BASE = "https://cloud.tenable.com"

def fetch(endpoint, headers):
    req = urllib.request.Request(API_BASE + endpoint, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode())

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='../web/data/tenable.json')
    args = ap.parse_args()

    access = os.getenv('TIO_ACCESS_KEY')
    secret = os.getenv('TIO_SECRET_KEY')
    if not (access and secret):
        raise SystemExit("Set TIO_ACCESS_KEY and TIO_SECRET_KEY")

    headers = {
        'X-ApiKeys': f'accessKey={access}; secretKey={secret}',
        'Accept': 'application/json'
    }

    # Simple rollup using workbenches/vulnerabilities
    # You may refine filters (e.g., severity, last_seen)
    vulns = fetch('/workbenches/vulnerabilities', headers)
    counts = {'critical':0,'high':0,'medium':0,'low':0}
    for v in vulns.get('vulnerabilities', []):
        sev = v.get('severity').lower()
        if sev in counts:
            counts[sev] = v.get('count', counts[sev])

    out = {
        'vulnerabilitySummary': {
            'critical': counts['critical'],
            'high': counts['high'],
            'medium': counts['medium'],
            'low': counts['low'],
            'lastScan': datetime.datetime.utcnow().replace(microsecond=0).isoformat()+'Z'
        }
    }
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, 'w') as f:
        json.dump(out, f, indent=2)
    print("Wrote", args.out)

if __name__ == '__main__':
    main()
