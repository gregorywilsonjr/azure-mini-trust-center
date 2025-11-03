import os, argparse
from azure.storage.blob import BlobServiceClient

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument('--file', required=True)
  ap.add_argument('--container', required=True)
  ap.add_argument('--path', required=True)
  args = ap.parse_args()

  conn = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
  if not conn:
    raise SystemExit("Set AZURE_STORAGE_CONNECTION_STRING")

  bsc = BlobServiceClient.from_connection_string(conn)
  blob = bsc.get_blob_client(container=args.container, blob=args.path)
  with open(args.file,'rb') as f:
    blob.upload_blob(f, overwrite=True)
  print("Uploaded to", f"{args.container}/{args.path}")

if __name__ == '__main__':
  main()
