##python script to check s3 bucket compliance and output a csv

import boto3
import csv

s3 = boto3.client("s3", region_name="us-east-1")
buckets = s3.list_buckets()["Buckets"]

def check_bucket(bucket_name):
    public = False
    encrypted = False
    versioning = False

    # Check public access
    try:
        acl = s3.get_bucket_acl(Bucket=bucket_name)
        for grant in acl["Grants"]:
            if "AllUsers" in str(grant):
                public = True
    except Exception as e:
        print(f"[{bucket_name}] Error checking ACL: {e}")

    # Check encryption
    try:
        s3.get_bucket_encryption(Bucket=bucket_name)
        encrypted = True
    except s3.exceptions.ClientError as e:
        if e.response['Error']['Code'] != 'ServerSideEncryptionConfigurationNotFoundError':
            print(f"[{bucket_name}] Error checking encryption: {e}")

    # Check versioning
    try:
        versioning_status = s3.get_bucket_versioning(Bucket=bucket_name)
        versioning = versioning_status.get("Status") == "Enabled"
    except Exception as e:
        print(f"[{bucket_name}] Error checking versioning: {e}")

    return {
        "Bucket": bucket_name,
        "Public": public,
        "Encrypted": encrypted,
        "Versioning": versioning,
        "Compliant": not public and encrypted and versioning,
    }

# Scan and write results
with open("s3_compliance_report.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["Bucket", "Public", "Encrypted", "Versioning", "Compliant"])
    writer.writeheader()

    for bucket in buckets:
        result = check_bucket(bucket["Name"])
        writer.writerow(result)
        print(result)
