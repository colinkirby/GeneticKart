Genetic Kart
==========
i need a better name

self-driving Mario Kart 64 using genetic algorithm

Instructions
------------
1. Clone repository, important that you have states folder
2. Get Bizhawk
    -Scripts are all written for the BizHawk emulator (tested in version 1.12.2), which has embedded Lua scripting. To get BizHawk you first need to install the prerequisites - https://github.com/TASVideos/BizHawk-Prereqs/releases/tag/1.4. Then you can download BizHawk (version 1.12.2) and unzip it to any directory - https://github.com/TASVideos/BizHawk/releases/tag/1.12.2
3. Get Mario Kart 64 (USA) rom, easy to find with quick google search
    -Important that it is the USA version of the ROM
4. Open ROM in Bizhawk (Emuhawk)
5. Go to tools -> lua console -> script -> open script, then open the Play.lua script in this directory
6. Run for a while, adjust weights as desired. Fitness score data will be saved into fitness.txt

Special thansk to
----------------
https://github.com/nicknlsn/MarioKart64NEAT
and 
https://github.com/rameshvarun/NeuralKart
some lua scripts were borrowed from these projects, and they were the inspiration for our project