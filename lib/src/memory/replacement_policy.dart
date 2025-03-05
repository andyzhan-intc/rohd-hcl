// Copyright (C) 2025 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
// replacement_policy.dart
// A module implementing Least Recently Used (LRU) replacement policy.
//
// 2025 March 5
// Author: Ke Liu <ke2.liu@intel.com>

import 'package:rohd/rohd.dart';

/// A module implementing Least Recently Used (LRU) replacement policy.
class LRUReplacementPolicy extends Module {
  /// The number of cache lines.
  final int numLines;

  /// The width of the address.
  final int addrWidth;

  /// The clock signal.
  Logic get clk => input('clk');

  /// The reset signal.
  Logic get reset => input('reset');

  /// The address of the accessed line.
  Logic get accessAddr => input('accessAddr');

  /// The enable signal for access.
  Logic get accessEn => input('accessEn');

  /// The output signal indicating the least recently used line.
  Logic get lruLine => output('lruLine');

  /// Internal storage for LRU counters.
  late final List<Logic> _lruCounters;

  LRUReplacementPolicy(Logic clk, Logic reset, Logic accessAddr, Logic accessEn,
      {this.numLines = 8, this.addrWidth = 4, super.name = 'lru_policy'})
      : super(definitionName: 'LRUReplacementPolicy') {
    addInput('clk', clk);
    addInput('reset', reset);
    addInput('accessAddr', accessAddr, width: addrWidth);
    addInput('accessEn', accessEn);
    addOutput('lruLine', width: addrWidth);

    _buildLogic();
  }

  void _buildLogic() {
    // Initialize LRU counters
    _lruCounters = List<Logic>.generate(
        numLines, (i) => Logic(name: 'lruCounter_$i', width: addrWidth));

    Sequential(clk, [
      If(reset, then: [
        // Reset all LRU counters
        ..._lruCounters.map((counter) => counter < 0)
      ], orElse: [
        If(accessEn, then: [
          // Increment all counters
          ..._lruCounters.map((counter) => counter < counter + 1),
          // Reset the counter for the accessed line
          _lruCounters[accessAddr.toInt()] < 0
        ])
      ])
    ]);

    // Determine the least recently used line
    Combinational([
      Case(Const(0, width: addrWidth), [
        for (var i = 0; i < numLines; i++)
          CaseItem(Const(LogicValue.ofInt(i, addrWidth)), [
            If(_lruCounters[i] > _lruCounters[lruLine.toInt()], then: [
              lruLine < Const(LogicValue.ofInt(i, addrWidth))
            ])
          ])
      ])
    ]);
  }
}
