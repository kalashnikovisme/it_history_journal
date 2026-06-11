---
title: "Apr 1, 2003 — The Evil Bit Standard Is Published"
date: "April 1, 2003"
excerpt: "RFC 3514 proposed marking malicious packets with an \"Evil Bit\" set to \"1\" for attack indication"
---

The RFC 3514 described a very important proposal for the early 2000s. Attackers were suggested to mark their malicious packets with a special bit called the "Evil Bit." If this bit contained "1", the attacker would thereby indicate that the packet was malicious. Writing "0" in this bit was suggested for all other applications that did not contain malicious content.

In 2003, this was very important because the internet had already reached almost every corner of the world together with viruses, worms, and other threats. RFC 3514 proposed to solve this problem once and for all.

## TL;DR — RFC 3514

- There is no general principle for designating the "Evil Bit"; every software system MUST provide its own interface for marking the Evil Bit, and attacking programs MUST use it.
- Packets that identify themselves as dangerous must write "1" to the Evil Bit; otherwise it should contain "0".
- During packet processing with Evil Bit = 1, it is determined that the packet is dangerous; the software system MUST rewrite the Evil Bit to 0.
- Hosts located inside the same firewall must set Evil Bit = 0, because obviously attackers are outside the firewall.
- When performing scanning actions on hosts, if the scan is performed for benign purposes, the Evil Bit should be 0. If the scan is performed for malicious purposes, it may be set to 1.
- Software systems that are not involved in security must ignore the Evil Bit to speed up packet processing.

## Evil Bit support

Several software systems later stated that they implemented support for the Evil Bit. This was important for organizing the security of software products and users.

[RFC 3514](https://www.rfc-editor.org/rfc/rfc3514)
