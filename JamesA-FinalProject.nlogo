;Final Project: Puffin Colonies in a Warming Ocean
;Allison James
;CSCI 390

globals [
  temp ;surface temperature in degrees celsius
  max-island-size ;maximum size of an island
  num-puffins ;starting number of puffins in the world
]

;other globals:
;global-warming? sets whether the ocean warms up during the simulation
;num-islands is the number of islands in the ocean
;puffins-per-island is the number of puffins living on each island
;starting-temp is the initial temperature of the ocean
;temp-threshold is the temperature at which fish start to swim north
;temp-increase is the increase in temperature per tick
;unlimited-fish? sets whether fish are randomly created at a probability of 50% per tick
;conservation-efforts? sets whether fish are delivered to the puffins to help them survive

breed [islands island]

islands-own [habitable?] ;determines whether puffins can live on this island

breed [puffins puffin]

puffins-own [
  energy ;current amount of energy (depleted after each tick and replenished after catching a fish)
  rookery-x ;x coordinate of that puffin's home
  rookery-y ;x coordinate of that puffin's home
  rookery ;who value of that puffin's home
  destination ;the turtle they are currently pursuing, whether that be a puffin or their home
  has-fish? ;true or false depending on whether the puffin is pursuing a fish or returning homed
  chick? ;true or false depending on whether puffin is an adult or not
  disturbed? ;true or false depending on whether the puffin's old home is disturbed
]

breed [fishes fish] ;I am aware "fishes" is grammatically incorrect, but fish needs a plural form here

breed [smallfishes smallfish]

breed [boats boat]


fishes-own[
  swim-north? ; determines whether this fish swims north when the ocean temperature reaching the threshold
]

;------------------------------- SETUP PROCEDURES -----------------------


;observer context
;creates the world, adds agents, and initializes graphs
to setup

  ca

  ask patches [
    set pcolor blue
    set temp starting-temp
  ]

  reset-ticks

  setup-plots

  crt-islands

  make-puffins

  create-fish

  create-smallfish

end

;observer context
;create islands
to crt-islands
  set max-island-size 5
  create-islands num-islands[
    setxy random-pxcor random 31 * -1 ;make islands in the southern half of the map (if fish swim north, puffins fly farther)
    set color green
    set shape "circle"
    set size random max-island-size + 2
    set habitable? true
  ]
end

;observer context
;creates puffins on islands
to make-puffins

  let i 0

  repeat count islands [
    create-puffins puffins-per-island [
      set shape "bird side"
      set size 3
      set color white
      set has-fish? false
      set chick? false
      set disturbed? false
      set energy 100
      set rookery i ;assign this puffin a home island
      set rookery-x [xcor] of turtle i
      set rookery-y [ycor] of turtle i
      setxy rookery-x rookery-y
    ]

    create-puffins 2 [
      set shape "egg"
      set size 2
      set color white
      set has-fish? false
      set chick? true
      set disturbed? false
      set rookery i ;assign this puffin a home island
      set rookery-x [xcor] of turtle i
      set rookery-y [ycor] of turtle i
      setxy rookery-x rookery-y
    ]

    set i i + 1
    set num-puffins count puffins with [not chick?]
  ]

end

;observer context
;creates fish in the ocean
to create-fish
  ;let num count puffins
  create-fishes 8 * num-puffins [
    set shape "fish"
    set size 2
    setxy random-pxcor random 31 * -1 ;spawn fish in the lower half of the world
    set color gray
    set swim-north? true
  ]
end

;observer context
;creates fish that don't provide as much energy, but are closer to home
to create-smallfish
  ;let num count puffins
  create-smallfishes num-puffins [
    set shape "fish 2"
    set size 1
    setxy random-pxcor random 31 * -1
    set color black

  ]
end


; -------------------------------- GO PROCEDURE ----------------------------------

;observer context
;runs the model by having puffins attempt to catch fish without depleting all of their energy
to go
  ;reset-ticks

  if any? fishes or any? smallfishes[
    fish-wander
    smallfish-wander

    puffins-hunt

    if temp < temp-threshold and global-warming? [raise-temp] ;fish move north when it is too warm
    if unlimited-fish?[replenish-fish] ;provide a constant flow of fish into the ecosystem
    replenish-smallfish
    if conservation-efforts? [conserve-puffins] ;provide extra fish that stay near the puffins' homes

    chicks-grow-up

    disturb-with-boat

    tick
    wait .15
  ]

end

;-------------------------------- HELPERS FOR GO ---------------------------------

;observer context
;fish wander randomly in the bottom half of the world unless the temperature reaches the threshold
to fish-wander
  ask fishes [
    rt random 30 - 15
    if temp > temp-threshold and ycor < 0 and swim-north?[
      set heading 0
    ]
    if not can-move? 2[
      rt 180
    ]
    ask islands [
      ask fishes in-radius 1 [
        rt 180
      ]
    ]
    if temp < temp-threshold and ycor > 0 [
      set heading 180
    ]
    fd 1
  ]
end

;observer context
;small fish wander randomly in the bottom half of the world
to smallfish-wander
  ask smallfishes [
    rt random 30 - 15
    if not can-move? 2[
      rt 180
    ]
    ask islands [
      ask fishes in-radius 1 [
        rt 180
      ]
    ]
    if ycor > 0 [
      set heading 180
    ]
    fd 1
  ]
end


;observer context
;puffins pursue the fish closest to them and return home afterwards
to puffins-hunt

  deal-with-disturbance

  choose-prey

  return-home

  feed-chicks

  check-energy

end

;observer context
;puffins choose large fish if they are nearby, but if the energy expenditure is not worth it they pursue small fish
to choose-prey
  ask puffins with [not has-fish?] with [not chick?] with [not disturbed?] [
    ifelse any? fishes in-radius 10 [
      catch-fish
    ]
    [catch-smallfish]
  ]
end

;puffin context
;puffins move toward a fish and eat it if it does not have a fish. if there are no fish, puffins return home
to catch-fish

    ifelse any? fishes [set destination min-one-of fishes [distance myself]
    ifelse any? fishes in-radius 1.5 [
      ask one-of fishes in-radius 1.5 [die]
      replenish-energy
    ]
    [face destination
    fd 1.5
    ]
  ]
  [
    set destination island rookery
    face destination
    fd 1.5
  ]

end

;puffin context
;puffins move toward a small fish and eat it if it does not have a fish. if there are no small fish, puffins return home
to catch-smallfish

  ifelse any? smallfishes [set destination min-one-of smallfishes [distance myself]
    ifelse any? smallfishes in-radius 1.5[
      ask one-of smallfishes in-radius 1.5 [die]
      replenish-less-energy
    ]
    [face destination
      fd 1.5]
  ]
  [
    set destination island rookery
    fd 1.5
  ]

end

;observer context
;puffins fly home if it has already caught a fish on this trip outside the nest
to return-home
  ask puffins with [has-fish?] with [not chick?] with [not disturbed?] [
    ifelse distance destination <= 1 [
      setxy rookery-x rookery-y
      set has-fish? false
    ]
    [face destination
    fd 1
    ]
  ]
end

;observer context
;the ocean temperature rises until it reaches the threshold
to raise-temp
  set temp temp + temp-increase
  if temp = temp-threshold [
    write "The temperature has reached the threshold!"
  ]
end

;observer context
;puffin's energy is depleted from movement, and if they run out of energy they die
to check-energy
  ask puffins with [not chick?] [
    set energy energy - 1
    if energy <= 0 [
      show " has died :("
      die
    ]
  ]
end

;puffin context
;puffins gain energy and prepare to return home when they eat a fish
to replenish-energy
  set has-fish? true
  set destination island rookery
  ifelse energy < 80 [set energy energy + 20][set energy 100]
end

;puffin context
;puffins gain less energy when they eat a small fish and prepare to return home
to replenish-less-energy
  set has-fish? true
  set destination island rookery
  ifelse energy < 88 [set energy energy + 12][set energy 100]
end

;observer context
;fish have a chance of being spawned in the bottom half of the world to keep the fish population stable
to replenish-fish
  ifelse global-warming? [ ;if global warming is in effect, fewer fish are spawned because fewer are being eaten
    if random 100 < 20 [
      create-fishes num-puffins / 4 [
        set shape "fish"
        set size 2
        setxy random-pxcor random 31 * -1
        set color gray
        set swim-north? false
      ]
    ]
  ]
  [
    if random 100 < 20 [
      create-fishes num-puffins / 2[ ;if global warming is not in effect, fish have to reproduce more to maintain a population
        set shape "fish"
        set size 2
        setxy random-pxcor random 31 * -1
        set color gray
        set swim-north? false
      ]
    ]
  ]

end

;observer context
;smallfish cannot be depleted, so if any are eaten more are created in the world to keep the population constant
to replenish-smallfish
  if count smallfishes < count puffins [
    let x count puffins - count smallfishes
    create-smallfishes x [
      set shape "fish 2"
      set size 1
      setxy random-pxcor random 31 * -1
      set color black
    ]
  ]
end


;observer context
;if global warming decreases the fish nearby, humans occasionally insert fish into the world near the puffins' homes to keep them alive
to conserve-puffins
  if random 200 < 1 and temp >= temp-threshold [
    create-fishes 5 * count puffins[
      set shape "fish"
      set size 2
      setxy random-pxcor random 31 * -1
      set color gray
      set swim-north? false
    ]
  ]
end


; ---------------------------------- CHICK PROCEDURES -----------------------------



;observer context
;chicks hatch into adolescents and become adults as time progresses, but only if adults have fed them enough
to chicks-grow-up
  ask puffins with [chick?] [
    if ticks = 200 [
      hatch-chick
      show " has hatched!"
    ]
    if ticks = 400 and energy >= 100[
      become-adult
      show " is now an adult!"
    ]
    if ticks = 400 and energy < 100 [
      show " wasn't fed enough as a chick and has died :("
      die
    ]
  ]
end

;puffin context
;an egg becomes a chick, which still cannot hunt and must rely on adults for food
to hatch-chick
  set size 1
  set shape "bird side"
  set energy 40
end

;puffin context
;a chick becomes an adult, which must now leave the nest and hunt for fish
to become-adult
  set chick? false
  set energy 100
  set size 3
end


;observer context
;adult puffins that have returned home "gift" some of their energy to the chicks to feed them, but only if they have more than 50 energy
to feed-chicks
  ask puffins with [at-home?] with [not disturbed?][
    let x [rookery] of self
    if any? puffins with [chick?] with [shape = "bird side"] with [rookery = x] [
      if energy >= 50[
        set energy energy - 2
        ask puffins with [chick?] with [shape = "bird side"] with [rookery = x][ ;only feed chicks on the same island as myself
          set energy energy + 1
        ]
      ]
    ]
  ]
end

;puffin context
;if the puffin is located at its nesting site, it is at home
to-report at-home?
  ifelse xcor = rookery-x and ycor = rookery-y [report true] [report false]
end


;---------------------------------- DISTURBANCE PROCEDURES ---------------------

;observer context
;make boats that pass through the ocean with the potential to make islands inhabitable
to disturb-with-boat

  make-boat

  ask boats [
    fd 1
    if any? islands in-radius 4 [
      ;show " is near an island!"
      ask one-of islands in-radius 4 [
        disturb-island ;disturb islands that are close to it
      ]
      die
    ]
    if not can-move? 2 [die] ;die at the edge of the world

  ]

end

;observer context
;1 in 200 chance of a boat spawning on the western edge of the ocean facing east
to make-boat
  if random 200 < 1 and count islands with [habitable?] > 1[
    create-boats 1 [
      setxy -32 random-ycor
      set heading random 50 + 50
      set size 4
      set shape "boat"
      set color red
    ]
  ]
end

;island context
;island is no longer habitable and puffins living there have to leave
to disturb-island
  set habitable? false
  let r [who] of self
  ask puffins with [rookery = r] [
    set rookery [who] of one-of other islands with [habitable?]
    set rookery-x [xcor] of island rookery
    set rookery-y [ycor] of island rookery
    set disturbed? true
  ]
end

;observer context
;puffins fly to their new homes, where they resume hunting
to deal-with-disturbance
  ifelse any? islands with [habitable?] [
    ask puffins with [disturbed?] with [not chick?][
    set destination island rookery
    ifelse distance destination <= 1 [
      setxy rookery-x rookery-y
      set disturbed? false
    ]
    [face destination
      fd 1
    ]
  ]
    ask puffins with [disturbed?] with [chick?] [
      die
    ]
  ]
  [
    ask puffins [die]
    write "No more islands are habitable! The puffins have nowhere to go"
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
226
10
787
572
-1
-1
8.51
1
10
1
1
1
0
0
0
1
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
33
17
99
50
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
27
117
199
150
num-islands
num-islands
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
27
167
199
200
puffins-per-island
puffins-per-island
2
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
28
256
200
289
temp-threshold
temp-threshold
17
25
20.0
1
1
NIL
HORIZONTAL

BUTTON
122
17
185
50
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
793
436
866
481
Total Fish
count fishes
0
1
11

SLIDER
31
302
203
335
temp-increase
temp-increase
0
.1
0.05
.01
1
NIL
HORIZONTAL

SLIDER
29
213
201
246
starting-temp
starting-temp
5
17
17.0
1
1
NIL
HORIZONTAL

MONITOR
794
374
938
419
Current Temperature
temp
2
1
11

SWITCH
27
75
200
108
global-warming?
global-warming?
0
1
-1000

SWITCH
31
353
204
386
unlimited-fish?
unlimited-fish?
0
1
-1000

SWITCH
30
399
201
432
conservation-efforts?
conservation-efforts?
1
1
-1000

PLOT
799
35
999
185
Total Fish
Ticks
Fish
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2674135 true "" "plot count fishes"

PLOT
799
202
999
352
Total Puffins
Ticks
Puffins
0.0
10.0
0.0
50.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count puffins with [not chick?]"

@#$#@#$#@
Allison James
CSCI 390

## WHAT IS IT?

This model simulates the effects of global warming and other human disturbances on the habitat and food supply of puffins. Examples included in the model are fish swimming north to escape rising ocean temperatures, boats disturbing islands, and conservation efforts to maintain the puffin population.

This model was inspired by the work of the Audubon Society on Eastern Egg Rock in Maine, where puffins have successfully been reintroduced.

## HOW IT WORKS

Adult puffins leave their assigned rookeries with the intention of catching fish and eating them. They either pursue the nearest large fish, which provide more energy, or the nearest small fish, which provide less energy, depending on which is closer.

After 200 ticks, the 2 eggs on each island hatch into chicks. These chicks must be fed by adults upon each return to the rookery or else chicks will die rather than reaching adulthood, which takes another 200 ticks. 

The ocean has a set starting temperature, which can either remain constant or warm until it reaches a set threshold. Fish swim randomly throughout the ocean, and make no attempt to evade puffins. The exception to this rule is if the ocean temperature reaches the threshold: in this circumstance, large fish swim to the top half of the world.

The user can set whether fish reproduce, which serves to maintain the fish population, and whether local conservationists periodically provide puffins with large amounts of fish.

Boats drive through the ocean occasionally. If a boat comes too close to an island, that island is no longer habitable and puffins choose a new island as their home. The chicks and eggs on the previous island sadly cannot survive. While puffins can survive in the ocean during winter, this model represents the summer, which involves raising chicks and incubating eggs.

## HOW TO USE IT

The SETUP button populates the world with islands, puffins, and fish. Users can change the numbers of islands and puffins per island using the NUM-ISLANDS and PUFFINS-PER-ISLAND sliders. The button also initializes the ocean temperature at the temperature set by the STARTING-TEMP slider.

When the user presses GO, puffins leave and return to their islands, hunting for fish and feeding their young. The GLOBAL-WARMING? switch determines whether the ocean temperature increases over time. If it does, this increment is set by the TEMP-INCREASE slider, which increases the temperature by a certain amount per tick. Users can also change the temperature threshold at which fish swim north using the TEMP-THRESHOLD slider. 

When a puffin eats a fish, that fish dies, so without any reproduction or outside intervention the population will rapidly decline. To prevent this, users can enable fish reproduction using the UNLIMITED-FISH? switch and human conservation efforts (random shipments of fish) using the CONSERVATION-EFFORTS? switch.

Two outputs display the ocean temperature and the number of large fish. Two plots display the number of adult puffins over time and he number of large fish over time.

## THINGS TO NOTICE

The minium and maximum starting temperatures for the model are found on the 1982-2011 average daily mean temperature in early April and the middle of August. Other starting temperatures can represent an different points in the summer. 

The default temperature threshold was the highest daily mean temperature in 2020, a new record for that particular day in August.

The smaller but less nutritious fish were modelled after puffin behavior that leads them to capture less desireable prey to feed their chicks when their preferred fish, white hake and Atlantic herring, cannot be found. However, in the natural environment sometimes the chicks are unable to swallow these other fish because of their shape of size.

## THINGS TO TRY

Adjust sliders for number of puffins and determine whether this increases competition. Now adjust the sliders for temperature. Which of these factors affects the fitness of the puffins more?

How much of an influence does global warming have? How many fish or puffins remain when global warming is or is not in effect?

How does the random location of the islands affect the outcome, even with the same slider settings? Is this realistic?

Adjust sliders so that puffins eventually rely on the small fish for food. Is this sustainable?

## CREDITS AND REFERENCES

Research about puffins for this project was found from Audubon's Project Puffin website:

https://projectpuffin.audubon.org/news/climate-change-and-chance

https://projectpuffin.audubon.org/birds/puffin-chicks

https://projectpuffin.audubon.org/birds/puffin-faqs#:~:text=Puffins%20breed%20in%20colonies%20from,this%20aspect%20of%20their%20life.

Temperature data from Maine was found from the Gulf of Maine Research Institute:

https://gmri.org/stories/2020-gulf-maine-warming-update/
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird side
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
