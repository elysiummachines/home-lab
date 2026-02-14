## Unbound Wiki:

**Pi-hole includes a caching and forwarding `DNS` server, now known as `FTLDNS`.** After applying the blocking lists, it forwards requests made by the clients to configured upstream DNS server. However, as has been mentioned by **several users in the past, this leads to some privacy concerns as it ultimately raises the question: Whom can you trust?** Recently, more and more small (`and not so small`) DNS upstream providers have appeared on the market, advertising free and private DNS service, but how can you know that they keep their promises? Right, you can't.

**Furthermore, from the point of an attacker, the DNS servers of larger providers are very worthwhile targets, as they only need to poison one DNS server, but millions of users might be affected.** Instead of your bank's actual IP address, you could be sent to a phishing site hosted on some island. This scenario has already happened and it isn't unlikely to happen again. When you operate your own (tiny) recursive DNS server, then the likeliness of getting affected by such an attack is greatly reduced.

## What is a recursive DNS server:
  
  - **The first distinction we have to be aware of is whether a DNS server is authoritative or not.** If I'm the authoritative server for, e.g., pi-hole.net, then I know which IP is the correct answer for a query. Recursive name servers, in contrast, resolve any query they receive by consulting the servers authoritative for this query by traversing the domain. ***Example:*** We want to resolve pi-hole.net. On behalf of the client, the recursive DNS server will traverse the path of the domain across the Internet to deliver the answer to the question.
    
  - You can easily imagine even longer chains for subdomains as the query process continues until your recursive resolver reaches the authoritative server for the zone that contains the queried domain name. **It is obvious that the methods are very different and the own recursion is more involved than "just" asking some upstream server.** This has benefits and drawbacks:
    
    ■ ***Benefit*** - Privacy - as you're directly contacting the responsive servers, no server can fully log the exact paths you're going, as e.g. the Google DNS servers will only be asked if you want to visit a Google website, but not if you visit the website of your favorite newspaper, etc.

    ■ ***Drawback*** - Traversing the path may be slow, especially for the first time you visit a website - while the bigger DNS providers always have answers for commonly used domains in their cache, you will have to traverse the path if you visit a page for the first time. The first request to a formerly unknown TLD may take up to a second (or even more if you're also using DNSSEC). Subsequent requests to domains under the same TLD usually complete in < 0.1s. Fortunately, both your Pi-hole as well as your recursive server will be configured for efficient caching to minimize the number of queries that will actually have to be performed.

## Pihole & Unbound Process:

- ***lient asks the Pi-hole Who is pi-hole.net***
- ***Pi-hole checks its cache and reply if the answer is already known.***
- ***Pi-hole Checks the blocking lists and reply if the domain is blocked.***
- ***If it can't Pi-hole it delegates the request to the (local) recursive DNS resolver.***
- ***Recursive server will send a query to the DNS root servers: "Who is handling .net?"***
- ***Root server answers with a referral to the TLD servers for .net.***
- ***Recursive server will send a query to one of the TLD DNS servers for .net: "Who is handling pi-hole.net?"***
- ***TLD server answers with a referral to the authoritative name servers for pi-hole.net.***
- ***Recursive server will send a query to the authoritative name servers: "What is the IP of pi-hole.net?"***
- ***The authoritative server will answer with the IP address of the domain pi-hole.net.***
- ***Recursive server will send the reply to your Pi-hole which will, in turn, reply to your client and tell it the answer to its request.***