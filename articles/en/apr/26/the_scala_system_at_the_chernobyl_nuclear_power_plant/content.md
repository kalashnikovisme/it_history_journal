---
title: "Apr 26, 1986 — The SCALA System at the Chernobyl Nuclear Power Plant"
date: "April 26, 1986"
excerpt: "The SCALA system was well-designed but could not block operator actions without human consent"
---

On April 26, 1986, the worst man-made disaster in history took place — the explosion at the Chernobyl Nuclear Power Plant.

This is a good moment to talk about the digital-analog system SCALA (System for Control and Analysis of Local Accidents), which was used at the plant. What could it do? What kind of monitoring systems did it include? And did it have any faults that contributed to the disaster?

## What was SCALA?

SCALA consisted of several components. The main one was the V-3M computer — a powerful computing system for its time. Programs were loaded using punch cards, and all information was either displayed on operator panels or printed on paper.

Another important part of SCALA was the large indicator wall — the one you often see in photos of Soviet-era control rooms or in reconstructions of the Chernobyl accident.

Some control panels at the plant were purely analog, meaning they worked without computers. But this particular indicator wall was controlled by the V-3M systems.

Engineers who had access to SCALA could retrieve any value using a special terminal. This terminal had its own query language. Commands looked like this: `AOP 3214`. Only RBMK reactor specialists knew how to use it. The result was shown on a dedicated display panel.

SCALA also included the DREG system (Diagnostic Recording). In modern terms, it continuously logged data from all systems at the plant. It constantly polled available systems, recorded their state, and tracked any changes made by operators.

The main storage for DREG was magnetic tape — the standard storage medium in the USSR at the time. Magnetic tapes are relatively resistant to radiation, which turned out to be critical: investigators later used DREG logs to reconstruct the events of the accident.

## What did the computer do during the accident?

The connection between the Chernobyl disaster and computer systems is not about hardware failure. SCALA was well designed. Its creators anticipated many possible scenarios.

The plant had two V-3M computers. Each handled its own tasks, but they continuously monitored each other. If one failed to respond, the other would take over its workload.

SCALA included a large number of sensors and alarm systems. Some alarms were intentionally very loud so operators would not miss them. It was a solid monitoring and control system.

However, SCALA lacked one critical function that modern systems at nuclear plants have: it could not automatically shut down the reactor or block dangerous actions without human intervention. All critical decisions were made by operators.

The human-computer interaction problem during the accident was that operators ignored or disabled parts of the monitoring system. Some alarms were turned off, others were simply ignored.

Operator actions were not the only cause of the disaster. The reactor design had a critical flaw unknown to the operators, and management decisions also played a role.

But if the operators had used SCALA as intended, the accident could likely have been avoided.

The Chernobyl disaster is something every engineer should study. It clearly shows why safety requirements must be followed — during design, production, and operation.
