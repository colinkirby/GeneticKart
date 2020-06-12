--Written by Colin Kirby and David Barrette
--Open this file on emulator to run genetic algorithm

local util = require(".util")

function initialize_things()
    local verbose = true
    console.clear()











----------------------------------------------------------------------------Stuff not to worry about-----------------------------------------------------------------
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
 --------------------------------------------------------------------------END Stuff Not to worry about


    --weights that should be optimized
    num_species = 2
    mutation_rate = 0.1 --Can be from 0.00 to 1.00
    frame_interval = 5
    genome_size = 1000



    generation_max_fitness = 0
    current_species = 1
    current_generation = 1
    generation = {}
    generation_fitnesses = {}

    frame_count = -1
    time = 0
    previous_time = 0
    time_segment = 0


    VELOCITY_THRESHOLD = 1.2



    ------Global Vars
    current_gene = 1
    fitness = 0
    distance = 0
    prev_distance = -2
    most_fit_species = {}

    initialize_population()
    clear_controller()
end -- end initialize_things










-------------------------------------------------------------------------------STUFF THAT WORKS---------------------------------------------------------------
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

--renders information
function display_info()
	gui.drawBox(-1, 214, 320, 240, none, bwhite)
	-- gui.drawText(-2, 212, course.name, black, none)
	gui.drawText(-2, 212, "Generation:"..current_generation, black, none)
	gui.drawText(120, 212, "Species:"..current_species, black, none)
    gui.drawText(
		120, 224, "Max Fitness:"..round(generation_max_fitness), black, none
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


---------------------------------------------------------------------------------END STUFF THAT JUST WORKS
















-------------------------------------------------------------------------------Creating each generation of species------------------------------------------
--GENERATE POPULATION
function initialize_population()
    for i = 1, num_species do
        generation[#generation + 1] = {
            id = i,
            genome = new_genome(genome_size),
            furthest_gene_reached = 0, --Time spent playing is tied with this
            fitness = 0,
            distance = 0,
        }
    end
    file:write("Gen: ".. current_generation, "\n")
    file:flush()
end 

--generates the genome
function new_genome()
    local genome = {}
    for i = 1, genome_size do
        genome[#genome+1] = new_gene()
    end
    return genome 
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


----------------------------------------------------------------------------END create new generation's species





------------------------------------------------------------------selecting the best species---------------------------------------------------
function select_best_species()
    generation_fitnesses = {}

    temp_generation = clone(most_fit_species)       --TRY REMOVING, MAY NOT NEED THIS EXPLICIT DELETION
    generation = {} 
    generation = temp_generation
end  

--function for copying tables
function clone(most_fit_species)
    new_generation = {}

    for species = 1, num_species do
        new_genome = {}

        --Copy the most fit geneome over until the futhest gene it reached
        for i = 1, most_fit_species.furthest_gene_reached do
            new_genome[#new_genome + 1] = most_fit_species.genome[i]
        end

        --Mutate that genome
        mutate(new_genome)

        --Add on the rest of the genome until genome_size is reached
        for i = #new_genome+1, genome_size do
            new_genome[i] = new_gene()
        end

        --Save genome as a new species
        new_generation[#new_generation+1] = {
            id = i,
            genome = new_genome,
            furthest_gene_reached = 0,
            fitness = 0,
            distance = 0
        }
    end

    return new_generation
end

--iterates through every gene and mutates based on mutation probability
function mutate(subgenome)
    local mutation_percentage = mutation_rate * 100
    for i = 1, #subgenome do 
        local num = math.random(1, 100)
        if(num <= mutation_percentage) then
            local gene = subgenome[i]
            local mutated_gene = new_gene()
            while(gene == mutated_gene) do 
                mutated_gene = new_gene()
            end
            subgenome[i] = mutated_gene
        end
    end
    return subgenome
end 


function round(num, idp)
    if(num ~= 0) then
        local mult = 10^(idp or 0)
        return math.floor(num * mult + 0.5) / mult
    else
        return 0
    end
end













--------------------------------------------------------------------------END selecting the best species
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

    generation[current_species].furthest_gene_reached = current_gene
    generation[current_species].fitness = fitness
    generation[current_species].distance = distance

--Total generation fitness
    if(generation_fitnesses[current_species] ~= nil) then
        generation_fitnesses[current_species] = generation_fitnesses[current_species] + fitness
    else
        generation_fitnesses[current_species] = fitness
    end

    if(fitness > generation_max_fitness) then
        generation_max_fitness = fitness
        most_fit_species = generation[current_species]
    end  

    frame_count = -1
    prev_distance = -2
    previous_time = 0
    time_segment = 0

    fitness = 0
    distnace = 0
    current_gene = 1

    clear_controller()

    current_species = current_species + 1
    savestate.load(state_file)
end

--proceeds to the next generation 
function next_generation()
    select_best_species()
    current_generation = current_generation + 1
    generation_max_fitness = 0
    current_species = 1
    file:write("Gen: ".. current_generation, "\n")
end  


--compute fitness NEEDS TO BE REVAMPED
function get_fitness_score()
    local score = 0
    time_segment = time - previous_time

    if(distance > -1) then
        score = (1 / time_segment)
    end
    return score
end


function play()
    print("sb vkesdvbesvbbjkrsbk")
    game = gameinfo.getromname()
    correct_game = "Mario Kart 64 (USA)" == game
    initialize_things()
    if correct_game ~= true then
        print("This is not the correct ROM, need Mario Kart 64 (USA)")
    end
    
    while correct_game do
        if(frame_count > 180 and (distance < prev_distance or util.readVelocity() < VELOCITY_THRESHOLD)) then
            next_species()
        elseif(current_species > num_species) then
            next_generation()
        else 
            refresh()
            display_info()
        end

        ------------------------------------------------------Update 

        if(frame_count % frame_interval == 0) then
            gene_to_controller(generation[current_species].genome[current_gene])
            current_gene = current_gene + 1
        end

        joypad.set(controller)
        if(distance % 5 == 0 and distance ~= prev_distance) then
            fitness = fitness + get_fitness_score()
            prev_distance = distance 
            previous_time = time 
        end


        emu.frameadvance()
    end
end

play()

file:close()