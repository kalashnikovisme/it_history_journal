---
title: "Apr 15, 1993 — Directive to Launch the Clipper Chip Project"
date: "April 15, 1993"
excerpt: "On April 15, 1993, the Clinton administration launched the Clipper Chip project — a government-backed encryption module with a built-in backdoor. It faced immediate opposition from cryptographers and technology companies, and by 1996 the project was effectively dead."
---

*Disclaimer: the author of this material is not a citizen of the United States and has no claims or questions for the U.S. government. The Clipper Chip project is criticized here only for violating basic principles of information security:*

- *security must not depend on the secrecy of the algorithm*
- *there must be no single point of compromise*

On April 15, 1993, the administration of U.S. President Bill Clinton published a directive announcing the launch of the Clipper Chip project.

In the early 1990s, rapidly expanding information technologies and the emerging Internet increasingly relied on security systems and cryptography for communication. For governments this looked dangerous. Strong encryption meant:

- intelligence agencies could lose the ability to intercept communications
- criminals could communicate without the risk of surveillance

This created a conflict between governments, cryptographers, and technology companies. In history this period became known as the Crypto Wars, and the Clipper Chip project was one of the main battlefields where this struggle played out.

## What the project proposed

The Clipper Chip was a hardware module intended to be installed in communication devices that used secure connections. The module contained the Skipjack encryption algorithm and a unique encryption key. All secure communication from a device equipped with a Clipper Chip was supposed to pass through this module.

The unique encryption key associated with each device was split into two parts and stored by two different government agencies. This meant that neither agency could decrypt communications on its own. The idea was that both agencies could release their halves of the key only after a court order. In that case, authorities could combine the key and decrypt any data that had been protected with it.

The Skipjack algorithm itself was classified. At the time the project was introduced, it had not been published. Only the relevant government agencies had access to it.

## Problems with the project

Deploying the Clipper Chip in communication devices violated two fundamental principles of cryptography and information security.

**Security must not depend on the secrecy of the algorithm**

Most modern encryption algorithms are public. Their specifications are available to anyone, and technology companies can implement them depending on licensing terms.

The openness of algorithms is important for several reasons:

- a public algorithm can be reviewed by the cryptographic community and independent professional organizations — only after that is an algorithm considered trustworthy
- publishing the algorithm shows that its security does not rely on secrecy but on the computational difficulty of decrypting information without the key

Skipjack remained secret during the early years of the Clipper Chip initiative, which is why it did not inspire this confidence. In 1998, the algorithm was finally published, and independent researchers concluded that the algorithm itself was actually fairly strong.

This episode showed something important: skilled engineers and technology companies are not willing to rely on "trust us" when it comes to security. Until a system can be independently examined, it will not be trusted.

**The project created a single point of compromise**

Technically, there were several possible points of compromise, but the real issue was administrative control. Both agencies responsible for storing key fragments ultimately reported to the same authority — the administration of the President of the United States. From a security perspective, this effectively created a single point of compromise. Even if the chance of compromise was extremely small, for security professionals, that was enough to consider the system unsafe.

## Who opposed the project

Because of these issues and many others, the Clipper Chip initiative faced strong opposition from cryptographers and technology companies, including:

- Ron Rivest — creator of the RSA algorithm
- Phil Zimmermann — creator of PGP
- Apple
- IBM
- Sun Microsystems
- Internet Engineering Task Force — the main organization responsible for developing RFC standards
- And thousands of other engineers, researchers, and companies

## End of the project

By 1996, the Clipper Chip project stopped receiving active support from the government agencies. They began searching for other ways to address the problems that had originally motivated the project.
