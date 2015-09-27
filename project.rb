#!/usr/bin/ruby

class Strategy
	attr_accessor :level, :crushed
	def initialize(level, crushed)
		@level = level
		@crushed = crushed
	end
end

$MAX = 10000000000000000

def max_trials(numFloors, numEggs)
	# if there are not floors, no trials required, or if 1 floor, 1 trials required
	return numFloors if [0, 1].include? numFloors
	
	# For 1 egg, we need numFloors trial
	return numFloors if numEggs == 1
	
	min = $MAX
	
	# Consider all droppings from 1st floor to kth floor and return min of these + 1 (this floor)
	for i in 1..numFloors do
		res = [max_trials(i-1, numEggs-1), max_trials(numFloors-i, numEggs)].max
		min = res if res < min
	end
	
	min + 1
end

def find_strategy(numFloors, numEggs, floorOffset)
	# if there are not floors, no trials required, or if 1 floor, 1 trials required
	if numFloors == 1
		return {'cost'=> 1, 'strategy'=> [floorOffset+1]}
	elsif numFloors == 0
		return 	{'cost'=> 0, 'strategy'=> []}
	end
	
	# For 1 egg, we need numFloors trial
	if numEggs == 1
		strategy = []
		for i in 1..numFloors do
			strategy << floorOffset + i
		end
		return 	{'cost'=> numFloors, 'strategy'=> strategy}
	end
	
	min_strategy = {'cost'=> $MAX}
	
	# Consider all droppings from 1st floor to kth floor and return min of these + 1 (this floor)
	for i in 1..numFloors do
		crushed = find_strategy(i-1, numEggs-1, floorOffset)
		not_crushed = find_strategy(numFloors-i, numEggs, floorOffset+i)
		if not_crushed['cost'] > crushed['cost']
			res = not_crushed
		else
		    res = crushed
		end
		if res['cost'] < min_strategy['cost']
			min_strategy = res 
			min_strategy['strategy'] = [floorOffset+i] + min_strategy['strategy']
		end
	end
	
	min_strategy['cost'] = min_strategy['cost']+1
	min_strategy
end

def get_bf_strategy(numFloors, numEggs)
	find_strategy(numFloors, numEggs, 0)['strategy']
end

def max_trials_dp(numFloors, numEggs)
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << $MAX
		end
	end
 
	# We need one trial for one floor and0 trials for 0 floors
	for i in 1..numEggs do
		mem[i][1] = 1;
		mem[i][0] = 0;
	end 
 
 	# We always need j trials for one egg and j floors.
	for j in 1..numFloors
		mem[1][j] = j;
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = $MAX
			for x in 1..j do
				res = 1 + [mem[i-1][x-1], mem[i][j-x]].max
				mem[i][j] = res if res < mem[i][j]
			end
		end
	end
 
	# mrm[numEggs][numFloors] holds the result
	mem[numEggs][numFloors]
end

puts get_bf_strategy(10, 2)