#!/usr/bin/env python3

import boto3
import sys
from datetime import datetime, timedelta

# Default values
DEFAULT_AVAILABILITY_ZONE = "eu-west-1a"
DEFAULT_INSTANCE_TYPES = [
    "t2.nano",
    "t2.micro",
    "t2.small",
    "t3.nano",
    "t3a.nano",
    "t3.micro",
    "t3.small",
]


def get_spot_instances(region, availability_zone, instance_types):
    # Initialize AWS EC2 client
    ec2_client = boto3.client("ec2", region_name=region)

    # List to store spot instances information
    spot_instances = []

    # Iterate over specified instance types and fetch spot price history
    for instance_type in instance_types:
        spot_prices = ec2_client.describe_spot_price_history(
            InstanceTypes=[instance_type],
            ProductDescriptions=["Linux/UNIX"],
            AvailabilityZone=availability_zone,
            MaxResults=10,  # Adjust the number of results as needed
            StartTime=(datetime.now() - timedelta(hours=1)).isoformat(),
        )

        # Append spot prices to the list
        if "SpotPriceHistory" in spot_prices:
            spot_instances.extend(spot_prices["SpotPriceHistory"])

    return spot_instances


def display_help():
    # Display script usage information
    print(
        "Usage: python script.py [--help] [--az <availability_zone>] [--instance-type <instance_type1> <instance_type2> ...]"
    )
    sys.exit(0)


if __name__ == "__main__":
    # Check for help flag in command line arguments
    if "--help" in sys.argv:
        display_help()

    # Set default values
    availability_zone = DEFAULT_AVAILABILITY_ZONE
    region = availability_zone[:-1]  # Extract region from availability zone
    instance_types = DEFAULT_INSTANCE_TYPES

    # Check if --az flag is present and update availability_zone
    az_index = sys.argv.index("--az") if "--az" in sys.argv else None
    if az_index is not None:
        availability_zone = sys.argv[az_index + 1]
        region = availability_zone[:-1]  # Extract region from availability zone

    # Check if --instance-type flag is present and update instance_types
    instance_type_index = (
        sys.argv.index("--instance-type") if "--instance-type" in sys.argv else None
    )
    if instance_type_index is not None:
        instance_types = sys.argv[instance_type_index + 1 :]

    # Fetch spot instances
    spot_instances = get_spot_instances(region, availability_zone, instance_types)

    if spot_instances:
        # Print availability zone once at the beginning
        print(f"Availability Zone: {availability_zone}")

        # Sort and print spot instance details
        sorted_instances = sorted(spot_instances, key=lambda x: float(x["SpotPrice"]))
        for instance in sorted_instances:
            print(f"{instance['InstanceType']} - {instance['SpotPrice']}")
    else:
        print(
            f"No spot instances found in {availability_zone} for the specified instance types"
        )
