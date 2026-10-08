"""Five-minute health check for the otelnew RUM ingest proxy.

Prints one JSON line. The Coralogix Lambda telemetry exporter ships that line
to the customer account. Alerts in that account watch dns_ok and cert_status.
"""

import json
import os
import random
import socket
import ssl
import struct
import urllib.error
import urllib.request

def main():
    hostname = os.environ["HOSTNAME"]
    expected_cname = os.environ["EXPECTED_CNAME"].rstrip(".").lower()
    tenant_id = os.environ["TENANT_ID"]
    probe_url = os.environ["PROBE_URL"]
    cname, dns_error = lookup_cname(hostname)
    dns_ok = cname == expected_cname
    cert_status, cert_error = certificate_status(tenant_id)
    probe_status, probe_error = probe(probe_url)
    # 403 means the edge function is serving and refused a request with no
    # cxforward target. Any other TLS or HTTP failure means the proxy is down.
    probe_ok = probe_status == 403

    print(
        json.dumps(
            {
                "dns_ok": dns_ok,
                "cert_status": cert_status,
                "probe_ok": probe_ok,
                "hostname": hostname,
                "cname": cname,
                "expected_cname": expected_cname,
                "probe_status": probe_status,
                "dns_error": dns_error,
                "cert_error": cert_error,
                "probe_error": probe_error,
            },
            separators=(",", ":"),
        )
    )


def lookup_cname(name):
    try:
        packet = dns_query(name, 5)
        answers = parse_answers(packet)
        for rtype, rdata in answers:
            if rtype == 5:
                return rdata.rstrip(".").lower(), None
        return "", "no CNAME in answer"
    except Exception as error:
        return "", str(error)


def certificate_status(tenant_id):
    try:
        import boto3

        client = boto3.client("cloudfront")
        response = client.get_managed_certificate_details(Identifier=tenant_id)
        details = response.get("ManagedCertificateDetails") or response
        status = details.get("CertificateStatus")
        if not status:
            return "unknown", "certificate status missing from response"
        return status, None
    except Exception as error:
        return "unknown", str(error)


def probe(url):
    try:
        request = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(request, timeout=8) as response:
            return response.status, None
    except urllib.error.HTTPError as error:
        return error.code, None
    except Exception as error:
        return 0, str(error)


def dns_query(name, qtype, server="8.8.8.8"):
    transaction = random.randint(0, 65535)
    header = struct.pack(">HHHHHH", transaction, 0x0100, 1, 0, 0, 0)
    question = encode_name(name) + struct.pack(">HH", qtype, 1)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(3)
    try:
        sock.sendto(header + question, (server, 53))
        data, _ = sock.recvfrom(4096)
    finally:
        sock.close()
    if len(data) < 12 or struct.unpack(">H", data[:2])[0] != transaction:
        raise RuntimeError("unexpected DNS response")
    return data


def parse_answers(packet):
    _, _, qdcount, ancount, _, _ = struct.unpack(">HHHHHH", packet[:12])
    offset = 12
    for _ in range(qdcount):
        _, offset = read_name(packet, offset)
        offset += 4
    answers = []
    for _ in range(ancount):
        _, offset = read_name(packet, offset)
        rtype, _, _, rdlength = struct.unpack(">HHIH", packet[offset : offset + 10])
        offset += 10
        rdata = packet[offset : offset + rdlength]
        if rtype == 5:
            target, _ = read_name(packet, offset)
            answers.append((rtype, target))
        else:
            answers.append((rtype, ""))
        offset += rdlength
    return answers


def read_name(packet, offset):
    labels = []
    jumped = False
    end = offset
    guard = 0
    while guard < 128:
        guard += 1
        length = packet[offset]
        if length == 0:
            if not jumped:
                end = offset + 1
            break
        if length & 0xC0 == 0xC0:
            pointer = struct.unpack(">H", packet[offset : offset + 2])[0] & 0x3FFF
            if not jumped:
                end = offset + 2
            offset = pointer
            jumped = True
            continue
        offset += 1
        labels.append(packet[offset : offset + length].decode("ascii"))
        offset += length
        if not jumped:
            end = offset
    return ".".join(labels), end


def encode_name(name):
    encoded = b""
    for label in name.rstrip(".").split("."):
        encoded += bytes([len(label)]) + label.encode("ascii")
    return encoded + b"\x00"


if __name__ == "__main__":
    main()
