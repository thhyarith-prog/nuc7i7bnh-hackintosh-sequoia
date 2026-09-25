// gpuburn <seconds> : Metal compute ALU load, prints GFLOP-ish rate every 5 s
import Metal
import Foundation
let secs = Double(CommandLine.arguments[1])!
let dev = MTLCreateSystemDefaultDevice()!
let src = """
#include <metal_stdlib>
using namespace metal;
kernel void burn(device float *o [[buffer(0)]], uint i [[thread_position_in_grid]]) {
  float a = float(i) * 0.0001f, b = 1.0001f;
  for (int k = 0; k < 4096; k++) { a = fma(a, b, 0.0001f); b = fma(b, 0.99999f, 0.00001f); }
  o[i] = a + b;
}
"""
let lib = try! dev.makeLibrary(source: src, options: nil)
let pso = try! dev.makeComputePipelineState(function: lib.makeFunction(name: "burn")!)
let n = 1 << 20
let buf = dev.makeBuffer(length: n * 4, options: .storageModePrivate)!
let q = dev.makeCommandQueue()!
let start = Date(); var mark = Date(); var batches = 0
print("\(Int(Date().timeIntervalSince1970)) gpu_name \(dev.name.replacingOccurrences(of: " ", with: "_"))")
while Date().timeIntervalSince(start) < secs {
  let cb = q.makeCommandBuffer()!; let e = cb.makeComputeCommandEncoder()!
  e.setComputePipelineState(pso); e.setBuffer(buf, offset: 0, index: 0)
  e.dispatchThreads(MTLSize(width: n, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: pso.maxTotalThreadsPerThreadgroup, height: 1, depth: 1))
  e.endEncoding(); cb.commit(); cb.waitUntilCompleted(); batches += 1
  let dt = Date().timeIntervalSince(mark)
  if dt >= 5 { let gflops = Double(batches) * Double(n) * 4096 * 4 / dt / 1e9
    print("\(Int(Date().timeIntervalSince1970)) gpu_gflops \(String(format: "%.1f", gflops))"); fflush(stdout); batches = 0; mark = Date() }
}
