---
author: "Pasha Kalashnikov"
title: "Jan 31, 1952 — David P. Reed Was Born"
date: "January 31, 1952"
excerpt: "co-designed TCP/IP, created UDP, and formulated the End-to-End principle for scalable networking"
---

David P. Reed is the author of the UDP protocol (the reason you can watch live streams, play online games, and talk over video calls), one of the contributors to TCP/IP (which practically the entire internet runs on), and a person who made a profound impact on how networks work in general.

If you want to read about him, google David P. Reed, not just David Reed. That will help you cut through the sea of actors and musicians in the search results.

The Quiet Architect of the Internet
Despite the fact that David’s work has affected the lives of nearly everyone on the planet, very few people outside the professional community know his name. If you had a video call today, played an online shooter, or watched a stream, you were using his ideas.

Reed is the person who taught the internet to be flexible and proved that sometimes “the best” is the enemy of “fast enough.”

Working on TCP/IP
In the late 1970s, the internet (then still ARPANET) looked like a construction site without a clear blueprint. Working at MIT, David Reed became one of the key engineers who turned the theoretical concepts of Vint Cerf and Bob Kahn into a living standard.

His most important contribution to TCP/IP was architectural purism. In early versions, the two protocols were almost inseparable. Reed was one of the strongest advocates for separating them. He understood that the routing protocol (IP) should be a universal postal address, while the transport protocol (TCP) should be just one of the possible delivery methods.

This decision made the internet modular. Thanks to Reed, today we can switch from Wi-Fi to 5G without rewriting application code. The network became layered, where each level performs its own task without interfering with the others.

The Birth of UDP: A Protocol That Asks No Questions
While working on TCP, Reed noticed a problem. TCP is extremely meticulous: it verifies every delivered packet. If data is lost, the system pauses and waits for retransmission. This is perfect for sending text, but disastrous for live data streams.

The ideas of Reed was published in several specifications, the most important one is RFC 768, describing UDP (User Datagram Protocol). The idea behind UDP sounded almost reckless: “I sent the data — what happens next is up to fate.” The protocol does not verify delivery and does not require acknowledgments.

Why was this necessary?

For speed: In a video call, you do not care if a couple of pixels disappear in the corner of the screen. What matters is hearing the other person without a 10-second delay.

For online games: Where instant server response is more important than confirmation that every packet arrived.

Reed effectively legalized chaos in the name of efficiency — and that is what made the internet multimedia.

The Philosophy of a Fast but Simple Network (End-to-End)
Together with his colleagues, Reed formulated the fundamental End-to-End principle. Its essence is that the network itself should remain as simple as possible — just moving packets from point A to point B. All the “intelligence” (encryption, error correction) should be handled by the end devices — your computers and smartphones.

If every router in the world tried to “think” about your traffic, the internet would have collapsed under its own weight back in the 1990s. Reed’s principle allowed the network to scale to billions of users.

Why This Matters Today
David Reed understood that technology should be simple in its imperfection. He did not try to build a perfectly reliable system. He built a system that allows errors, allows data loss, yet keeps moving forward.

Without his role in TCP/IP and the creation of UDP, our internet would have remained a slow archive for sending documents, rather than the fast, living, real-time space we are used to today.
