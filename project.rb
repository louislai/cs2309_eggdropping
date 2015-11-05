#!/usr/bin/ruby
require "ruby-graphviz"
require "awesome_print"

class Strategy
	attr_accessor :level, :crushed
	def initialize(level, crushed=nil)
		@level = level
		@crushed = crushed
	end
	
	# For string representation
	def to_s
		"Egg dropped at floor #{@level} and #{@crushed ? '' : 'not '}crushed."
	end
end

class Node
	attr_accessor :level, :crushed_node, :not_crushed_node
	def initialize(level, crushed_node=nil, not_crushed_node=nil)
		@level = level
		@crushed_node = crushed_node
		@not_crushed_node = not_crushed_node
	end
	
	# For string representation
	def to_s
		"Egg dropped at floor #{@level}"
	end
	
	def self.print(root, filename="decision_tree") 
		g = ::GraphViz.new( :G, :type => :digraph )
		
		Node.draw_nodes(root, g)

		# Generate output image
		g.output( :png => "#{filename}.png" )	
	end
	
	private 
	def self.draw_nodes(node, graph)
		parent = graph.add_nodes(node.level.to_s)
	
		# Create two nodes
		if node.not_crushed_node
			not_crushed = Node.draw_nodes(node.not_crushed_node, graph)
			graph.add_edges(parent, not_crushed, label: 'not crushed')
		end
		
		if node.crushed_node
			crushed = Node.draw_nodes(node.crushed_node, graph)
			graph.add_edges(parent, crushed, label: 'crushed')
	 	end

		parent
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
		return {'cost'=> 1, 'strategy'=> [Strategy.new(floorOffset+1, FALSE)]}
	elsif numFloors == 0
		return 	{'cost'=> 0, 'strategy'=> []}
	end
	
	# For 1 egg, we need numFloors trial
	if numEggs == 1
		strategy = []
		for i in 1..numFloors do
			strategy << Strategy.new(floorOffset+i, FALSE)
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
			crushed = FALSE
		else
		    res = crushed
			crushed = TRUE
		end
		if res['cost'] < min_strategy['cost']
			min_strategy = res 
			min_strategy['strategy'] = [Strategy.new(floorOffset+i, crushed)] + min_strategy['strategy']
		end
	end
	
	min_strategy['cost'] = min_strategy['cost']+1
	min_strategy
end

def get_bf_strategy(numFloors, numEggs)
	find_strategy(numFloors, numEggs, 0)['strategy']
end

def output_decision_tree(numFloors, numEggs, floorOffset)
	# if there are not floors, no trials required, or if 1 floor, 1 trials required
	if numFloors == 1
		return {'cost'=> 1, 'root' => Node.new(floorOffset+1)}
	elsif numFloors == 0
		return 	{'cost'=> 0, 'root'=> nil}
	end
	
	# For 1 egg, we need numFloors trial
	if numEggs == 1
		tree = []
		pnode = nil
		for i in numFloors.downto(1) do
			node = Node.new(floorOffset+i, nil, pnode)
			pnode = node
		end
		return 	{'cost'=> numFloors, 'root'=> node}
	end
	
	min_strategy = {'cost'=> $MAX}
	
	# Consider all droppings from 1st floor to kth floor and return min of these + 1 (this floor)
	for i in 1..numFloors do
		crushed = output_decision_tree(i-1, numEggs-1, floorOffset)
		not_crushed = output_decision_tree(numFloors-i, numEggs, floorOffset+i)
		if not_crushed['cost'] > crushed['cost']
			res = not_crushed
		else
		    res = crushed
		end
		if res['cost'] < min_strategy['cost']
			node = Node.new(floorOffset+i, crushed['root'], not_crushed['root'])
			min_strategy['cost'] = res['cost'] 
			min_strategy['root'] = node
		end
	end
	
	min_strategy['cost'] = min_strategy['cost']+1
	min_strategy
end

def print_decision_tree(numFloors, numEggs, filename="decision_tree")
	Node.print(output_decision_tree(numFloors, numEggs, 0)['root'], filename)
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

def get_dp_strategy(numFloors, numEggs)
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << { 'cost' => $MAX }
		end
	end
 
	# We need one trial for one floor and0 trials for 0 floors
	for i in 1..numEggs do
		mem[i][1] = { 'cost' => 1 };
		mem[i][0] = { 'cost' => 0 };
	end 
 
 	# We always need j trials for one egg and j floors.
	for j in 1..numFloors
		mem[1][j] = { 'cost' => j };
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = { 'cost' => $MAX }
			for x in 1..j do
				if mem[i-1][x-1]['cost'] > mem[i][j-x]['cost']
					res = mem[i-1][x-1].clone
					prev = [i-1, x-1]
				else
					res = mem[i][j-x].clone
					prev = [i, j-x]
				end
				res['cost'] = res['cost'] + 1
				if res['cost'] < mem[i][j]['cost']
					mem[i][j] = res
					mem[i][j]['prev'] = prev
				end
			end
		end
	end
 
	# mem[numEggs][numFloors] holds the result
	fin = mem[numEggs][numFloors]
	p fin
	curEggs = numEggs
	curFloors = numFloors
	floorOffset = 0
	floorCeiling = numFloors
	strategy = []
	
	while !fin['prev'].nil?
		floorDiff =  curFloors - fin['prev'][1]
		if fin['prev'][0] == curEggs
			floorOffset += floorDiff
			strategy << Strategy.new(floorOffset, FALSE)
		else
			floorCeiling = floorCeiling - floorDiff + 1
			strategy << Strategy.new(floorCeiling, TRUE)
		end
		curFloors = fin['prev'][1]
		curEggs = fin['prev'][0]
		fin = mem[fin['prev'][0]][fin['prev'][1]]	
		p fin
	end
	
	# The egg should has been dropped at level floorOffset
	for i in 1..fin['cost']
		strategy << Strategy.new(floorOffset+i, FALSE)
	end

	strategy
end

def print_dp_decision_tree(numFloors, numEggs, filename="decision_tree")
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << { 'cost' => $MAX }
		end
	end
 
	# We need one trial for one floor and0 trials for 0 floors
	for i in 1..numEggs do
		mem[i][1] = { 'cost' => 1, 'floorsLeft' => 1 };
		mem[i][0] = { 'cost' => 0, 'floorsLeft' => 0 };
	end 
 
 	# We always need j trials for one egg and j floors.
	for j in 1..numFloors
		mem[1][j] = { 'cost' => j, 'floorsLeft' => j };
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = { 'cost' => $MAX }
			for x in 1..j do
				cost = [mem[i][j-x]['cost'], mem[i-1][x-1]['cost']].max + 1
				
				if cost < mem[i][j]['cost']
					mem[i][j] = { 'cost' => cost, 
					'offset' => x, 'crushed' => mem[i-1][x-1], 'not_crushed' => mem[i][j-x]}
				end
			end
		end
	end
 
	# mem[numEggs][numFloors] holds the result
	# But need to process the level in the result
	Node.print(retrieve_node(mem[numEggs][numFloors], 0), filename)	
end

def retrieve_node(table_node, curOffset)
	if table_node['offset']
		crushed = retrieve_node(table_node['crushed'], curOffset)
		not_crushed = retrieve_node(table_node['not_crushed'], curOffset+table_node['offset'])
		Node.new(curOffset+table_node['offset'], crushed, not_crushed)
	else
		pnode = nil
		for i in table_node['floorsLeft'].downto(1)
			node = Node.new(curOffset+i, nil, pnode)
			pnode = node
		end
		node
	end
end

#print_dp_decision_tree(30, 2, "decision_tree_alt")

def output_gamestate_crush_status(startFloor, endFloor, numEggs, chosenFloor)
	if chosenFloor < startFloor
		return 'not crushed'
	elsif chosenFloor > endFloor
		return 'crushed'
	else
		numFloors = endFloor-startFloor
		# Calculate dp table
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
	
		numFloorsWhenCrushed = chosenFloor - startFloor
		# Having no eggs when there are floors left is worse
		return 'crushed' if numFloorsWhenCrushed > 0 && numEggs - 1 == 0
		
		maxTrialsWhenCrushed = mem[numEggs-1][numFloorsWhenCrushed]
		numFloorsWhenNotCrushed = endFloor - chosenFloor
		maxTrialsWhenNotCrushed = mem[numEggs][numFloorsWhenNotCrushed]
		if maxTrialsWhenCrushed > maxTrialsWhenNotCrushed
			return 'crushed'
		else
			return 'not crushed'
		end
	end
end

def print_dp_decision_tree_fixed_cost(numFloors, numEggs, ipadCost=5, filename="decision_tree")
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << { 'cost' => $MAX }
		end
	end
 
	# We need one trial and one egg crushed for one floor and 0 trials for 0 floors,
	for i in 1..numEggs do
		mem[i][1] = { 
			'cost' => 1 + ipadCost, 
			'crushed_ipad' => 1,
			'floorsLeft' => 1 
			};
		mem[i][0] = { 
			'cost' => 0,
			'crushed_ipad' => 0,
			'floorsLeft' => 0
			};
	end 
 
 	# We always need j trials and one egg crushed for one egg and j floors
	for j in 1..numFloors
		mem[1][j] = { 
			'cost' => j + ipadCost,
			'crushed_ipad' => 1,
			'floorsLeft' => j
			};
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = { 'cost' => $MAX }
			for x in 1..j do
				if mem[i][j-x]['cost'] >= (mem[i-1][x-1]['cost'] + ipadCost)
					cost = mem[i][j-x]['cost'] + 1
					crushed_number = mem[i][j-x]
				else
					cost = mem[i-1][x-1]['cost'] + ipadCost + 1
					crushed_number = mem[i-1][x-1]['crushed_ipad'] + 1
				end
				if cost <= mem[i][j]['cost']
					mem[i][j] = { 
						'cost' => cost, 
						'offset' => x, 
						'crushed' => mem[i-1][x-1], 
						'not_crushed' => mem[i][j-x],
						'crushed_ipad' => crushed_number
						}
				end
			end
		end
	end
 
	# mem[numEggs][numFloors] holds the result
	# But need to process the level in the result
	Node.print(retrieve_node(mem[numEggs][numFloors], 0), filename)	
	ap mem[numEggs][numFloors]['cost']
end

print_dp_decision_tree_fixed_cost(100, 2)

def dp_cost_table_fixed_cost_ipad(numFloors, numEggs, ipadCost)
	# Calculate dp table
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << $MAX
		end
	end
 
	# We need one trial for one floor and 0 trials for 0 floors
	for i in 1..numEggs do
		mem[i][1] = 1+ipadCost;
		mem[i][0] = 0;
	end 
 
 	# We always need j trials for one egg and j floors.
	for j in 1..numFloors
		mem[1][j] = j+ipadCost;
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = $MAX
			for x in 1..j do
				res = 1 + [mem[i-1][x-1]+ipadCost, mem[i][j-x]].max
				mem[i][j] = res if res < mem[i][j]
			end
		end
	end
	mem
end	
	
def output_gamestate_crush_status_fixed_cost_ipad(startFloor, endFloor, numEggs, chosenFloor, ipadCost)
	if chosenFloor < startFloor
		return 'not crushed'
	elsif chosenFloor > endFloor
		return 'crushed'
	else
		numFloors = endFloor-startFloor
		# Calculate dp table
		# A 2D table where entery eggFloor[i][j] will represent minimum
		#   number of trials needed for i eggs and j floors.
		mem = []
		for i in 0..numEggs do
			mem << []
			for j in 0..numFloors do
				mem[i] << $MAX
			end
		end
	 
		# We need one trial for one floor and 0 trials for 0 floors
		for i in 1..numEggs do
			mem[i][1] = 1+ipadCost;
			mem[i][0] = 0;
		end 
	 
	 	# We always need j trials for one egg and j floors.
		for j in 1..numFloors
			mem[1][j] = j+ipadCost;
	 	end

		# Fill rest of the entries in table using optimal substructure
		# property
		for i in 2..numEggs
			for j in 2..numFloors
				mem[i][j] = $MAX
				for x in 1..j do
					res = 1 + [mem[i-1][x-1]+ipadCost, mem[i][j-x]].max
					mem[i][j] = res if res < mem[i][j]
				end
			end
		end
	
		numFloorsWhenCrushed = chosenFloor - startFloor
		# Having no eggs when there are floors left is worse
		return 'crushed' if numFloorsWhenCrushed > 0 && numEggs - 1 == 0
		
		maxCostWhenCrushed = mem[numEggs-1][numFloorsWhenCrushed]
		numFloorsWhenNotCrushed = endFloor - chosenFloor
		maxCostWhenNotCrushed = mem[numEggs][numFloorsWhenNotCrushed]
		if maxCostWhenCrushed > maxCostWhenNotCrushed
			return 'crushed'
		else
			return 'not crushed'
		end
	end
end

def print_dp_decision_tree_dynamic_cost(numFloors, numEggs, fun, filename="decision_tree")
	# A 2D table where entery eggFloor[i][j] will represent minimum
	#   number of trials needed for i eggs and j floors.
	mem = []
	for i in 0..numEggs do
		mem << []
		for j in 0..numFloors do
			mem[i] << { 'cost' => $MAX }
		end
	end
 
	# We need one trial, one egg crushed, for one floor and 0 trials for 0 floors
	for i in 1..numEggs do
		mem[i][1] = { 
			'cost' => 1 + fun.call(1), 
			'crushed_ipad' => 1,
			'floorsLeft' => 1 
			};
		mem[i][0] = { 
			'cost' => 0,
			'crushed_ipad' => 0,
			'floorsLeft' => 0
			};
	end 
 
 	# We always need j trials, one egg crushed, for one egg and j floors.
	for j in 1..numFloors
		mem[1][j] = { 
			'cost' => j + fun.call(1),
			'crushed_ipad' => 1 ,
			'floorsLeft' => j
			};
 	end

	# Fill rest of the entries in table using optimal substructure
	# property
	for i in 2..numEggs
		for j in 2..numFloors
			mem[i][j] = { 'cost' => $MAX }
			for x in 1..j do
				ipadCostWhenCrushed = fun.call(mem[i-1][x-1]['crushed_ipad']+1)
				if mem[i][j-x]['cost'] >= (mem[i-1][x-1]['cost'] + ipadCostWhenCrushed)
					cost = mem[i][j-x]['cost'] + 1
					crushed_number = mem[i][j-x]
				else
					cost = mem[i-1][x-1]['cost'] + ipadCostWhenCrushed + 1
					crushed_number = mem[i-1][x-1]['crushed_ipad'] + 1
				end
				if cost <= mem[i][j]['cost']
					mem[i][j] = { 
						'cost' => cost, 
						'offset' => x, 
						'crushed' => mem[i-1][x-1], 
						'not_crushed' => mem[i][j-x],
						'crushed_ipad' => crushed_number
						}
				end
			end
		end
	end
 
	# mem[numEggs][numFloors] holds the result
	# But need to process the level in the result
	Node.print(retrieve_node(mem[numEggs][numFloors], 0), filename)	
	ap mem[numEggs][numFloors]['cost']
end

def output_gamestate_crush_status_dynamic_cost_ipad(startFloor, endFloor, numEggs, chosenFloor, fun)
	if chosenFloor < startFloor
		return 'not crushed'
	elsif chosenFloor > endFloor
		return 'crushed'
	else
		numFloors = endFloor-startFloor
		# A 2D table where entery eggFloor[i][j] will represent minimum
		#   number of trials needed for i eggs and j floors.
		mem = []
		for i in 0..numEggs do
			mem << []
			for j in 0..numFloors do
				mem[i] << { 'cost' => $MAX }
			end
		end
	 
		# We need one trial for one floor and 0 trials for 0 floors
		for i in 1..numEggs do
			mem[i][1] = { 
				'cost' => 1 + fun.call(1), 
				'crushed_ipad' => 1
				};
			mem[i][0] = { 
				'cost' => 0,
				'crushed_ipad' => 0
				};
		end 
	 
	 	# We always need j trials for one egg and j floors.
		for j in 1..numFloors
			mem[1][j] = { 
				'cost' => j + fun.call(1),
				'crushed_ipad' => 1
				};
	 	end

		# Fill rest of the entries in table using optimal substructure
		# property
		for i in 2..numEggs
			for j in 2..numFloors
				mem[i][j] = { 'cost' => $MAX }
				for x in 1..j do
					ipadCostWhenCrushed = fun.call(mem[i-1][x-1]['crushed_ipad']+1)
					if mem[i][j-x]['cost'] >= (mem[i-1][x-1]['cost'] + ipadCostWhenCrushed)
						cost = mem[i][j-x]['cost'] + 1
						crushed_number = mem[i][j-x]
					else
						cost = mem[i-1][x-1]['cost'] + ipadCostWhenCrushed + 1
						crushed_number = mem[i-1][x-1]['crushed_ipad'] + 1
					end
					if cost <= mem[i][j]['cost']
						mem[i][j] = { 
							'cost' => cost,
							'crushed_ipad' => crushed_number
							}
					end
				end
			end
		end
	 
		# mem[numEggs][numFloors] holds the result
		# But need to process the level in the result
		
		# Having no eggs when there are floors left is worse
		numFloorsWhenCrushed = chosenFloor - startFloor
		return 'crushed' if numFloorsWhenCrushed > 0 && numEggs - 1 == 0
		maxCostWhenCrushed = mem[numEggs-1][numFloorsWhenCrushed]['cost']
		numFloorsWhenNotCrushed = endFloor - chosenFloor
		maxCostWhenNotCrushed = mem[numEggs][numFloorsWhenNotCrushed]['cost']
		if maxCostWhenCrushed > maxCostWhenNotCrushed
			return 'crushed'
		else
			return 'not crushed'
		end
	end
end

sample_fun = Proc.new do |numIpad|
	numIpad * 5
end

print_dp_decision_tree_dynamic_cost(100, 2, sample_fun)

#ap(output_gamestate_crush_status(1, 100, 2, 30))

#for i in 0..10
#	tbl = dp_cost_table_fixed_cost_ipad(100, 4, i)
#	print "Fixed Ipad Cost = #{i}\n"
#	for j in 1..4
#		print "Number of eggs = #{j}\n"
#		for k in 0..100
#			print " #{tbl[j][k]}"
#		end
#		print "\n"
#	end
#	print "\n"
#end

# Draw graph
