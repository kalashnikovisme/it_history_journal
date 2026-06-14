---
author: "Pasha Kalashnikov"
title: "Jan 24, 2003 — A 376-Byte Virus Infected the World in 11 Minutes"
date: "January 24, 2003"
excerpt: "SQL Slammer infected 75,000 servers in 11 minutes, causing $750M–$1.2B in damage"
---

SQL Slammer virus erupted on January 24 and, in just a few hours, managed to disrupt large parts of the global internet. It was arguably the fastest-spreading worm in history.

SQL Slammer did not destroy data and did not steal anything. Its only goal was to get into the RAM of vulnerable servers and endlessly resend itself over UDP. It exploited a buffer overflow vulnerability in Microsoft SQL Server 2000, which at the time was installed on thousands of servers worldwide.

What happened that night?
All times below are in Pacific Standard Time (PST).

21:29 — Patient zero.
The first infected packet appears on the internet. The attack likely began from a server in Hong Kong or South Korea. The worm hits its first vulnerable Microsoft SQL Server 2000 instance and immediately begins blasting thousands of copies of itself to random IP addresses.

21:32 (3 minutes later)
The number of infected servers doubles every 8 seconds. Traffic becomes so dense that monitoring systems at major IT companies start showing red alert indicators.

21:40 (11 minutes later)
At least 75,000 servers are infected. Internet connectivity in South Korea collapses as links are saturated with worm traffic. Backbone routers in the United States, Europe, Japan, and Russia begin to feel the load.

22:15 (46 minutes later) — physical infrastructure failures begin.
Some of the following reports were never fully confirmed by official sources and are known primarily from witnesses:

Bank of America ATMs stop working

Check-in systems at United States airports fail as reservation systems lose access to databases

911 services in some states (Washington, Oregon) switch to paper sources because they cannot reach their databases

The Davis-Besse nuclear power station (United States) loses its safety parameter display system. Operators cannot see reactor readings for nearly five hours. Fortunately, the reactor was offline for maintenance at the time

Train service in Seattle is halted after control systems lose communication with signals and switches. Dispatchers stop trains because they can no longer guarantee safety

Police and healthcare databases in the United Kingdom either stop working or function with severe disruptions

NTT telecommunications in Japan experiences major outages

Payment systems in Australia malfunction

Major ports in Germany and the Netherlands lose the ability to track container movements

23:00 (1.5 hours later)
Microsoft security teams begin receiving calls from customers around the world. System administrators everywhere start realizing the issue is related to Microsoft SQL Server 2000 and attempt to contact Microsoft.

01:00 (3.5 hours later)
The worm is fully identified. Instructions for an emergency fix begin spreading worldwide: block or filter UDP port 1434. Administrators also discover that the worm exploits a vulnerability that Microsoft had already patched six months earlier. Only servers that had not been updated were affected.

04:00 (6.5 hours later)
The storm begins to subside. Many providers, administrators, and security teams have applied the emergency fix and started patching their Microsoft SQL Server 2000 installations.

What damage did SQL Slammer cause?
Since the worm did not destroy data or steal money, the primary damage was lost productivity and the cost of recovery. For obvious reasons, exact numbers are impossible to calculate.

Computer Economics estimated the total global damage at $750 million to $1.2 billion.

Despite this massive impact, SQL Slammer turned out to be less financially destructive than some of its contemporaries.

The “Warhol worm” idea
In 2002, three computer scientists introduced the concept of a Warhol worm — malware capable of infecting the entire internet faster than defenders can respond.

They estimated the time required to compromise the world at 15 minutes.

SQL Slammer came even closer: it infected 90 percent of all vulnerable systems in just 10 minutes. However, it does not qualify as a true Warhol worm because it did not meet all the theoretical criteria.

Fortunately, no real Warhol worm has ever been created and released.

Where did the worm come from?
The author of SQL Slammer remains unknown. It is extremely difficult to trace because the worm did not steal data and only replicated itself. Its entire size was just 376 bytes, and it contained no signature or reference to its creator.

Main hypotheses:

A deliberate attempt to demonstrate the feasibility of Warhol worms (the theory had been published just a year earlier)

An experiment that got out of hand

Always install updates!
The main reason for SQL Slammer’s success was a widespread mindset among IT professionals at the time: “If it ain’t broke, don’t fix it.”

The worm exploited a vulnerability that Microsoft had fixed six months before the incident. Even in large organizations, systems often went unpatched for years.

Unfortunately, this attitude still exists today. The difference is that modern defense layers make it much harder for attackers to exploit every vulnerable machine exposed to the internet.
