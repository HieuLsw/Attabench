//
//  SharedInsertionBenchmark.swift
//  Attabench
//
//  Created by Károly Lőrentey on 2017-02-27.
//  Copyright © 2017 Károly Lőrentey.
//

import Foundation
import BenchmarkingTools

func sharedInsertionBenchmark(iterations: Int = 10, maxScale: Int = 15, random: Bool = true) -> Benchmark<[Int]> {
    let orders = [1024] //[8, 16, 32, 64, 128, 256, 512, 768, 1024, 1500, 2048]
    let internalOrders = [16] //[5, 8, 16, 32, 64, 128]

    let benchmark = Benchmark<[Int]>(title: "SharedInsertion")
    benchmark.descriptiveTitle = "Random insertions into shared storage"
    benchmark.descriptiveAmortizedTitle = "One random insertion into shared storage"

    func add<T: SortedSet>(_ title: String, for type: T.Type = T.self, maxCount: Int? = nil, to benchmark: Benchmark<[Int]>, _ initializer: @escaping () -> T = T.init) where T.Iterator.Element == Int {
        benchmark.addTask(title: title) { input in
            if let maxCount = maxCount, input.count > maxCount { return nil }
            var first = true
            return { timer in
                var set = initializer()
                timer.measure {
                    #if false
                        var copy = set
                        var k = 0
                        for value in input {
                            set.insert(value)
                            precondition(!copy.contains(value))
                            precondition(set.contains(value))
                            copy = set

                            do {
                                var i = 0
                                let test = input.prefix(through: k).sorted()
                                set.forEach { value in
                                    guard value == test[i] else { fatalError("Expected \(test[i]), got \(value)") }
                                    i += 1
                                }
                                set.validate()
                            }
                            k += 1
                        }
                        _ = copy
                    #else
                        var copy = set
                        for value in input {
                            set.insert(value)
                            copy = set
                        }
                        _ = copy
                    #endif
                }

                if first {
                    var i = 0
                    set.forEach { value in
                        guard value == i else { fatalError("Expected \(i), got \(value)") }
                        i += 1
                    }
                    set.validate()
                    first = false
                }
            }
        }
    }

    add("SortedArray", for: SortedArray<Int>.self, maxCount: 130_000, to: benchmark)
    add("OrderedSet", for: OrderedSet<Int>.self, maxCount: 2048, to: benchmark)
    add("RedBlackTree", for: RedBlackTree<Int>.self, to: benchmark)
    //add("BinaryTree", for: BinaryTree<Int>.self, to: benchmark)
    add("RedBlackTree2", for: RedBlackTree2<Int>.self, to: benchmark)

    for order in orders {
        add("BTree/\(order)", to: benchmark) { BTree<Int>(order: order) }
    }
    for order in orders {
        add("BTree2/\(order)", to: benchmark) { BTree2<Int>(order: order) }
    }
    for order in orders {
        add("BTree3/\(order)", to: benchmark) { BTree3<Int>(order: order) }
    }
    for order in orders {
        add("BTree4/\(order)-16", to: benchmark) { BTree4<Int>(order: order) }
    }
//    for order in orders {
//        for internalOrder in internalOrders {
//            add("IntBTree/\(order)-\(internalOrder)", to: benchmark) { IntBTree(leafOrder: order, internalOrder: internalOrder) }
//        }
//    }

    benchmark.addTask(title: "Array.sort") { input in
        guard input.count < 130_000 else { return nil }
        return { timer in
            var array: [Int] = []
            var copy = array
            for value in input {
                array.append(value)
                copy = array
            }
            array.sort()
            _ = copy
        }
    }
    
    return benchmark
}
