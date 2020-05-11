--Written by Colin Kirby
--Open this file on emulator to run genetic algorithm

local util = require(".util")

function initialize_things()
    console.clear()
	state_file = "states/tt/LR.state"
    file = io.open("fitness.txt", "a")
    file:write("New Iteration" , "\n")

    -- TODO add bumpers?
    button_input_names = {
    -- "Start",
    "P1 A",
    "P1 A Left",
    "P1 A Right"}
 
    button_actual_names = {
    -- "Start",
    "A",
    "Left",
    "Right",
    }
    

    num_buttons = #button_actual_names
 
    course = {}
 
    -- collision address
    course.col_addresses = {
    0x1D65A0,  -- Mario Raceway
    0x1D4280,  -- Choco Mountain
    "",
    0x1D8380,  -- Banshee Boardwalk
    0x1E5170,  -- Yoshi Valley
    0x1D4650,  -- Frappe Snowland
    0x1E6380,  -- Koopa Troopa Beach
    0x1DAF50,  -- Royal Raceway
    0x1DD1C0,  -- Luigi Raceway
    0x1E1500,  -- Moo Moo Farm
    0x1F0AC0,  -- Toad's Turnpike
    0x1F0120,  -- Kalamari Desert
    0x1D6A70,  -- Sherbet Land
    0x1E3080,  -- Rainbow Road
    0x1D9AE0,  -- Wario Stadium
    "",
    "",
    "",
    0x1E1300,
    ""}  --
 
    -- the collision attribute for each track
    course.track_attribute = {
    "",  -- Mario Raceway
    "",  -- Choco Mountain
    "",
    6,
    2,  -- Yoshi Valley
    5,  -- Frappe Snowland
    3,  -- Koopa Troopa Beach
    1,  -- Royal Raceway
    1,  -- Luigi Raceway
    2,  -- Moo Moo Farm
    1,  -- Toad's Turnpike
    2,  -- Kalamari Desert
    "",  -- Sherbet Land
    1,  -- Rainbow Road
    "",  -- Wario Stadium
    "",
    "",
    "",
    2,
    ""}
 
    course.names = {
    "Mario Raceway      ",
    "Choco Mountain     ",
    "Bowser's Castle    ",
    "Banshee Boardwalk  ",
    "Yoshi Valley       ",
    "Frappe Snowland    ",
    "Koopa Troopa Beach ",
    "Royal Raceway      ",
    "Luigi Raceway      ",
    "Moo Moo Farm       ",
    "Toad's Turnpike    ",
    "Kalimari Desert    ",
    "Sherbet Land       ",
    "Rainbow Road       ",
    "Wario Stadium      ",
    "Block Fort         ",
    "Skyscraper         ",
    "Double Deck        ",
    "DK's Jungle Parkway",
    "Big Donut          "}
 
    savestate.load(state_file)
 
    course.selected_addr = 0xDC5A0
    course.number = mainmemory.read_u16_be(course.selected_addr) + 1
    course.name = course.names[course.number]
    course.col_start = course.col_addresses[course.number]
    -- course.col_fin = course.col_addr_fins[course.number]
    course.col_step = 0x2C
    course.col_attr_offset = 0x02
    course.p1_offset = 0x11
    course.p2_offset = 0x15
    course.p3_offset = 0x19
    course.tr_attr = course.track_attribute[course.number]
 
    -- this loads the map, just the track sections though
    load_map()
 
    -- kart data
    kart = {}
    kart.x_addr = 0x0F69A4
    kart.xv_addr = 0x0F69C4
    kart.y_addr = 0xF69A8
    kart.yv_addr = 0x0F69C8
    kart.z_addr = 0x0F69AC
    kart.zv_addr = 0x0F69CC
    dist_addr = 0x16328A
    kart.sin = 0xF6B04
    kart.cos = 0xF6B0C
 
    character_addr = 0x0DC53B
    character = mainmemory.read_u8(character_addr)
 
    -- object addresses
    obj = {}
    obj.addr = 0x15F9B8
    obj.stop = 0x162578
    obj.step = 0x70
    obj.x_offset = 0x18
    obj.y_offset = 0x1C
    obj.z_offset = 0x20
 
    -- some colors
    black  = 0xFF000000
    white  = 0xFFFFFFFF
    red    = 0xFFFF0000
    bred   = 0x60FF0000
    green  = 0xFF00FF00
    sgreen = 0xFF009900
    blue   = 0xFF0000FF
    yellow = 0xFFFFFF00
    fbox   = 0xFF00007F
    bblue  = 0x200000FF
    l_off  = 0x500000FF
    bwhite = 0x60FFFFFF
    back   = 0x40808080
    none   = 0x00000000
    b_on   = 0xFF1d2dc1
    b_off  = 0x90000000
    player = {
    0x80FF0000, -- mario
    0x0, -- luigi
    0x0, --
    0x0, --
    0x0, --
    0x0, --
    0x0, --
    0x0} --
 
    --weights that should be optimized
    population_size = 20
    mutation_rate = 0.02
    frame_interval = 5
    genome_size = 1000



    max_nodes = 1000000

    fitness = 0
    total_fitness = 0
    current_species = 1
    current_generation = 1
    current_gene = 1
    distance = -2

    frame_count = -1
    previous_distance = -2
    previous_time = 0
    time_segment = 0
    max_fitness = 0

    --weights for progress
    --weights = {}
    generation = {}
    generation_fitness = {}
    gene_reached = {}
    initialize_population()

    clear_controller()
end -- end initialize_things

function load_map()
    the_course = {}
    -- TODO find where the collision addresses end for each track
    for addr = course.col_start, course.col_start + 0x9000, course.col_step do
        local section = {}
        section.p1 = {}
        section.p2 = {}
        section.p3 = {}
        local the_attribute = mainmemory.read_s16_be(
            addr + course.col_attr_offset
            )
        if the_attribute == course.tr_attr then
            section.attribute = the_attribute
 
            local p1_addr = mainmemory.read_s24_be(addr + course.p1_offset)
            section.p1.x = mainmemory.read_s16_be(p1_addr)
            section.p1.y = mainmemory.read_s16_be(p1_addr + 0x2)
            section.p1.z = mainmemory.read_s16_be(p1_addr + 0x4)
 
            local p2_addr = mainmemory.read_s24_be(addr + course.p2_offset)
            section.p2.x = mainmemory.read_s16_be(p2_addr)
            section.p2.y = mainmemory.read_s16_be(p2_addr + 0x2)
            section.p2.z = mainmemory.read_s16_be(p2_addr + 0x4)
 
            local p3_addr = mainmemory.read_s24_be(addr + course.p3_offset)
            section.p3.x = mainmemory.read_s16_be(p3_addr)
            section.p3.y = mainmemory.read_s16_be(p3_addr + 0x2)
            section.p3.z = mainmemory.read_s16_be(p3_addr + 0x4)
 
            the_course[#the_course + 1] = section
        end
    end
end



--GENERATE POPULATION

function initialize_population()
    local genome = {}
    for i = 1, population_size do
        for j = 1, genome_size do
            genome[#genome + 1] = new_gene()
        end
        generation[#generation + 1] = genome
        genome = {}
    end
    file:write("Gen: ".. current_generation, "\n")
    file:flush()
end 


--generates a new gene 00 = forward, 01 = right, 10 = left
function new_gene()
    local gene = ""
    local r = math.random(0,2)
    if(r == 0) then
        gene = "00"
    elseif(r == 1) then 
        gene = "01"
    else
        gene = "10"
    end
    return gene 
end 

--takes gene input and gives controller instructions 
function gene_to_controller(gene) 
    local left = (gene == "10")
    local right = (gene == "01")

    for i,v in ipairs(button_input_names) do
        if(i == 2) then
            controller[v] = left
        elseif(i == 3)  then   
            controller[v] = right 
        end 
    end 
end

--compute fitness
function get_fitness_score()
    local score = 0
    time_segment = time - previous_time

    if(distance > -1) then
        score = (1 / time_segment)
    end
    return score
end


--selects species for reproduction based on fitness weighted random selection
function select_best_species()
    local normalized_fitness = {}
    local normalized_accumulated_fitness = {}
    local prev = 0

    --this is inneficiant, but my knowledge of lua is limited
    --TODO
    --Make each genome an object, with a list of genes, and a fitness score
    local temp_fitness = shallowCopy(generation_fitness)
    local sorted_order = {}
    table.sort(temp_fitness)
    for i, val1 in ipairs(temp_fitness) do
        for j, val2 in ipairs(generation_fitness) do 
            if(val1 == val2) then 
                sorted_order[#sorted_order + 1] = j
            end
        end
    end 

    --normalize
    for _, fit in ipairs(generation_fitness) do
        normalized_fitness[#normalized_fitness + 1] = (fit / total_fitness) * 100
    end

    --accumulated normalized values
    table.sort(normalized_fitness)
    for i,v in ipairs(normalized_fitness) do 
        local val = prev + normalized_fitness[i]
        normalized_accumulated_fitness[i] = val
        prev = val
    end 
    
    temp_gen = {}

    --randomly select 2 at a time until the number selected reaches the population size
    for i = 1, population_size/2 do 
        local p1 = choose_parent(normalized_accumulated_fitness, sorted_order)
        local p2 = p1
        while(p1 == p2) do
            p2 = choose_parent(normalized_accumulated_fitness, sorted_order)
        end 
        crossover(p1, p2)
    end 

    generation = {}
    generation_fitness = {}
    gene_reached = {}
    total_fitness = 0
    generation = shallowCopy(temp_gen)
end  

--does the random (weighted) selection
function choose_parent(normalized_accumulated_fitness, sorted_order)
    local parent = 0
    local num = math.random(1,100)
    for i,v in ipairs(normalized_accumulated_fitness) do
        if num <= v then
            return sorted_order[i]
        end
    end    
    return 0
end 

--function for copying tables
function shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

--crosses over inputted parents at randomized mutation point in the genome
function crossover(p1, p2) 
    local child1 = {}
    local child2 = {}

    max_gene_reached = math.max(gene_reached[p1], gene_reached[p2])
    crossover_point = math.random(1, max_gene_reached)

    for i = 1, crossover_point do 
        child1[#child1 + 1] = generation[p1][i]
        child2[#child2 + 1] = generation[p2][i]
    end


    for j = crossover_point + 1, genome_size do
        child1[#child1 + 1] = generation[p2][j]
        child2[#child2 + 1] = generation[p1][j]
    end



    

    child1 = mutate(child1)
    child2 = mutate(child2)

    temp_gen[#temp_gen + 1] = child1
    temp_gen[#temp_gen + 1] = child2
end 

--iterates through every gene and mutates based on mutation probability
function mutate(c)
    local mutate_num = mutation_rate * 1000
    for i = 1, #c do 
        local num = math.random(1, 1000)
        if(num <= mutate_num) then
            local gene = c[i]
            local mutated_gene = new_gene()
            while(gene == mutated_gene) do 
                mutated_gene = new_gene()
            end
            c[i] = mutated_gene
        end
    end
    return c
end 

--resets controller input
function clear_controller()
    controller = {}
    for i,v in ipairs(button_input_names) do
        if(i == 1) then
            controller[v] = true
        else          
            controller[v] = false
        end 
    end 
end

--resets variables, moves to next species
function next_species()
    file:write(fitness, "\n")
    file:flush()
    gene_reached[#gene_reached + 1] = current_gene
    generation[#generation + 1] = generation[current_species]
    generation_fitness[#generation_fitness + 1] = fitness
    total_fitness = total_fitness + fitness
    if(fitness > max_fitness) then
        max_fitness = fitness
    end  
    fitness = 0 
    current_species = current_species + 1
    frame_count = -1
    previous_distance = -2
    previous_time = 0
    current_gene = 1
    time_segment = 0
    clear_controller()

    savestate.load(state_file)
end

--proceeds to the next generation 
function next_generation()
    current_generation = current_generation + 1
    current_species = 1
    file:write("Gen: ".. current_generation, "\n")
    select_best_species()
end  

--renders information
function display_info()
	gui.drawBox(-1, 214, 320, 240, none, bwhite)
	-- gui.drawText(-2, 212, course.name, black, none)
	gui.drawText(-2, 212, "Generation:"..current_generation, black, none)
	gui.drawText(120, 212, "Species:"..current_species, black, none)
    gui.drawText(
		120, 224, "Max Fitness:"..round(max_fitness), black, none
		)
    gui.drawText(-1, 224, "Fitness:".. round(fitness), black, none)
end


--Not all of these are necessary, but could be useful for future work
function refresh()
    frame_count = frame_count + 1

    distance = mainmemory.read_s16_be(dist_addr)
    time = util.readTimer()
 
    k_sin    = mainmemory.readfloat(kart.sin,     true)
    k_cos    = mainmemory.readfloat(kart.cos,     true)
 
    kart_x   = mainmemory.readfloat(kart.x_addr,  true)
    kart_xv  = mainmemory.readfloat(kart.xv_addr, true) * 12
    kart_y   = mainmemory.readfloat(kart.y_addr,  true)
    kart_yv  = mainmemory.readfloat(kart.yv_addr, true) * 12
    kart_z   = mainmemory.readfloat(kart.z_addr,  true)
    kart_zv  = mainmemory.readfloat(kart.zv_addr, true) * 12
 
    XYspeed  = math.sqrt (kart_xv^2+kart_yv^2)
    XYZspeed = math.sqrt (kart_xv^2+kart_yv^2+kart_zv^2)
end


game = gameinfo.getromname()
right_game = "Mario Kart 64 (USA)" == game
initialize_things()
 
while right_game do
    if(distance < previous_distance or time_segment > 1.5 or (util.readVelocity() < 1 and distance > 0)) then
        next_species()
    end 

    if(current_species > population_size) then
        next_generation()
    end

    refresh()
    display_info()

    if(frame_count % frame_interval == 0) then
        gene_to_controller(generation[current_species][current_gene])
        current_gene = current_gene + 1
    end

    joypad.set(controller)
    if(distance % 5 == 0 and distance ~= previous_distance) then
     fitness = fitness + get_fitness_score()
     previous_distance = distance 
     previous_time = time 
    end



	emu.frameadvance()
end

file:close()
