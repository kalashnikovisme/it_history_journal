---
author: "Pasha Kalashnikov"
title: "Racket (1995): The Lisp Dialect That Revolutionized Language Design"
date: "January 28, 1995"
excerpt: "Explore how Racket, introduced in 1995, evolved from Scheme into a powerful platform for language creation, macros, and metaprogramming innovation."
updated_at: "2026-06-28"
---
Lisp has always felt like a kind of Holy Grail — powerful, but for many people, too academic. Not every programmer has read SICP (Structure and Interpretation of Computer Programs).

In the mid-1990s, a group of researchers began developing Racket, which over time evolved from a teaching tool into a true Swiss Army knife for anyone who wants to build their own programming languages.

Why was Racket needed?

Before Racket, there was Scheme — an elegant but minimalist Lisp dialect. The PLT (Programming Languages Team), led by Matthias Felleisen, understood that to teach people how to program well, they needed a tool that wouldn’t punish mistakes, but would encourage experimentation.

Until 2010, the project was called PLT Scheme. Its creators positioned it not as “just another dialect,” but as a full platform for building new languages.

A language that doesn’t dictate the rules
Racket’s key idea is the ability to reshape the language itself for a specific task. In most languages, you adapt to the syntax. In Racket, you shape the syntax to fit your needs. It’s like creating your own DSL (Domain Specific Language), except you get to define a much broader set of language features.

What makes Racket stand out:

The #lang directive: In one file you can write classic Racket, in another use Typed Racket, and in a third produce documentation with Scribble — and all of it works together seamlessly.

Next-level macros: These are not simple text substitutions like in C, but powerful code transformation tools that guarantee you won’t break program logic because of accidental name clashes.

DrRacket: An interactive environment designed specifically for language creation and for leveraging all of Racket’s features.

Metaprogramming by default
Metaprogramming is a set of techniques where code and its primitives (methods, classes, and so on) are treated as data. In regular programming, we store business data or technical data in data structures. In metaprogramming, those data structures contain code itself and its building blocks. This approach is useful when implementing functionality with a wide variety of possible use cases.

In Racket, you are effectively metaprogramming by default, because the programming language itself is treated as something malleable — a product with a broad range of potential uses.

More broadly, building your own programming language is a great way to grow as a developer. Once you start designing a language, the next question is where to apply it. That part is genuinely hard: without real application, it is difficult to judge how well you did. So a practical starting point is to build your own DSL. You can create a DSL in almost any programming language, and you can often find real use for it even in commercial projects. To do this, you will inevitably need to use metaprogramming techniques — and that’s where the real learning happens.

Languages that feel especially natural for metaprogramming include Lisp, Ruby, Racket, and Elixir. But you can use it everywhere, even with C++.

Where do we see Racket today?
Racket has found its place wherever rapid development and custom tooling matter:

Naughty Dog: The studio behind The Last of Us and Uncharted has used Racket to build internal tools and scripting engines. When you need to quickly sketch out the logic of a complex game, Racket can be invaluable.

Publishing and documentation: With the Scribble system, Racket is used to typeset highly technical books and manuals where code and text must exist as a single, integrated whole.

Racket on GitHub https://github.com/racket/racket

DrRacket on GitHub https://github.com/racket/drracket
