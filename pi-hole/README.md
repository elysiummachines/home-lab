## Pi-hole Wiki:

**Pi-hole is a network-wide ad blocker that operates as a DNS sinkhole to protect devices from unwanted content without the need to install client-side software. It was created by Jacob Salmela in 2014 as an open-source alternative to AdTrap**. The project quickly gained popularity and now has a large and active community of contributors. 

**ITs a advertising-aware DNS/Web server,** makes use of the following technologies: `dnsmasq` - a lightweight DNS and DHCP server, `curl` - A command-line tool for transferring data with URL syntax `lighttpd` - web server designed and optimized for high performance `php` - a popular general-purpose web scripting language `AdminLTE Dashboard` - premium admin control panel based on Bootstrap 3. `xsqlite3` - SQL Database engine

** It functions by intercepting DNS requests and checking them against a list of known advertising and tracking domains. If a match is found, Pi-hole blocks the request, preventing ads from being downloaded.** This approach differs from traditional ad blockers, which typically run as browser extensions and only hide ads after they have been downloaded.

Pi-hole is highly configurable and **supports custom block and allow lists. It can be installed on various platforms, including Raspberry Pi,** which makes it a popular choice for home networks. The software uses a modified version of dnsmasq called `FTLDNS` to handle DNS queries and blocking. **It can act as a forwarding DNS (`by defeult`) or configured to act as a recursive** 

## Key Features:

  - ***Network-wide Ad Blocking*** - Pi-hole blocks ads for all devices on the network by acting as a `DNS` server. This includes ads on websites, as well as in apps and on smart `TVs`.
  - ***Custom Block/Allow Lists*** - Users can configure their own lists of domains to block or allow, providing fine-grained control over content.
  - ***Web Interface: Pi-hole includes*** - a web-based interface for monitoring `DNS` queries, configuring settings, and viewing statistics.
  - ***Low Resource Usage*** - Designed to run on low-power devices like the Raspberry Pi, Pi-hole is efficient and requires minimal resources.
  - ***Privacy Protection*** - By blocking trackers and ad domains, Pi-hole enhances user privacy by preventing data collection from various sources.
 
## Best Practices:

- When working with Pi-hole, it’s crucial to follow best practices to ensure security, efficiency, and maintainability. Best practices are essential for maintaining a secure, efficient, and reliable network-wide ad blocker environment. Here are the key practices:

  -  ***Configure DNS Settings Properly*** -
Ensure that your Pi-hole is configured to use reliable and privacy-respecting upstream DNS servers. Consider using `DNS` over `HTTPS` (DoH) or `DNS` over `TLS` (DoT) for added privacy.

  - ***Enable Query Logging and Privacy Levels*** -
Enable query logging to monitor DNS requests and configure the appropriate privacy level to balance logging detail with user privacy. `Command: pihole -a logging`

  - ***Implement Custom Block and Allow Lists*** -
Regularly update and customize your block lists to improve ad blocking effectiveness. Maintain a whitelist for domains that should always be allowed.

## Standard Pi-hole Process:

  - ***Client asks Pi-hole Who is pi-hole.net***
  - ***Pi-hole check its cache and reply if the answer is already known.***
  - ***Pi-hole checks the blocking lists and reply if the domain is blocked.***
  - ***If it can't Pi-hole forwards the request to external upstream DNS server.***
  - ***Pi-hole will reply to client and tell it the answer to its request once it has it from upstream.***
  - ***Pi-hole will save the answer in cache to be able to respond faster if any clients queries the same domain again.***

##
> Pi-hole is widely used in home networks to block ads and protect privacy across all devices. It is also employed in small to medium office environments to reduce bandwidth usage and improve browsing speeds by blocking unwanted content at the network level.