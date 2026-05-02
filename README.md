# Platform Toolkits

Some containers images that I build, which I find useful for debugging stuff from a Kubernetes Cluster.

## Toolkits

Below is a list of available toolkits and a brief description of what the use case is.

You can pull each one from `ghcr.io/pyrxm/ptk-${flavor}-toolkit:latest`, where `${flavor}` is identified from the below:

### Alpine Linux based

 - `network` - Network debugging tools such as `tshark`, `mtr`, `iperf` `nmap`, inspired by [nicolaka/netshoot](https://github.com/nicolaka/netshoot).
 - `proxy` - Runs [Microsocks](https://github.com/rofl0r/microsocks) to provide a lightweight SOCKS5 proxy (@TODO: Add support for `mitmproxy`)
 - `data` - Database client tools such as `mysql`, `psql` and `redis-cli`, bundled with some basic network tools to check connectivity and name resolution.

 ### Fedora Linux based

 - `platform` - Container image shipped with `chezmoi`, `mise` and `nix` and a wrapper `/entrypoint.sh` script to install tools and local configuration at runtime.

> [!WARNING]
> The `platform` image is a lot more powerful than the other images, it is intended for extremely short-lived pods troubleshooting highly specific scenarios where specialised tools are required. Never leave this pod running for longer than needed!
