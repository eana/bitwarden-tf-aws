#!/usr/bin/env python3

import boto3
import sys
from datetime import datetime, timedelta

DEFAULT_AVAILABILITY_ZONE = "eu-north-1b"
DEFAULT_INSTANCE_TYPES = [
    "t4g.nano",
    "t4g.micro",
    "t4g.small",
    "t4g.medium",
    "t4g.large",
    "c7g.medium",
    "c6g.medium",
]


def get_spot_instances(region, availability_zone, instance_types):
    ec2_client = boto3.client("ec2", region_name=region)
    spot_instances = []
    for instance_type in instance_types:
        spot_prices = ec2_client.describe_spot_price_history(
            InstanceTypes=[instance_type],
            ProductDescriptions=["Linux/UNIX"],
            AvailabilityZone=availability_zone,
            MaxResults=10,
            StartTime=(datetime.now() - timedelta(hours=1)).isoformat(),
        )
        if "SpotPriceHistory" in spot_prices:
            spot_instances.extend(spot_prices["SpotPriceHistory"])
    return spot_instances


def display_help():
    print(
        "Usage: python script.py [--help] [--az <availability_zone>] [--instance-type <instance_type1> <instance_type2> ...]"
    )
    sys.exit(0)


if __name__ == "__main__":
    if "--help" in sys.argv:
        display_help()
    availability_zone = DEFAULT_AVAILABILITY_ZONE
    region = availability_zone[:-1]
    instance_types = DEFAULT_INSTANCE_TYPES
    az_index = sys.argv.index("--az") if "--az" in sys.argv else None
    if az_index is not None:
        availability_zone = sys.argv[az_index + 1]
        region = availability_zone[:-1]
    instance_type_index = (
        sys.argv.index("--instance-type") if "--instance-type" in sys.argv else None
    )
    if instance_type_index is not None:
        instance_types = sys.argv[instance_type_index + 1 :]
    spot_instances = get_spot_instances(region, availability_zone, instance_types)
    if spot_instances:
        print(f"Availability Zone: {availability_zone}")
        sorted_instances = sorted(spot_instances, key=lambda x: float(x["SpotPrice"]))
        for instance in sorted_instances:
            print(f"{instance['InstanceType']} - {instance['SpotPrice']}")
    else:
        print(
            f"No spot instances found in {availability_zone} for the specified instance types"
        )
