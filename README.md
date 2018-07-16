VANAGLORIA (working title)
==========================

> A team game with an emphasis on movement (with no shooting), inspired by Overwatch and Zineth

![Four heroes on the first level](docs/2018-02-14-heroes.png)

Main mechanics ideas:

- [x] Teams start side-by-side and must get to objective
- [x] Objective is a see-saw: have more mass on your side of point

Side mechanics ideas:

- [x] After enough movement, player can switch characters (switching is a mechanic, not a meta-game! no one-tricks)
- [x] Speed up slowly over time. Reset on switch

Current heroes:

- Active:
  - INDUSTRIA (Wallriding mfer)
- Offensive:
  - IRA (WallMAKING mfer)
  - LUSSURIA (An ATTRACTIVE mfer)
  - PAZIENZA (Slow down at a distance)
- Support:
  - CARITAS (Margarine)
  - SUPERBIA (Build portals)

Ideas for Heroes / Abilities:

- More active
  - Blink (like tracer) costs charge
  - Heavy guy - Slow, but very heavy for the see-saw
  - Climb and glide abilities
  - JUMPING
- More supportive
  - Switch places with a TEAMMATE
    - This is awesomely self-regulating because it's zero-sum
      - However, it can't really gain charge because it can still be abused
  - Boost - Area of effect or zarya-like cast, speeds people up
  - Flop - Changes side of see-saw for each team (should it be mechanic instead??)
  - Build - Build Zineth-like rails for anyone to use
  - (Combine with IRA?) Portal 2-like gels (bounce, speed, slow?)
  - (Combine with LUSSURIA?) Hook and swing on terrain
- More offensive
  - Lay traps
  - Freeze a hero. A teammate of that hero must unfreeze them! (Or *n* seconds or whatever)
  - (Combine with PAZIENZA?) Destroy buildings
  - (Combine wit LUSSURIA?) Hold, then release to explode enemies away

Key concepts:

- From mobas we take:
  - An emphasis on teamwork (Objective-based is a plus)
  - Rich, emergent interaction
  - Quick battles (very high replay value)
- From FPS we take:
  - Attention bursts / rationing
  - Fast pace
- From Zineth we take:
  - A rethinking of racing games
  - High skill cap, high(=easy) skill floor
  - Forgiving gameplay

Running
=======

1. Install [Godot](https://godotengine.org/download) 3.0 or later

1. `$ git clone https://github.com/CosineGaming/nv-moba && cd nv-moba`

2. We have a submodule, so you gotta do that janky git stuff

    ```
    $ git submodule init && git submodule update
    ```

3. Install "PythonScript" (the CPython one) from Godot AssetLib. Then restart.
   This project is way too big for me to include in source control because it
   contains an entire Python. I have no reason to believe that it wouldn't work
   with PyPy but I've never tried.

4. Install pymumble from the submodule:

    ```
    $ cd py/pymumble
    $ ../../pythonscript/[yourplatform]/bin/python3 setup.py install
    ```

5. Hope that's it?? Idk

6. `$ godot`

Contributing
============

I'd love to have contributions!

Please open an issue first. As games are a creative project, I reserve the right to control the direction of the project.

Let me know if you have a better idea for a name :)

