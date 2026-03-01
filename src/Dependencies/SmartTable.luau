-- SmartTable V 1.9
-- @Patriots8800

-- Types

--!nocheck
-- Im too lazy to fix it to work in strict

export type Queue = {
	QueueList: {any},

	Enter: (self:Queue, Value:any) -> (),
	Next: (self:Queue) -> any,
	Size: (self:Queue) -> number,
}

export type Stack = {
	StackList: {any},

	Shove: (self:Stack, Value:any) -> (),
	Pop: (self:Stack) -> any,
	Size: (self:Stack) -> number,
}

export type BinaryTree = {
	Tree: Tree,
	Sorted: boolean,

	Insert: (self:BinaryTree, Value: any | { any }, Index:number?) -> number,
	Remove: (self:BinaryTree, IndexOrId:number? | string?) -> (any, number),
	Contains: (self:BinaryTree, NodeID:number, Remove:boolean?) -> (boolean | any, number),
	Update: (self:BinaryTree, NodeID:string, NewVal:any | { any }) -> (),
	Size: (self:BinaryTree) -> number,
	GetNodeFromIndex: ((self:BinaryTree, index:number, ReturnValue:boolean) -> any) & ((self:BinaryTree, index:number, ReturnValue:nil) -> BinaryNode),
	DeNode:(self:BinaryTree) -> {any},
	AreChildrenExistant: (self:BinaryTree, Index:number) -> (boolean, boolean),
	Sort:(self:BinaryTree, Type:"Heapify", SortStyle:"Max" | "Min", ValueIndex:any?) -> () & (self:BinaryTree, Type:"BST", Root:number, ValueIndex:any?) -> () & (self:BinaryTree, Type:"Order") -> ()

}

export type BinaryNode = {
	Parent:number, -- Will always be (NodeIndex-1)//2
	NodeIndex:number,
	NodeID:string,
	Right:number, -- Will always be (NodeIndex*2) + 2
	Left:number, -- Will always be (NodeIndex*2) + 1
	Value:number | {any}
}

type Tree = typeof(setmetatable({}::{BinaryNode}, {}::{
	Get: (self:Tree, ID:string) -> number?,
	Append: (self:Tree, ID:string, Value:number) -> (),
	Swap: (self:Tree, ID1:string, ID2:string) -> (),
}))

export type HelperFunctions = {
	GenerateUUID:() -> string,
	Swap:<T>(Tbl:{[number]:T}, Index1:number, Index2:number) -> {[number]:T},
	Shift:<T>(Tbl:{[number]:T}, ShiftAmount:number) -> {[number]:T},
	Align:<T>(Tbl:{[number]:T}) -> {[number]:T},
	ConcatTable:<T, B>(Tbl1:{T}, Tbl2:{B}) -> {T&B},
	Count:(Tbl:{any}) -> number,
	MinN:(Tbl:{[number]:any}) -> number,
	MaxN:(Tbl:{[number]:any}) -> number,
	Flip:<T>(Tbl:{[number]:T}) -> {[number]:T},
}

--[[    Equations

NodeParent - math.floor((ChildIndex-1)/2)
NodeRightChild - (ChildIndex*2) + 2
NodeLeftChild - (ChildIndex*2) + 1
NodeSibling - either +1 or -1 depending on even or odd current index


]]

-- Add id system to Queue & stacks


-- Helper functions
local ID, RptCount, MaxChar = 0, 0, utf8.char(1114111) -- 1114111 Max size

local function GenID():string
	local S = ""

	if ID >= 1114111 then
		ID = 0
		RptCount += 1
	end

	if RptCount > 0 then
		S = string.rep(MaxChar, RptCount)
	end

	ID += 1
	return S..utf8.char(ID)
end

local function BinaryNodeConstructor(Value:any | { any }, CustomIndex:number?, CustomID:string?) : BinaryNode
	local ChildIndex:number = CustomIndex
	local Node:BinaryNode = {}
	local Dual = ChildIndex*2


	Node.Parent = (ChildIndex-1)//2
	Node.Left = Dual + 1
	Node.Right = Dual + 2
	Node.Value = Value
	Node.NodeIndex = ChildIndex
	Node.NodeID = CustomID or GenID()

	return Node
end

-- Concatenates 2 tables Tbl1 takes priority
local function ConcatTable<T, B>(T1:{T}, T2:{B}) : {T & B}
	for i, v in T2 do
		T1[i] = v
	end
	return T1
end

-- Counts a table bypassing the len metamethod
local function Count(T:{any}):number
	local counter = 0
	for _, __ in T do
		counter += 1
	end
	return counter
end

-- Moves array to fill all gaps, (so ipairs works)
local function Align(T:{BinaryNode})
	local CurrentIndex = 1

	for i = 1, table.maxn(T) do
		if T[i] then
			if i == CurrentIndex then
				CurrentIndex += 1
				continue
			end
			T[CurrentIndex] = T[i]
			CurrentIndex += 1
			T[i] = nil
		end
	end
	return T

end

-- Swaps 2 indicies and their values
local function Swap(T:{any}, I1:number, I2:number, EditTreeValues:boolean)
	local V1:any, V2:any = T[I1], T[I2]

	if EditTreeValues then
		T[I1].Value, T[I2].Value = V2.Value, V1.Value
		T[I1].NodeID, T[I2].NodeID = V2.NodeID, V1.NodeID
	else
		T[I1], T[I2] = V2, V1
	end
	return T
end

-- Grabs the biggest numerical Index (equivialent to table.maxn)
local function MaxN(T:{[number]:any}) : number
	local Max = -math.huge
	for Index, _ in T do
		Max = math.max(Max, Index)
	end
	return Max
end

-- Grabs the Smallest numerical Index (opposite of table.maxn)
local function MinN(T:{[number]:any}) : number
	local Min = math.huge
	for Index, _ in T do
		Min = math.min(Min, Index)
	end
	return Min
end

-- Shifts a table's numerical indicies by a given amount (negitive will go down)
local function Shift<V>(T:{[number]:V}, ShiftAmount:number, Denode:boolean?): {[number]:V}
	if Denode then
		local NT = {}
		if math.sign(ShiftAmount) == 1 then -- Up
			for i = Count(T), MinN(T), -1 do
				NT[i+ShiftAmount] = T[i]
			end
		else
			for i = MinN(T), Count(T), 1 do -- Down
				NT[i+ShiftAmount] = T[i]
			end
		end
		return NT
	else
		if math.sign(ShiftAmount) == 1 then -- Up
			for i = Count(T), MinN(T), -1 do
				T[i+ShiftAmount] = T[i]
				T[i] = nil
			end
		else
			for i = MinN(T), Count(T), 1 do -- Down
				T[i+ShiftAmount] = T[i]
				T[i] = nil
			end
		end
		return T
	end
end

-- Flips a table making the last value first and so on
local function Flip<T>(Tbl:{[number]:T}) : {[number]:T}
	local Max = MaxN(Tbl)
	for i = 1, Max//2 do
		Swap(Tbl, i, (Max-i)+1)
	end
	return Tbl
end

--  Private functions!!  --

local function TreeConstructor()
	local _IDMap = {}
	local TreeMeta = {}
	TreeMeta.__index = TreeMeta
	TreeMeta.Get = function(self, ID:string)
		return self[_IDMap[ID]]
	end
	TreeMeta.Append = function(self, ID:string, Value:number)
		_IDMap[ID] = Value
	end
	TreeMeta.Swap = function(self, ID1:string, ID2:string)
		Swap(_IDMap, ID1, ID2)
	end
	TreeMeta.Print = function(self)
		return _IDMap
	end

	--self.Tree = {} :: {BinaryNode} -- -Old PFFT

	-- Tree behavior
	return setmetatable({}, TreeMeta)
end

-- Sorting Functions

local function Heapify(Tree:Tree, SearchStyle: "Max"|"Min", pointer:any) : {BinaryNode}
	local function GetComparativeValue(Node:BinaryNode) :number
		if not Node then return end

		local ComparativeValue:number
		if pointer then
			ComparativeValue = Node.Value[pointer]
		else
			ComparativeValue = Node.Value
		end
		assert(type(ComparativeValue) == "number", "[SmartTable]: Attempt to get number value got "..typeof(ComparativeValue))
		return ComparativeValue
	end

	local Heap: Tree = TreeConstructor()
	local Index:number = 0

	Shift(Tree, 1) -- Shifts for Ipairs

	if SearchStyle == "Max" then -- The only difference is the sign :Skull:
		for CI:number, Node:BinaryNode in ipairs(Tree) do
			local ParentNode:BinaryNode = Heap[(Index-1)//2] -- Get the added nodes parent
			local ComparativeValue:number, ParentComparativeValue:number = GetComparativeValue(Node), GetComparativeValue(ParentNode)

			local ProjectedIndex = Index
			Heap[Index] = BinaryNodeConstructor(Node.Value, Index, Node.NodeID) -- Insert node into heap
			Heap:Append(Node.NodeID, Index)


			if ParentComparativeValue then
				while ComparativeValue > ParentComparativeValue do
					Heap:Swap(ParentNode.NodeID, Node.NodeID) -- ID swap must be first because it goes off the current table index NOT SAVING
					Swap(Heap, ParentNode.NodeIndex, ProjectedIndex, true) -- Swap the node for the parent

					ProjectedIndex = ParentNode.NodeIndex -- Node now has the parents index

					ParentNode = Heap[ParentNode.Parent]
					ParentComparativeValue = GetComparativeValue(ParentNode)

					if not ParentComparativeValue then break end

				end
			end
			Index += 1
		end
	else
		for CI:number, Node:BinaryNode in ipairs(Tree) do
			local ParentNode:BinaryNode = Heap[(Index-1)//2] -- Get the added nodes parent
			local ComparativeValue:number, ParentComparativeValue:number = GetComparativeValue(Node), GetComparativeValue(ParentNode)

			local ProjectedIndex = Index
			Heap[Index] = BinaryNodeConstructor(Node.Value, Index, Node.NodeID) -- Insert node into heap
			Heap:Append(Node.NodeID, Index)


			if ParentComparativeValue then
				while ComparativeValue < ParentComparativeValue do
					Heap:Swap(ParentNode.NodeID, Node.NodeID)
					Swap(Heap, ParentNode.NodeIndex, ProjectedIndex, true) -- Swap the node for the parent

					ProjectedIndex = ParentNode.NodeIndex -- Node now has the parents index

					ParentNode = Heap[ParentNode.Parent]
					ParentComparativeValue = GetComparativeValue(ParentNode)

					if not ParentComparativeValue then break end

				end
			end
			Index += 1
		end
	end

	return Heap
end

local function BinarySearch(Array:{BinaryNode},Root:number, pointer:any) -- Need to look over for performance and MAYBE rewrite for performance (also needs to work with new id system)
	local function GetComparativeValue(Node:BinaryNode) :number
		if not Node then return nil end

		local ComparativeValue:number
		if pointer then
			ComparativeValue = Node.Value[pointer]
		else
			ComparativeValue = Node.Value
		end
		assert(type(ComparativeValue) == "number", "[SmartTable]: Attempt to get number value got "..typeof(ComparativeValue))
		return ComparativeValue
	end

	local BST:{BinaryNode} = {}

	if Array[0] then -- -- Converts a Binary array to a lua array for loop
		Shift(Array, 1)
	end

	for CurrentIndex:number, Node:BinaryNode in ipairs(Array) do
		--task.wait()
		local NeighborIndex = 0
		local ComparativeValue:number, DesendentValue:number = GetComparativeValue(Node), Root
		while true do
			if ComparativeValue < DesendentValue then
				NeighborIndex = (NeighborIndex*2)+1
			else
				NeighborIndex = (NeighborIndex*2)+2
			end
			DesendentValue = GetComparativeValue(BST[NeighborIndex])
			if not DesendentValue then break end
		end

		BST[NeighborIndex] = BinaryNodeConstructor(ComparativeValue, NeighborIndex)
	end

	BST["Root"] = BST[0]

	return Align(BST)
end

local Smart = {}

Smart.Helper = {
	GenerateUUID = GenID,
	Swap = function<T, B>(Table:{[B]:T}, Index1:B, Index2:B) : {[B]:T} -- Rewritten as the other one is used for binary nodes particularly
		local V1, V2 = Table[Index1], Table[Index2]
		Table[Index1], Table[Index2] = V2, V1
		return Table
	end,
	Shift = Shift,
	Align = Align,
	ConcatTable = ConcatTable,
	Flip = Flip,
	MaxN = MaxN,
	MinN = MinN,
}

-- Queue Sections
local QueueMetaData = {}
QueueMetaData.ClassName = "Queue"


function QueueMetaData:Enter(Value)
	table.insert(self.QueueList, Value)
	self._Last += 1
end

function QueueMetaData:Next()
	if #self.QueueList == 0 then
		return error("[SmartTable]: Attempt to get Next of Nil, (Empty queue)", 100)
	end

	local Data = self.QueueList[self._Next]
	table.remove(self.QueueList, self._Next)
	self._Next += 1
	return Data
end

function QueueMetaData:Size()
	return Count(self.QueueList)
end

function Smart.NewQueue() : Queue
	local self = {}
	self.QueueList = {}

	local QueueMetaSetup = ConcatTable({
		_Next = 1,
		_Last = 0,
	}, QueueMetaData) 

	QueueMetaSetup.__index = QueueMetaSetup
	QueueMetaSetup.__newindex = QueueMetaSetup

	return setmetatable(self, QueueMetaSetup)
end

-- Stack Section
local StackMetaData = {}
StackMetaData.ClassName = "Stack"

function StackMetaData:Shove(Value:any)
	table.insert(self.StackList, Value)
	self._Last += 1
end

function StackMetaData:Pop()
	if self._Last == 0 then
		return error("[SmartTable]: Attempt to get Next of Nil, (Empty Stack)", 100)
	end
	local FOValue = self.StackList[self._Last]
	table.remove(self.StackList, self._Last)
	self._Last -= 1
	return FOValue
end

function StackMetaData:Size()
	return Count(self.StackList)
end

function Smart.NewStack() : Stack
	local self = {}
	self.StackList = {}

	local StackMetaSetup = ConcatTable({
		_Last = 0
	}, StackMetaData)

	StackMetaSetup.__index = StackMetaSetup
	StackMetaSetup.__newindex = StackMetaSetup

	return setmetatable(self, StackMetaSetup)
end

-- BinaryTree Section
local BinaryTreeMetaData = {}
BinaryTreeMetaData.ClassName = "BinaryTree"

function BinaryTreeMetaData:Size()
	return Count(self.Tree)
end

function BinaryTreeMetaData:GetNodeFromIndex(IndexOrID:number?|string?, ReturnValue:boolean?) : BinaryNode | any
	local Node:BinaryNode

	if type(IndexOrID) == "string" then
		Node = self.Tree:Get(IndexOrID)
	else
		Node = self.Tree[IndexOrID]
	end

	if Node then
		if ReturnValue then
			return Node.Value
		else
			return Node
		end
	end
	return nil
end

-- Index only Applies to BST and if nil will result to using Value, (Must be number)
function BinaryTreeMetaData:Insert(Value: any | { any }, Index:number?) : number
	local CurrentIndex = Index or self._NodeIndex
	local Node:BinaryNode = BinaryNodeConstructor(Value, CurrentIndex)

	self.Tree[CurrentIndex] = Node
	self.Tree:Append(Node.NodeID, CurrentIndex) -- Adds ID to map

	--print(getmetatable(self.Tree))

	--table.insert(self.Tree, CurrentIndex, Node)

	self._NodeIndex += 1
	self.Sorted = false
	return Node.NodeID
end

function BinaryTreeMetaData:Update(NodeID:string, NewVal:any | { any })
	local Node:BinaryNode = self.Tree:Get(NodeID)

	assert(type(NodeID) == "string", "[SmartTable]: ID must be a string")
	assert(Node, "[SmartTable]: ID not in map (Use Insert to add a new value and update to update existing values)")
	Node.Value = NewVal

	self.Sorted = false
	self.Tree[Node.NodeIndex] = Node
end

-- Nil will remove the first index/Min index
function BinaryTreeMetaData:Remove(IndexOrId:number | string?) : any -- fix NodeID reseting
	IndexOrId = IndexOrId or 0
	self._NodeIndex -= 1 -- Drop one

	local Data:BinaryNode

	if type(IndexOrId) == "string" then
		Data = self.Tree:Get(IndexOrId)
	else
		Data = self.Tree[IndexOrId]
	end

	if not Data then return error("[SmartTable]: Attempt to remove Node invalid ID, (Node does not exist)",100) end

	local OldestNode:BinaryNode = self.Tree[self._NodeIndex]

	self.Tree:Swap(Data.NodeID, OldestNode.NodeID)
	self.Tree:Append(Data.NodeID, nil) -- Set to nil

	local DataClone:BinaryNode = BinaryNodeConstructor(OldestNode.Value, Data.NodeIndex, OldestNode.NodeID)

	self.Tree[Data.NodeIndex] = DataClone
	self.Tree[OldestNode.NodeIndex] = nil

	self.Sorted = false

	return Data.Value, Data.NodeIndex
end

function BinaryTreeMetaData:Contains(NodeID:string, Remove:boolean?) : boolean | any
	assert(type(NodeID) == "string", "[SmartTable]: ID must be a string")
	local Node:BinaryNode = self.Tree:Get(NodeID)
	if Node then
		if Remove then
			return self:Remove(NodeID)
		end
		return true, Node.NodeIndex
	end
	return false
end

-- Left child, Right child: (Boolean, Boolean)
function BinaryTreeMetaData:AreChildrenExistant(IndexOrID:number?|string?) : (boolean, boolean)
	local Node:BinaryNode
	if type(IndexOrID) == "string" then
		Node = self.Tree:Get(IndexOrID)
	else
		Node = self.Tree[IndexOrID]
	end

	if not Node then return error("[SmartTable]: Attempt to get children of Nil node, (Node does not exist)",100) end
	return (self:GetNodeFromIndex(Node.Left) or false) and true, (self:GetNodeFromIndex(Node.Right) or false) and true
end

-- Returns a array of just values without the node data
function BinaryTreeMetaData:DeNode() : {any}
	if not self.Sorted then return error("[SmartTable]: Tree must be sorted to DeNode") end
	local A = {}

	for i = 0, self._NodeIndex-1 do
		A[i+1] = self.Tree[i].Value
	end
	return A
end

-- Sorting :D
function BinaryTreeMetaData:Sort(Type:"Heapify" | "BST" | "Order", P1, P2)
	local CopyTable = {}
	local Tree:{BinaryNode} = self.Tree

	if Type == "Heapify" then
		CopyTable = Heapify(self.Tree, P1, P2)

	elseif Type == "BST" then
		CopyTable = BinarySearch(Tree, P1, P2)

	elseif Type == "Order" then
		if Tree[0] then
			Shift(Tree, 1) -- Shifts tree to have array start at 1
		end
		local Index = 0
		for _, v:BinaryNode in ipairs(Tree) do -- Sets the tree in the correct sorted order with Parents and Childrens mapped correctly
			CopyTable[Index] = BinaryNodeConstructor(v.Value, Index)
			Index += 1
		end
	end

	self._NodeIndex = Count(Tree) -- Fixed NodeIndex to be based on 0 and not 1
	self.Tree = CopyTable
	self.Sorted = true
end

function Smart.NewBinaryTree() : BinaryTree
	local self = {}
	self.Sorted = false
	self.Tree = TreeConstructor()


	local BTMetaSetup = ConcatTable({
		_NodeIndex = 0, -- Will always show the Next nodes index

	}, BinaryTreeMetaData)

	BTMetaSetup.__index = BTMetaSetup
	BTMetaSetup.__newindex = BTMetaSetup

	return setmetatable(self, BTMetaSetup)
end

return Smart :: typeof(Smart)
-- 600+ lines :fire