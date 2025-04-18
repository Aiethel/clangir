//===- cir-opt.cpp - CIR optimization and analysis driver -----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Similar to MLIR/LLVM's "opt" tools but also deals with analysis and custom
// arguments. TODO: this is basically a copy from MlirOptMain.cpp, but capable
// of module emission as specified by the user.
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ReconcileUnrealizedCasts/ReconcileUnrealizedCasts.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/DLTI/DLTI.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/OpenMP/OpenMPDialect.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Pass/PassOptions.h"
#include "mlir/Pass/PassRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "clang/CIR/Dialect/IR/CIRDialect.h"
#include "clang/CIR/Dialect/Passes.h"
#include "clang/CIR/Passes.h"

struct CIRToLLVMPipelineOptions
    : public mlir::PassPipelineOptions<CIRToLLVMPipelineOptions> {
  // When lowering to LLVM, we should apply the CC lowering pass by default. The
  // option below allows us to disable it for testing purposes.
  Option<bool> disableCCLowering{
      *this, "disable-cc-lowering",
      llvm::cl::desc("Skips calling convetion lowering pass."),
      llvm::cl::init(false)};
};

int main(int argc, char **argv) {
  // TODO: register needed MLIR passes for CIR?
  mlir::DialectRegistry registry;
  registry
      .insert<mlir::BuiltinDialect, mlir::arith::ArithDialect, cir::CIRDialect,
              mlir::memref::MemRefDialect, mlir::LLVM::LLVMDialect,
              mlir::DLTIDialect, mlir::omp::OpenMPDialect>();

  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return cir::createConvertMLIRToLLVMPass();
  });
  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return mlir::createCIRCanonicalizePass();
  });
  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return mlir::createCIRSimplifyPass();
  });

  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return mlir::createSCFPreparePass();
  });
  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return cir::createConvertCIRToMLIRPass();
  });

  mlir::PassPipelineRegistration<CIRToLLVMPipelineOptions> pipeline(
      "cir-to-llvm", "",
      [](mlir::OpPassManager &pm, const CIRToLLVMPipelineOptions &options) {
        cir::direct::populateCIRToLLVMPasses(pm, options.disableCCLowering);
      });

  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return mlir::createFlattenCFGPass();
  });

  ::mlir::registerPass([]() -> std::unique_ptr<::mlir::Pass> {
    return mlir::createReconcileUnrealizedCastsPass();
  });

  mlir::registerTransformsPasses();

  return failed(MlirOptMain(
      argc, argv, "Clang IR analysis and optimization tool\n", registry));
}
