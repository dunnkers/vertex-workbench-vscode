#!/usr/bin/env python3

"""
Script that configures and registeers a Vertex Workbench VM with an inverting
proxy so that it can be accessed through the web browser from the console
(using the 'Open JupyterLab' button under Vertex Workbench).

Essentially performs the following steps:
* Registers the VM on the inverting proxy for the VM's region.
* Starts the proxy-agent on the VM using Docker.
* Sets metadata attributes on the VM informing Workbench where to send traffic.

For more info about the proxy see: https://github.com/google/inverting-proxy.
"""

from enum import Enum
from dataclasses import dataclass
import json
import logging
import subprocess
from typing import Any, Dict, List, Iterable, Optional, TypeVar
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError

AGENT_CONTAINER_NAME = "proxy-agent"
AGENT_CONTAINER_URL = "gcr.io/inverting-proxy/agent"

T = TypeVar("T")

logging.basicConfig(format="[%(asctime)s] %(message)s", level=logging.INFO)


class ProxyMode(Enum):
    """Enum of all possible proxy modes."""
    MAIL = "mail"
    NONE = "none"
    PROJECT_EDITORS = "project_editors"
    SERVICE_ACCOUNT = "service_account"
    USE_IAM = "use_iam"


@dataclass
class ProxyRegisterResult:
    """Utility class for storing the result of registering on the proxy."""
    backend_id: str
    hostname: str


def main() -> None:
    """
    Main function that registers the VM on the Workbench inverting proxy for the given region,
    starts the proxy agent on the VM and informs Workbench where to forward traffic by setting
    the required metadata on the VM.
    """

    # Fetch information about our instance.
    instance_id = get_instance_id()
    instance_name = get_instance_name()
    instance_region = get_instance_region()
    instance_zone = get_instance_zone()
    project_id = get_project_id()

    # Get proxy url for the region.
    proxy_url = get_proxy_url(region=instance_region)

    # Register the VM with the proxy so that it knows we exist. This returns a backend ID
    # and hostname that we can use for setting up the connection.
    registration = register_with_proxy(
        proxy_url=proxy_url, proxy_mode=get_proxy_mode(), proxy_mail=get_proxy_mail()
    )

    # Stop the proxy-agent if it's already running.
    stop_existing_agent()

    # Start a new agent with the received backend ID. This agent will subscribe to the
    # proxy and set up the forwarding connection.
    start_agent(
        backend_id=registration.backend_id,
        proxy_url=proxy_url,
        project_id=project_id,
        instance_id=instance_id,
        instance_zone=instance_zone,
    )

    # Update the VM's metadata with the new proxy URL so that the Workbench service knows
    # where to find us (this is crucial for the 'Open JupyterLab' button to show up in the
    # console). Beside this, we also set some extra metadata (title/framework/version) so
    # that the Workbench UI correctly shows which image the VM is running.
    set_instance_metadata(
        instance_name=instance_name,
        instance_zone=instance_zone,
        values={
            "proxy-url": registration.hostname,
            "title": "OpenVSCode with Pyenv and Poetry",
            "framework": "OpenVSCode/Pyenv/Poetry",
            "version": "latest"
        }
    )


def register_with_proxy(proxy_url: str, proxy_mode: ProxyMode, proxy_mail: Optional[str]) -> ProxyRegisterResult:
    """Registers the VM on the inverting proxy using a given mode."""

    logging.info(
        f"Registering on proxy '{proxy_url}' with mode '{proxy_mode.value}'"
        + f" and email '{proxy_mail}'"
        if proxy_mail is not None
        else ""
    )
    proxy_endpoint = f"{proxy_url}/request-endpoint"

    vm_identity = get_vm_identity(proxy_endpoint)
    access_token = get_access_token()

    headers = {
        "X-Inverting-Proxy-VM-ID": vm_identity,
        "Authorization": f"Bearer {access_token}",
    }

    if proxy_mode == ProxyMode.MAIL:
        if proxy_mail is None:
            raise ValueError("proxy_mail should be given if proxy mode is mail")
        result = request(proxy_endpoint, headers=headers, data=proxy_mail.encode())
    elif proxy_mode in (ProxyMode.PROJECT_EDITORS, ProxyMode.SERVICE_ACCOUNT):
        result = request(proxy_endpoint, headers=headers, data=b"")
    elif proxy_mode == ProxyMode.USE_IAM:
        result = request(
            proxy_endpoint, headers=headers, params={"usercustomiam": "true"}
        )
    else:
        raise Exception(f"Unsupported proxy-mode: {proxy_mode.value}")

    result_json = json.loads(result.decode())
    register_result = ProxyRegisterResult(
        backend_id=result_json["backendID"], hostname=result_json["hostname"]
    )

    logging.info(
        f"Received backend ID '{register_result.backend_id}' and hostname '{register_result.hostname}'"
    )

    return register_result


def stop_existing_agent() -> None:
    """Stops an existing proxy agent if already running in Docker."""

    ps_result = subprocess.run(
        ["docker", "ps", "-a", "-q", "-f", f"name={AGENT_CONTAINER_NAME}"],
        check=True,
        capture_output=True,
    )
    container_id = ps_result.stdout.decode().strip()

    if container_id:
        logging.info(f"Stopping existing agent container '{container_id}'")
        subprocess.run(
            ["docker", "stop", container_id], check=True, capture_output=True
        )
        subprocess.run(["docker", "rm", container_id], check=True, capture_output=True)


def start_agent(
    backend_id: str,
    proxy_url: str,
    project_id: str,
    instance_id: str,
    instance_zone: str,
    port: int = 8080,
    health_check_path: str = "/",
    health_check_interval_seconds: int = 30,
    proxy_timeout: str = "60s",
) -> None:
    """Starts a new instance of the proxy agent in Docker."""

    env = {
        "BACKEND": backend_id,
        "PROXY": proxy_url,
        "PROXY_TIMEOUT": proxy_timeout,
        "SHIM_WEBSOCKETS": "false",
        "SHIM_PATH": "websocket-shim",
        "PORT": str(port),
        "HEALTH_CHECK_PATH": health_check_path,
        "HEALTH_CHECK_INTERVAL_SECONDS": health_check_interval_seconds,
        "MONITORING_PROJECT_ID": project_id,
        "MONITORING_RESOURCE_LABELS": f"instance-id=${instance_id},instance-zone=${instance_zone}",
        "METRIC_DOMAIN": "notebooks.googleapis.com",
        "DEBUG": "false",
    }

    logging.info(f"Starting agent container with config: {json.dumps(env)}")

    env_args: List[str] = flatten([("--env", f"{key}={value}") for key, value in env.items()])

    result = subprocess.run(
        [
            "docker",
            "run",
            "-d",
            "--net",
            "host",
            "--restart",
            "always",
            "--name",
            AGENT_CONTAINER_NAME,
        ]
        + env_args
        + [AGENT_CONTAINER_URL],
        check=True,
        capture_output=True
    )

    container_id = result.stdout.decode().strip()
    logging.info(f"Agent container running under ID '{container_id}'")


def set_instance_metadata(instance_name: str, instance_zone: str, values: Dict[str, str]) -> None:
    """Sets metadata values on a compute instance VM."""

    logging.info(
        f"Setting metadata {values} on instance '{instance_name}' in zone '{instance_zone}'"
    )

    value_str = ",".join(f"{key}={value}" for key, value in values.items())
    subprocess.run(
        [
            "timeout",
            "30",
            "gcloud",
            "compute",
            "instances",
            "add-metadata",
            instance_name,
            "--metadata",
            value_str,
            "--zone",
            instance_zone,
        ],
        check=True,
        capture_output=True,
    )


def request(
    url: str,
    params: Optional[Dict[str, str]] = None,
    data: Optional[bytes] = None,
    headers: Optional[Dict[str, str]] = None,
) -> bytes:
    """Performs an HTTP request using urllib and returns the content of the result."""

    headers = headers or {}

    if params is not None:
        query_string = urlencode(params)
        url = url + "?" + query_string

    req = Request(url, data=data)

    for key, value in headers.items():
        req.add_header(key, value)

    result = urlopen(req)
    content: bytes = result.read()

    return content


def get_metadata_value(key: str) -> Optional[str]:
    """Fetches the requested metadata value from the current VM."""
    try:
        return request(
            url=f"http://metadata/computeMetadata/v1/{key}",
            headers={"Metadata-Flavor": "Google"},
        ).decode()
    except HTTPError:
        return None


def get_required_metadata_value(key: str) -> str:
    """Fetches the requested metadata value, erroring if it doesn't exist."""
    return require(get_metadata_value(key), name=key)


def get_attribute_value(key: str) -> Optional[str]:
    """Fetches the requested attribute value from the current VM."""
    try:
        return get_metadata_value(f"instance/attributes/{key}")
    except HTTPError:
        return None


def get_project_id() -> str:
    """Fetches the project ID of the current VM."""
    return get_required_metadata_value("project/project-id")


def get_instance_id() -> str:
    """Fetches the instance ID of the current VM."""
    return get_required_metadata_value("instance/id")


def get_instance_name() -> str:
    """Fetches the instance name of the current VM."""
    return get_required_metadata_value("instance/name")


def get_instance_zone(short: bool=True) -> str:
    """Fetches the instance zone of the current VM."""
    zone = get_required_metadata_value("instance/zone")
    return zone.split("/")[-1] if short else zone


def get_instance_region() -> str:
    """Fetches the instance region of the current VM."""
    zone = get_instance_zone(short=True)
    return zone.rsplit("-", 1)[0]


def get_vm_identity(audience: str) -> str:
    """Fetches an identify token for the current VM with the given audience."""
    return get_required_metadata_value(
        f"instance/service-accounts/default/identity?format=full&audience={audience}"
    )


def get_proxy_mode() -> ProxyMode:
    """Fetches the proxy mode for the current VM (as specified by the proxy-mode attribute)."""

    if get_attribute_value("proxy-mode") is not None:
        proxy_mode = ProxyMode(get_attribute_value("proxy-mode"))
    elif get_attribute_value("proxy-user-mail") is not None:
        proxy_mode = ProxyMode.MAIL
    else:
        proxy_mode = ProxyMode.NONE

    return proxy_mode


def get_proxy_mail() -> Optional[str]:
    """
    Fetches the proxy email for the current VM (as specified by the proxy-mode attribute).
    Only valid if proxy-mode is email.
    """
    return get_attribute_value("proxy-user-mail")


def get_proxy_url(region: str) -> str:
    """Fetches the proxy url for the given region."""
    if get_attribute_value("proxy-registration-url") is not None:
        logging.info(f"Using proxy URL from metadata")
        proxy_url = require(get_attribute_value("proxy-registration-url"), name="proxy-registrion-url")
    else:
        logging.info(f"Fetching proxy config for region '{region}'")
        proxy_config = get_proxy_config(region=region)
        proxy_url = proxy_config["agent-docker-containers"]["latest"]["proxy-url"]
    return proxy_url


def get_proxy_config(region: str) -> Dict[str, Any]:
    """Fetches the proxy configuration for the given region."""
    result = request(f"https://storage.googleapis.com/dl-platform-public-configs/regionalized-configs/proxy-agent-config-{region}.json")
    return json.loads(result.decode()) # type: ignore


def get_access_token() -> str:
    """Fetches an access token for the current VM."""
    result = subprocess.run(
        ["gcloud", "auth", "print-access-token"], check=True, capture_output=True
    )
    return result.stdout.decode().strip()


def flatten(nested_list: List[Iterable[T]]) -> List[T]:
    """Utility function for flattening a nested list."""
    return [item for sublist in nested_list for item in sublist]


def require(value: Optional[T], name: str="Value") -> T:
    if value is None:
        raise ValueError(f"{name} should not be None")
    return value


if __name__ == "__main__":
    main()
