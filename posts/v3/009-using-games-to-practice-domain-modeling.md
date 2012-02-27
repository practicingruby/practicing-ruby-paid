As programmers, it is literally our job to make [domain models](http://en.wikipedia.org/wiki/Domain_model) understandable to computers. While this can be some of the most creative work we do, it also tends to be the most challenging. The inherent difficulty of designing and implementing conceptual models leads many to develop their problem solving skills through a painful process of trial and error rather than some form of deliberate practice. However, that is a path paved with sorrows, and we can do better.

Defining problem spaces and navigating within them does get easier as you become more experienced. But if you only work with complex domain models while you are knee deep in production code, you'll find that many useful modeling patterns will blend in with application-specific details and quickly fade into the background without being noticed. Instead, what is needed is a testbed for exploring these ideas that is complex enough to mirror some of the problems you're likely to encounter in your daily work, but inconsequential enough to ensure that your practical needs for working code won't get in the way of exploring new ideas. 

While there are a number of ways to create a good learning environment for studying domain modeling, my favorite approach is to try to clone bits of functionality from various games I play when I'm not coding. In this article, I'll walk you through an example of this technique by demonstrating how to model a simplified version of the [Minecraft crafting system](http://www.minecraftwiki.net/wiki/Crafting).

### Defining the problem space

> NOTE: Those who haven't played Minecraft before may want to spend a few minutes watching this video [tutorial about crafting](http://www.youtube.com/watch?v=AKktiCsCPWE) or skimming [the game's wiki page](http://www.minecraftwiki.net/wiki/Crafting#Basic_Recipes) on the topic before continuing. However, because I only focus on a few very basic ideas about the system for this exercise, you don't need to be a Minecraft player in order to enjoy this article.

The crafting table is a key component in Minecraft because it provides the player with a way to turn natural resources into useful tools, weapons, and construction materials. Stripped down to its bare essence, the function of the crafting table is essentially to convert various input items laid out in a 3x3 grid into some quantity of a different type of item. For example, a single block of wood can be converted into four wooden planks, a pair of wooden planks can be combined to produce four sticks, and a stick combined with a piece of coal will produce four torches. Virtually all objects in the Minecraft world can be built in this fashion, as long as the player has the necessary materials and knows the rules about how to combine them together. 

Because positioning of input items within the crafting table's grid is significant, players need to make use of recipes to learn how various input items can be combined to produce new objects. To make recipes easier for the player to memorize, the game allows for a bit of flexibility in the way things are arranged, as long as the basic structure of the layout is preserved. In particular, the input items for recipes can be horizontally and vertically shifted as long as they remain within the 3x3 grid, and the system also knows how to match mirror images as well. However, after accounting for these variants, there is a direct mapping from the inputs to the outputs in the crafting system.

As of 2012-02-27, Minecraft supports 174 crafting recipes. This is a small enough number where even a naïve data model would likely be fast enough to not cause any usability problems, even if you consider the fact that most of those recipes can be shifted around in various ways or flipped. But in the interest of showing off some neat Ruby data modeling tricks, I've decided to try to implement this model in an efficient way. In doing so, I found out that inputs can be checked for corresponding outputs in constant time, and that there are some useful constraints that make it so that only a few variants need to be checked in most cases in order to find a match for the player's input items.

My finished model ended up consisting of three parts: A recipe object responsible for codifying the layout of input items and generating variants based on that layout, a cookbook object which maps recipes to their outputs, and an importer object which generates a cookbook object from CSV formatted recipe data. In the following sections, I will take a look at each of these objects and point out any interesting details about them.

### Modeling recipes 

### Modeling a cookbook

### Modeling a recipe importer

### Reflections
