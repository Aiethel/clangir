//--------------------------------------------------------------------------------------------------
// Test expected errors in terms of the shape and type of tensor, and the argument type of
// operation. Excludes the profile compilance checking since it is performed earlier in the
// validation flow.
//--------------------------------------------------------------------------------------------------

// RUN: mlir-opt %s -split-input-file -verify-diagnostics --tosa-validate="profile=pro_int,pro_fp extension=int16,int4,bf16,fp8e4m3,fp8e5m2,fft,variable,controlflow strict-op-spec-alignment"

func.func @test_const() -> tensor<1xf32> {
  // expected-error@+1{{'tosa.const' op expected same attr/result element types}}
  %0 = "tosa.const"() {value = dense<1> : tensor<1xi32>} : () -> tensor<1xf32>
  return %0 : tensor<1xf32>
}

// -----

func.func @test_const_non_tensor_attr() {
  // expected-error@+1{{tosa.const' op expected tensors for attr/result type}}
  %0 = "tosa.const"() {value = dense<1.0> : vector<f32>} : () -> tensor<f32>
  return
}

// -----

func.func @test_conv2d(%arg0: tensor<1x29x29x4xf32>, %arg1: tensor<16x3x3x4xi8>, %arg2: tensor<16xi8>) -> tensor<1x27x27x16xi8> {
  %input_zp = "tosa.const"() <{value = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  %weight_zp = "tosa.const"() <{value = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op expect both input and weight to be float or not together, got 'f32' and 'i8'}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf32>, tensor<16x3x3x4xi8>, tensor<16xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x27x27x16xi8>
  return %0 : tensor<1x27x27x16xi8>
}

// -----

func.func @test_conv2d(%arg0: tensor<*xi8>, %arg1: tensor<16x3x3x4xi8>, %arg2: tensor<16xi8>) -> tensor<1x27x27x16xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op expect a ranked tensor for input, got <block argument> of type 'tensor<*xi8>' at index: 0}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<*xi8>, tensor<16x3x3x4xi8>, tensor<16xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x27x27x16xi8>
  return %0 : tensor<1x27x27x16xi8>
}

// -----

func.func @test_conv2d(%arg0: tensor<1x29x29x4xi8>, %arg1: tensor<*xi8>, %arg2: tensor<16xi8>) -> tensor<1x27x27x16xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op operand #1 must be 4D tensor of 4-bit signless integer or 8-bit signless integer or Quint8 type or Qint4 type or Qint8 type or Qint16 type or Qint32 type or floating-point values, but got 'tensor<*xi8>'}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xi8>, tensor<*xi8>, tensor<16xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x27x27x16xi8>
  return %0 : tensor<1x27x27x16xi8>
}

// -----

func.func @test_conv2d_input_zp(%arg0: tensor<1x29x29x4xf16>, %arg1: tensor<16x3x3x4xf16>, %arg2: tensor<16xf16>) -> tensor<1x27x27x16xf16> {
  %input_zp = "tosa.const"() <{value = dense<-1.0> : tensor<1xf16>}> : () -> tensor<1xf16>
  %weight_zp = "tosa.const"() <{value = dense<0.0> : tensor<1xf16>}> : () -> tensor<1xf16>
  // expected-error@+1 {{'tosa.conv2d' op non-zero zero point is not allowed for float types}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = f16, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf16>, tensor<16x3x3x4xf16>, tensor<16xf16>, tensor<1xf16>, tensor<1xf16>) -> tensor<1x27x27x16xf16>
  return %0 : tensor<1x27x27x16xf16>
}

// -----

func.func @test_conv2d_weight_zp(%arg0: tensor<1x29x29x4xf16>, %arg1: tensor<16x3x3x4xf16>, %arg2: tensor<16xf16>) -> tensor<1x27x27x16xf16> {
  %input_zp = "tosa.const"() <{value = dense<0.0> : tensor<1xf16>}> : () -> tensor<1xf16>
  %weight_zp = "tosa.const"() <{value = dense<-1.0> : tensor<1xf16>}> : () -> tensor<1xf16>
  // expected-error@+1 {{'tosa.conv2d' op non-zero zero point is not allowed for float types}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = f16, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf16>, tensor<16x3x3x4xf16>, tensor<16xf16>, tensor<1xf16>, tensor<1xf16>) -> tensor<1x27x27x16xf16>
  return %0 : tensor<1x27x27x16xf16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xi8>, %arg1: tensor<16x3x3x4xi8>, %arg2: tensor<16xi8>) -> tensor<1x27x27x16xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for i8 tensor is not i32}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = f16, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xi8>, tensor<16x3x3x4xi8>, tensor<16xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x27x27x16xi8>
  return %0 : tensor<1x27x27x16xi8>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xi16>, %arg1: tensor<16x3x3x4xi8>, %arg2: tensor<16xi16>) -> tensor<1x27x27x16xi16> {
  %input_zp = "tosa.const"() {value = dense<0> : tensor<1xi16>} : () -> tensor<1xi16>
  %weight_zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for i16 tensor is not i48}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = f16, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xi16>, tensor<16x3x3x4xi8>, tensor<16xi16>, tensor<1xi16>, tensor<1xi8>) -> tensor<1x27x27x16xi16>
  return %0 : tensor<1x27x27x16xi16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xf8E5M2>, %arg1: tensor<16x3x3x4xf8E5M2>, %arg2: tensor<16xf16>) -> tensor<1x27x27x16xf16> {
  %zp = "tosa.const"() {value = dense<0.0> : tensor<1xf8E5M2>} : () -> tensor<1xf8E5M2>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for f8 tensor is not f16}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf8E5M2>, tensor<16x3x3x4xf8E5M2>, tensor<16xf16>, tensor<1xf8E5M2>, tensor<1xf8E5M2>) -> tensor<1x27x27x16xf16>
  return %0 : tensor<1x27x27x16xf16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xf8E4M3>, %arg1: tensor<16x3x3x4xf8E4M3>, %arg2: tensor<16xf16>) -> tensor<1x27x27x16xf16> {
  %zp = "tosa.const"() {value = dense<0.0> : tensor<1xf8E4M3>} : () -> tensor<1xf8E4M3>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for f8 tensor is not f16}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf8E4M3>, tensor<16x3x3x4xf8E4M3>, tensor<16xf16>, tensor<1xf8E4M3>, tensor<1xf8E4M3>) -> tensor<1x27x27x16xf16>
  return %0 : tensor<1x27x27x16xf16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xf16>, %arg1: tensor<16x3x3x4xf16>, %arg2: tensor<16xf16>) -> tensor<1x27x27x16xf16> {
  %zp = "tosa.const"() {value = dense<0.0> : tensor<1xf16>} : () -> tensor<1xf16>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for f16 tensor is not f16/f32}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf16>, tensor<16x3x3x4xf16>, tensor<16xf16>, tensor<1xf16>, tensor<1xf16>) -> tensor<1x27x27x16xf16>
  return %0 : tensor<1x27x27x16xf16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xbf16>, %arg1: tensor<16x3x3x4xbf16>, %arg2: tensor<16xbf16>) -> tensor<1x27x27x16xbf16> {
  %zp = "tosa.const"() {value = dense<0.0> : tensor<1xbf16>} : () -> tensor<1xbf16>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for bf16 tensor is not f32}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xbf16>, tensor<16x3x3x4xbf16>, tensor<16xbf16>, tensor<1xbf16>, tensor<1xbf16>) -> tensor<1x27x27x16xbf16>
  return %0 : tensor<1x27x27x16xbf16>
}

// -----

func.func @test_conv2d_acc_type(%arg0: tensor<1x29x29x4xf32>, %arg1: tensor<16x3x3x4xf32>, %arg2: tensor<16xf32>) -> tensor<1x27x27x16xf32> {
  %zp = "tosa.const"() {value = dense<0.0> : tensor<1xf32>} : () -> tensor<1xf32>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for f32 tensor is not f32}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x29x4xf32>, tensor<16x3x3x4xf32>, tensor<16xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x27x27x16xf32>
  return %0 : tensor<1x27x27x16xf32>
}

// -----

func.func @test_conv3d_acc_type(%arg0: tensor<1x4x8x21x17xi8>, %arg1: tensor<34x1x1x1x17xi8>, %arg2: tensor<34xi8>) -> tensor<1x4x8x21x34xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv3d' op accumulator type for i8 tensor is not i32}}
  %0 = tosa.conv3d %arg0, %arg1, %arg2, %zp, %zp {acc_type = f16, dilation = array<i64: 1, 1, 1>, pad = array<i64: 0, 0, 0, 0, 0, 0>, stride = array<i64: 1, 1, 1>}
           : (tensor<1x4x8x21x17xi8>, tensor<34x1x1x1x17xi8>, tensor<34xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x4x8x21x34xi8>
  return %0 : tensor<1x4x8x21x34xi8>
}

// -----

func.func @test_depthwise_conv2d_acc_type(%arg0: tensor<1x4x4x4xi8>, %arg1: tensor<1x1x4x2xi8>, %arg2: tensor<8xi8>) -> tensor<1x4x4x8xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.depthwise_conv2d' op accumulator type for i8 tensor is not i32}}
  %0 = tosa.depthwise_conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = f16, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x4x4x4xi8>, tensor<1x1x4x2xi8>, tensor<8xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x4x4x8xi8>
  return %0 : tensor<1x4x4x8xi8>
}

// -----

func.func @test_transpose_conv2d(%arg0: tensor<1x32x32x8xi8>, %arg1: tensor<16x1x1x8xi8>, %arg2: tensor<16xi8>) -> tensor<1x32x32x16xi8> {
  %zp = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.transpose_conv2d' op accumulator type for i8 tensor is not i32}}
  %0 = tosa.transpose_conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = f16, out_pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>} : (tensor<1x32x32x8xi8>, tensor<16x1x1x8xi8>, tensor<16xi8>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x32x32x16xi8>
  return %0 : tensor<1x32x32x16xi8>
}

// -----
// CHECK-LABEL: conv2d_quant_any_acc
func.func @test_conv2d_quant_any_acc(%arg0: tensor<1x4x4x4x!quant.any<i8<-8:7>>>, %arg1: tensor<8x1x1x4x!quant.any<i8<-8:7>>>, %arg2: tensor<8x!quant.any<i8<-8:7>>>) -> tensor<1x4x4x8x!quant.any<i8<-8:7>>> {
  %zp = "tosa.const" () { value = dense<0> : tensor<1xi8> } : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op accumulator type for i8 tensor is not i32}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true} : (tensor<1x4x4x4x!quant.any<i8<-8:7>>>, tensor<8x1x1x4x!quant.any<i8<-8:7>>>, tensor<8x!quant.any<i8<-8:7>>>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x4x4x8x!quant.any<i8<-8:7>>>
  return %0 : tensor<1x4x4x8x!quant.any<i8<-8:7>>>
}

// -----
// CHECK-LABEL: conv2d_quant_any_result
func.func @test_conv2d_quant_any_result(%arg0: tensor<1x4x4x4x!quant.any<i8<-8:7>>>, %arg1: tensor<8x1x1x4x!quant.any<i8<-8:7>>>, %arg2: tensor<8x!quant.any<i8<-8:7>>>) -> tensor<1x4x4x8x!quant.any<i8<-8:7>>> {
  %zp = "tosa.const" () { value = dense<0> : tensor<1xi8> } : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.conv2d' op input/output element types are incompatible}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %zp, %zp {acc_type = i32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true} : (tensor<1x4x4x4x!quant.any<i8<-8:7>>>, tensor<8x1x1x4x!quant.any<i8<-8:7>>>, tensor<8x!quant.any<i8<-8:7>>>, tensor<1xi8>, tensor<1xi8>) -> tensor<1x4x4x8x!quant.any<i8<-8:7>>>
  return %0 : tensor<1x4x4x8x!quant.any<i8<-8:7>>>
}

// -----

func.func @test_concat(%arg0 : tensor<2x1xf32>, %arg1 : tensor<2x2xf32>) -> tensor<?x?xf32> {
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{Cannot concat tensors with different sizes on the non-axis dimension 1}}
  %0 = tosa.concat %arg0, %arg1 {axis = 0 : i32} : (tensor<2x1xf32>, tensor<2x2xf32>) -> tensor<?x?xf32>
  return %0 : tensor<?x?xf32>
}

// -----

func.func @test_concat_element_type_mismatch(%arg0 : tensor<1x2xf32>, %arg1 : tensor<2x2xf32>) -> tensor<?x?xi8> {
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{'tosa.concat' op inferred type(s) 'tensor<3x2xf32>' are incompatible with return type(s) of operation 'tensor<?x?xi8>}}
  %0 = tosa.concat %arg0, %arg1 {axis = 0 : i32} : (tensor<1x2xf32>, tensor<2x2xf32>) -> tensor<?x?xi8>
  return %0 : tensor<?x?xi8>
}

// -----

func.func @test_pad_non_const(%arg0: tensor<13x21x3xf32>, %arg1: !tosa.shape<6>) -> tensor<13x21x3xf32> {
  // expected-error@+1 {{'tosa.pad' op shape operand is not compile time resolvable}}
  %0 = tosa.pad %arg0, %arg1 : (tensor<13x21x3xf32>, !tosa.shape<6>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----

func.func @test_pad_non_const(%arg0: tensor<13x21x3xi8>, %arg1: tensor<i8>) -> tensor<13x21x3xi8> {
  %0 = tosa.const_shape {value = dense<[0, 0, 0, 1, 0, 1]> : tensor<6xindex>} : () -> !tosa.shape<6>
  // expected-error@+1 {{'tosa.pad' op pad_const of pad is not constant}}
  %1 = tosa.pad %arg0, %0, %arg1 : (tensor<13x21x3xi8>, !tosa.shape<6>, tensor<i8>) -> tensor<13x21x3xi8>
  return %1 : tensor<13x21x3xi8>
}

// -----

func.func @test_pad_io_rank_mismatch(%arg0: tensor<13x21xf32>) {
  %padding = tosa.const_shape {value = dense<0> : tensor<4xindex>} : () -> !tosa.shape<4>
  // expected-error@+1 {{'tosa.pad' op expect same input and output tensor rank.}}
  %1 = tosa.pad %arg0, %padding : (tensor<13x21xf32>, !tosa.shape<4>) -> tensor<13x21x3xf32>
  return
}

// -----

func.func @test_pad_invalid_padding_rank(%arg0: tensor<13x21xf32>) {
  %0 = tosa.const_shape {value = dense<1> : tensor<6xindex>} : () -> !tosa.shape<6>
  // expected-error@+1 {{'tosa.pad' op expected padding tensor dim 0 to have size 4 (2*rank(shape1)) but got size 6}}
  %1 = tosa.pad %arg0, %0 : (tensor<13x21xf32>, !tosa.shape<6>) -> tensor<13x21xf32>
  return
}

// -----

func.func @test_pad_invalid_padConst_rank(%arg0: tensor<13x21xf32>, %arg1: tensor<2x2xi32>) {
  %0 = tosa.const_shape {value = dense<1> : tensor<4xindex>} : () -> !tosa.shape<4>
  %1 = "tosa.const"() {value = dense<3.14> : tensor<2xf32>} : () -> tensor<2xf32>
  // expected-error@+1 {{'tosa.pad' op operand #2 must be 0D tensor of number values, but got 'tensor<2xf32>'}}
  %2 = tosa.pad %arg0, %0, %1 : (tensor<13x21xf32>, !tosa.shape<4>, tensor<2xf32>) -> tensor<13x21xf32>
  return
}

// -----

func.func @test_pad_padding_shape_mismatch(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf32> {
  %0 = tosa.const_shape {value = dense<1> : tensor<4xindex>} : () -> !tosa.shape<4>
  // expected-error@+1 {{'tosa.pad' op expected padding tensor dim 0 to have size 6 (2*rank(shape1)) but got size 4}}
  %1 = tosa.pad %arg0, %0 : (tensor<13x21x3xf32>, !tosa.shape<4>) -> tensor<13x21x3xf32>
  return %1 : tensor<13x21x3xf32>
}

// -----

func.func @test_transpose_io_rank_mismatch(%arg0: tensor<13x21x3xf32>, %arg1: tensor<3xi32>) -> tensor<3x13x21x1xf32> {
  // expected-error@+1 {{'tosa.transpose' op expected input tensor rank to equal result tensor rank}}
  %0 = tosa.transpose %arg0 {perms = array<i32: 2, 1, 0>}: (tensor<13x21x3xf32>) -> tensor<3x13x21x1xf32>
  return %0 : tensor<3x13x21x1xf32>
}

// -----

func.func @test_transpose_rank0_perms() {
  %14 = tensor.empty() : tensor<5x27xi64>
  // expected-error@+1 {{'tosa.transpose' op expected perms attribute to have size 2 (input rank) but got size 0}}
  %72 = tosa.transpose %14 {perms = array<i32> }: (tensor<5x27xi64>) -> tensor<?x?xi64>
  return
}

// -----

func.func @test_transpose_invalid_perms_size(%arg0: tensor<13x21x3xf32>) -> tensor<3x13x21xf32> {
  // expected-error@+1 {{'tosa.transpose' op expected perms attribute to have size 3 (input rank) but got size 7}}
  %0 = tosa.transpose %arg0 {perms = array<i32: 6, 5, 4, 3, 2, 1, 0> }: (tensor<13x21x3xf32>) -> tensor<3x13x21xf32>
  return %0 : tensor<3x13x21xf32>
}

// -----

func.func @test_transpose_invalid_permutation_tensor(%arg0: tensor<13x21x3xf32>) -> tensor<?x?x?xf32> {
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %0 = tosa.transpose %arg0 {perms = array<i32: 2, 0, 0> }: (tensor<13x21x3xf32>) -> tensor<?x?x?xf32>
  return %0 : tensor<?x?x?xf32>
}

// -----

func.func @test_transpose_invalid_permutation_negative(%arg0: tensor<3x2xi32>) -> tensor<*xi32> {
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %1 = tosa.transpose %arg0 {perms = array<i32: -1, 0> }: (tensor<3x2xi32>) -> tensor<*xi32>
  return %1 : tensor<*xi32>
}

// -----

func.func @test_transpose_invalid_permutation_tensor_above_range(%arg0: tensor<3x2xi32>) -> tensor<*xi32> {
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %1 = tosa.transpose %arg0 {perms = array<i32: 2, 0> }: (tensor<3x2xi32>) -> tensor<*xi32>
  return %1 : tensor<*xi32>
}

// -----

func.func @test_transpose_invalid_permutation_types(%arg0: tensor<3x2xi32>) -> tensor<3x4xi32> {
  // expected-error@+1 {{'tosa.transpose' op expected output tensor dim 0 to match input dim 1 with value of 2}}
  %1 = tosa.transpose %arg0 {perms = array<i32: 1, 0> }: (tensor<3x2xi32>) -> tensor<3x4xi32>
  return %1 : tensor<3x4xi32>
}

// -----

func.func @test_transpose_invalid_permutation_types_dynamic_dim_ok(%arg0: tensor<2x?xi32>) -> tensor<3x4xi32> {
  // expected-error@+1 {{'tosa.transpose' op expected output tensor dim 1 to match input dim 0 with value of 2}}
  %1 = tosa.transpose %arg0 {perms = array<i32: 1, 0> }: (tensor<2x?xi32>) -> tensor<3x4xi32>
  return %1 : tensor<3x4xi32>
}

// -----

func.func @test_transpose_element_type_mismatch(%arg0: tensor<2x3xi32>) -> tensor<3x2xf32> {
  // expected-error@+1 {{'tosa.transpose' op failed to verify that all of {input1, output} have same element type}}
  %1 = tosa.transpose %arg0 {perms = array<i32: 1, 0>} : (tensor<2x3xi32>) -> tensor<3x2xf32>
  return %1 : tensor<3x2xf32>
}

// -----

func.func @test_reduce_sum_type_mismatch(%arg0 : tensor<2x3x4x5xf32>) -> () {
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{'tosa.reduce_sum' op inferred type(s) 'tensor<1x3x4x5xf32>' are incompatible with return type(s) of operation 'tensor<1x3x4x5xi32>'}}
  %0 = tosa.reduce_sum %arg0 {axis = 0 : i32} : (tensor<2x3x4x5xf32>) -> tensor<1x3x4x5xi32>
  return
}

// -----

func.func @test_reduce_max_type_mismatch(%arg0 : tensor<2x3x4x5xf32>) -> () {
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{'tosa.reduce_max' op inferred type(s) 'tensor<2x3x4x1xf32>' are incompatible with return type(s) of operation 'tensor<2x3x4x1xi32>'}}
  %0 = tosa.reduce_max %arg0 {axis = 3 : i32} : (tensor<2x3x4x5xf32>) -> tensor<2x3x4x1xi32>
  return
}

// -----

func.func @test_reduce_min_type_mismatch(%arg0 : tensor<2x3x4x5xf32>) -> () {
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{'tosa.reduce_min' op inferred type(s) 'tensor<2x1x4x5xf32>' are incompatible with return type(s) of operation 'tensor<2x1x4x5xi32>'}}
  %0 = tosa.reduce_min %arg0 {axis = 1 : i32} : (tensor<2x3x4x5xf32>) -> tensor<2x1x4x5xi32>
  return
}

// -----

func.func @test_reduce_prod_type_mismatch(%arg0 : tensor<2x3x4x5xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_product' op expect reduced dimension size to be 1, got 3}}
  %0 = tosa.reduce_product %arg0 {axis = 1 : i32} : (tensor<2x3x4x5xf32>) -> tensor<2x3x4x5xf32>
  return
}

// -----

func.func @test_reduce_all_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_all' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_all %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_any_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_any' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_any %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_max_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_max' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_max %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_min_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_min' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_min %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_prod_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_product' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_product %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_sum_invalid_axis(%arg0 : tensor<2x3x4xf32>) -> () {
  // expected-error@+1 {{'tosa.reduce_sum' op expect input tensor rank (3) to be larger than reduce axis (3)}}
  %0 = tosa.reduce_sum %arg0 {axis = 3 : i32} : (tensor<2x3x4xf32>) -> tensor<2x3x1xf32>
  return
}

// -----

func.func @test_reduce_min_invalid_output_rank(%arg0 : tensor<i32>) -> () {
  // expected-error@+1 {{'tosa.reduce_min' op expect output tensor rank to be equal to input tensor rank}}
  %0 = tosa.reduce_min %arg0 {axis = 0 : i32} : (tensor<i32>) -> tensor<1x10xi32>
  return
}

// -----

func.func @test_reshape_type_mismatch(%arg0 : tensor<13x21x3xf32>) -> () {
  %1 = tosa.const_shape {value = dense<[13, 21, 3, 1]> : tensor<4xindex>} : () -> !tosa.shape<4>
  // expected-error@+2 {{failed to infer returned types}}
  // expected-error@+1 {{'tosa.reshape' op inferred type(s) 'tensor<13x21x3x1xf32>' are incompatible with return type(s) of operation 'tensor<13x21x3x1xi32>'}}
  %0 = tosa.reshape %arg0, %1 : (tensor<13x21x3xf32>, !tosa.shape<4>) -> tensor<13x21x3x1xi32>
  return
}

// -----

func.func @test_reshape_static_zero_dim_input(%arg0 : tensor<13x0x3xf32>) -> () {
  %s = tosa.const_shape {value = dense<[13, 21, 3]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.reshape' op operand #0 must be tosa-conformant tensor of number values, but got 'tensor<13x0x3xf32>'}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<13x0x3xf32>, !tosa.shape<3>) -> tensor<13x0x3xf32>
  return
}

// -----

func.func @test_reshape_zero_dim_input(%arg0 : tensor<?x0x3xf32>) -> () {
  %s = tosa.const_shape {value = dense<[13, 21, 3]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.reshape' op operand #0 must be tosa-conformant tensor of number values, but got 'tensor<?x0x3xf32>'}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<?x0x3xf32>, !tosa.shape<3>) -> tensor<13x0x3xf32>
  return
}

// -----

func.func @test_reshape_rank_mismatch(%arg0 : tensor<?xf32>) -> () {
  %s = tosa.const_shape {value = dense<[2, 4]> : tensor<2xindex>} : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.reshape' op new shape does not match result rank}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<?xf32>, !tosa.shape<2>) -> tensor<?xf32>
  return
}

// -----

func.func @test_reshape_inconsistent_result_type(%arg0 : tensor<?xf32>) -> () {
  %s = tosa.const_shape {value = dense<[2, 4, -1]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.reshape' op new shape is inconsistent with result shape}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<?xf32>, !tosa.shape<3>) -> tensor<?x3x5xf32>
  return
}

// -----

func.func @test_reshape_invalid_size(%arg0 : tensor<2x4xf32>) -> () {
  %s = tosa.const_shape {value = dense<[3, 5]> : tensor<2xindex>} : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.reshape' op cannot reshape 8 elements into 15}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<2x4xf32>, !tosa.shape<2>) -> tensor<3x5xf32>
  return
}

// -----

func.func @test_reshape_invalid_newshape(%arg0 : tensor<1xf32>) -> () {
  %s = tosa.const_shape {value = dense<[-1, 4]> : tensor<2xindex>} : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.reshape' op cannot reshape 1 elements into 4}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<1xf32>, !tosa.shape<2>) -> tensor<?x4xf32>
  return
}

// -----

func.func @test_reshape_invalid_newshape(%arg0 : tensor<8xf32>) -> () {
  %s = tosa.const_shape {value = dense<[1, 4]> : tensor<2xindex>} : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.reshape' op cannot reshape 8 elements into 4}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<8xf32>, !tosa.shape<2>) -> tensor<?x4xf32>
  return
}

// -----

func.func @test_reshape_invalid_placeholders(%arg0 : tensor<?xf32>) -> () {
  %s = tosa.const_shape {value = dense<[2, -1, -1]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.reshape' op expected at most one target dimension to be -1}}
  %0 = "tosa.reshape"(%arg0, %s) : (tensor<?xf32>, !tosa.shape<3>) -> tensor<2x?x?xf32>
  return
}

// -----

func.func @test_reshape_invalid_tensor_dim(%arg0 : tensor<4x?xf32>) -> () {
  %s = tosa.const_shape {value = dense<[-2, -1]> : tensor<2xindex>} : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.reshape' op new shape has invalid tensor dimension size -2}}
  %0 = "tosa.reshape" (%arg0, %s) : (tensor<4x?xf32>, !tosa.shape<2>) -> tensor<?x4xf32>
  return
}

// -----

func.func @test_reverse_axis_out_of_range(%arg0 : tensor<13x21x3xf32>) -> () {
  // expected-error@+1 {{'tosa.reverse' op expect input tensor rank (3) to be larger than reverse axis (5)}}
  %0 = tosa.reverse %arg0 {axis = 5 : i32} : (tensor<13x21x3xf32>) -> tensor<?x?x?xi32>
  return
}

// -----

func.func @test_reshape_zero_dim_input(%arg0 : tensor<?x0x3xf32>) -> () {
  %1 = tosa.const_shape {value = dense<[13, 21, 3]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.reshape' op operand #0 must be tosa-conformant tensor of number values, but got 'tensor<?x0x3xf32>'}}
  %0 = "tosa.reshape"(%arg0, %1) : (tensor<?x0x3xf32>, !tosa.shape<3>) -> tensor<13x0x3xf32>
  return
}

// -----

func.func @test_const_attribute_type_mismatch() -> tensor<100x100xf32> {
  // expected-error@+1 {{'tosa.const' op failed to verify that all of {value, output} have same shape}}
  %0 = "tosa.const"() {value = dense<0.000000e+00> : tensor<1x1xf32>} : () -> tensor<100x100xf32>
  return %0 : tensor<100x100xf32>
}

// -----

func.func @test_conv2d_static_zero_dim_input(%arg0: tensor<1x29x0x4xf32>, %arg1: tensor<16x3x3x4xf32>, %arg2: tensor<16xf32>) -> tensor<1x27x27x16xf32> {
  %input_zp = "tosa.const"() <{value = dense<0> : tensor<i32>}> : () -> tensor<i32>
  %weight_zp = "tosa.const"() <{value = dense<0> : tensor<i32>}> : () -> tensor<i32>
  // expected-error@+1 {{'tosa.conv2d' op operand #0 must be 4-d tosa-conformant tensor, but got 'tensor<1x29x0x4xf32>'}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x29x0x4xf32>, tensor<16x3x3x4xf32>, tensor<16xf32>, tensor<i32>, tensor<i32>) -> tensor<1x27x27x16xf32>
  return %0 : tensor<1x27x27x16xf32>
}

// -----

func.func @test_conv2d_zero_dim_input(%arg0: tensor<1x?x0x4xf32>, %arg1: tensor<16x3x3x4xf32>, %arg2: tensor<16xf32>) -> tensor<1x27x27x16xf32> {
  %input_zp = "tosa.const"() <{value = dense<0> : tensor<i32>}> : () -> tensor<i32>
  %weight_zp = "tosa.const"() <{value = dense<0> : tensor<i32>}> : () -> tensor<i32>
  // expected-error@+1 {{'tosa.conv2d' op operand #0 must be 4-d tosa-conformant tensor, but got 'tensor<1x?x0x4xf32>'}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %input_zp, %weight_zp {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>}
           : (tensor<1x?x0x4xf32>, tensor<16x3x3x4xf32>, tensor<16xf32>, tensor<i32>, tensor<i32>) -> tensor<1x27x27x16xf32>
  return %0 : tensor<1x27x27x16xf32>
}


// -----

func.func @test_avg_pool2d_static_zero_dim_input(%arg0: tensor<1x0x7x9xf32>) -> tensor<1x7x7x9xf32> {
  // expected-error@+1 {{'tosa.avg_pool2d' op operand #0 must be 4-d tosa-conformant tensor, but got 'tensor<1x0x7x9xf32>'}}
    %0 = "tosa.avg_pool2d"(%arg0) {acc_type = f32, kernel = array<i64: 2, 2>, pad = array<i64: 0, 1, 0, 1>, stride = array<i64: 1, 1>}
      : (tensor<1x0x7x9xf32>) -> tensor<1x7x7x9xf32>
    return %0 : tensor<1x7x7x9xf32>
}

// -----

func.func @test_avg_pool2d_zero_dim_input(%arg0: tensor<1x0x?x9xf32>) -> tensor<1x7x7x9xf32> {
  // expected-error@+1 {{'tosa.avg_pool2d' op operand #0 must be 4-d tosa-conformant tensor, but got 'tensor<1x0x?x9xf32>'}}
    %0 = "tosa.avg_pool2d"(%arg0) {acc_type = f32, kernel = array<i64: 2, 2>, pad = array<i64: 0, 1, 0, 1>, stride = array<i64: 1, 1>}
      : (tensor<1x0x?x9xf32>) -> tensor<1x7x7x9xf32>
    return %0 : tensor<1x7x7x9xf32>
}

// -----

func.func @test_variable_duplicates(%arg0: tensor<2x4x8xi32>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi32>
  // expected-error@+1 {{'tosa.variable' op name has already been declared}}
  tosa.variable @stored_var : tensor<1x4x8xi32>
  return
}

// -----

func.func @test_variable_read_type(%arg0: tensor<2x4x8xi32>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi32>
  // expected-error@+1 {{'tosa.variable.read' op result type does not equal variable type}}
  %0 = tosa.variable.read @stored_var : tensor<2x4x8xi16>
  return
}

// -----

func.func @test_variable_read_shape(%arg0: tensor<2x4x8xi32>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi32>
  // expected-error@+1 {{'tosa.variable.read' op result type does not equal variable type}}
  %0 = tosa.variable.read @stored_var : tensor<1x4x8xi32>
  return
}

// -----

func.func @test_variable_write_type(%arg0: tensor<2x4x8xi16>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi32>
  // expected-error@+1 {{'tosa.variable.write' op operand type does not equal variable type}}
  tosa.variable.write @stored_var, %arg0 : tensor<2x4x8xi16>
  return
}

// -----

func.func @test_variable_write_shape(%arg0: tensor<1x4x8xi32>) -> () {
  tosa.variable @stored_var = dense<-1> : tensor<2x4x8xi32>
  // expected-error@+1 {{'tosa.variable.write' op operand type does not equal variable type}}
  tosa.variable.write @stored_var, %arg0 : tensor<1x4x8xi32>
  return
}

// -----

func.func @test_slice_invalid_start() {
  %0 = tensor.empty() : tensor<4x31x31xf32>
  %start = tosa.const_shape {value = dense<[1, 1]> : tensor<2xindex>} : () -> !tosa.shape<2>
  %size = tosa.const_shape {value = dense<[1, 1, 1]> : tensor<3xindex>} : () -> !tosa.shape<3>
  // expected-error@+1 {{'tosa.slice' op length of start attribute is not equal rank of input shape}}
  %3 = tosa.slice %0, %start, %size : (tensor<4x31x31xf32>, !tosa.shape<2>, !tosa.shape<3>) -> tensor<*xf32>
  return
}

// -----

func.func @test_slice_invalid_size() {
  %0 = tensor.empty() : tensor<4x31x31xf32>
  %start = tosa.const_shape {value = dense<[1, 1, 1]> : tensor<3xindex>} : () -> !tosa.shape<3>
  %size = tosa.const_shape {value = dense<[1]> : tensor<1xindex>} : () -> !tosa.shape<1>
  // expected-error@+1 {{'tosa.slice' op length of size attribute is not equal rank of input shape}}
  %3 = tosa.slice %0, %start, %size : (tensor<4x31x31xf32>, !tosa.shape<3>, !tosa.shape<1>) -> tensor<*xf32>
  return
}

// -----

func.func @test_tile_invalid_multiples() {
  %0 = tensor.empty() : tensor<4x31x31xf32>
  %cst = tosa.const_shape { value = dense<1> : tensor<1xindex> } : () -> !tosa.shape<1>
  // expected-error@+1 {{'tosa.tile' op expect 'multiples' to have rank 3 but got 1.}}
  %1 = tosa.tile %0, %cst: (tensor<4x31x31xf32>, !tosa.shape<1>) -> tensor<4x31x31xf32>
  return
}

// -----

func.func @test_tile_invalid_multiples_value() {
  %0 = tensor.empty() : tensor<4x31xf32>
  %multiples = tosa.const_shape { value = dense<[2, -2]> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.tile' op expect element of 'multiples' to be positive integer or -1.}}
  %1 = tosa.tile %0, %multiples : (tensor<4x31xf32>, !tosa.shape<2>) -> tensor<4x31xf32>
  return
}

// -----

func.func @test_tile_io_rank_mismatch() {
  %0 = tensor.empty() : tensor<4x31xf32>
  %multiples = tosa.const_shape { value = dense<[2, 2]> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.tile' op expect same input and output tensor rank.}}
  %1 = tosa.tile %0, %multiples : (tensor<4x31xf32>, !tosa.shape<2>) -> tensor<4x31x31xf32>
  return
}

// -----

// CHECK-LABEL: @test_invalid_constant_permutation
func.func @test_invalid_constant_permutation() {
  %0 = tensor.empty() : tensor<3x4x5xi32>
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %2 = tosa.transpose %0 {perms = array<i32: 3, 0, 1>}: (tensor<3x4x5xi32>) -> tensor<3x4x5xi32>
  return
}

// -----

// CHECK-LABEL: test_rank_size_constant_permutation
func.func @test_rank_size_constant_permutation() {
  %0 = arith.constant 6 : index
  %2 = tensor.empty(%0) : tensor<?x27xi64>
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %3 = tosa.transpose %2 {perms = array<i32: 0, 2>}: (tensor<?x27xi64>) -> tensor<?x27xi64>
  return
}

// -----

// CHECK-LABEL: test_large_constant_permutation
func.func @test_large_constant_permutation() {
  %0 = arith.constant 6 : index
  %2 = tensor.empty(%0) : tensor<?x27xi64>
  // expected-error@+1 {{'tosa.transpose' op expected valid permutation indices}}
  %3 = tosa.transpose %2 {perms = array<i32: 1185677355, 332462212>}: (tensor<?x27xi64>) -> tensor<?x27xi64>
  return
}

// -----

// CHECK-LABEL: test_table_rank0_table
func.func @test_table_rank0_table(%arg0: tensor<64xi16>, %arg1: tensor<i16>) {
  // expected-error@+1 {{'tosa.table' op operand #1 must be 1-d tosa-conformant tensor, but got 'tensor<i16>'}}
  %0 = tosa.table %arg0, %arg1 : (tensor<64xi16>, tensor<i16>) -> tensor<64xi16>
  return
}

// -----

// CHECK-LABEL: test_table_io_rank_mismatch
func.func @test_table_io_rank_mismatch(%arg0: tensor<64xi16>, %arg1: tensor<6xi16>) {
  // expected-error@+1 {{'tosa.table' op expected input tensor rank to equal result tensor rank}}
  %0 = tosa.table %arg0, %arg1 : (tensor<64xi16>, tensor<6xi16>) -> tensor<64x?xi16>
  return
}

// -----

// CHECK-LABEL: test_table_io_shape_mismatch
func.func @test_table_io_shape_mismatch(%arg0: tensor<?x16xi16>, %arg1: tensor<6xi16>) {
  // expected-error@+1 {{'tosa.table' op dim(result, 1) = 15 doesn't match dim(input, 1) = 16}}
  %0 = tosa.table %arg0, %arg1 : (tensor<?x16xi16>, tensor<6xi16>) -> tensor<?x15xi16>
  return
}

// -----

// CHECK-LABEL: test_mul_type_mismatch
func.func @test_mul_type_mismatch(%arg0: tensor<13x21x3xf32>, %arg1: tensor<13x1x3xf16>) -> tensor<13x21x3xf32> {
  %shift = "tosa.const"() {value = dense<0> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.mul' op requires the same element type for all operands}}
  %0 = tosa.mul %arg0, %arg1, %shift : (tensor<13x21x3xf32>, tensor<13x1x3xf16>, tensor<1xi8>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----

// CHECK-LABEL: test_mul_invalid_shift
func.func @test_mul_invalid_shift(%arg0: tensor<13x21x3xf32>, %arg1: tensor<13x1x3xf32>) -> tensor<13x21x3xf32> {
  %shift = "tosa.const"() {value = dense<1> : tensor<1xi8>} : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.mul' op require shift to be 0 for float type}}
  %0 = tosa.mul %arg0, %arg1, %shift : (tensor<13x21x3xf32>, tensor<13x1x3xf32>, tensor<1xi8>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----

// CHECK-LABEL: test_mul_missing_shift
func.func @test_mul_missing_shift(%arg0: tensor<13x21x3xi32>, %arg1: tensor<13x1x3xi32>) -> tensor<13x21x3xi32> {
  // expected-error@+1 {{'tosa.mul' op expected 3 operands, but found 2}}
  %0 = tosa.mul %arg0, %arg1 : (tensor<13x21x3xi32>, tensor<13x1x3xi32>) -> tensor<13x21x3xi32>
  return %0 : tensor<13x21x3xi32>
}

// -----

// CHECK-LABEL: test_unsupported_int64_data_type
func.func @test_unsupported_int64_data_type(%arg0: tensor<1x13x13x5xf32>) -> tensor<1x13x13xi64> {
  // expected-error@+1 {{'tosa.argmax' op is not profile-aligned: element type 'i64' is not legal}}
  %0 = tosa.argmax %arg0 {axis = 3 : i32} : (tensor<1x13x13x5xf32>) -> tensor<1x13x13xi64>
  return %0 : tensor<1x13x13xi64>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_clamp
func.func @test_mismatch_in_out_data_type_clamp(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.clamp' op requires the same element type for all operands and results}}
  %0 = tosa.clamp %arg0 {min_val = 0.0 : f32, max_val = 1.0: f32} : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_clamp
func.func @test_mismatch_in_out_shape_clamp(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.clamp' op requires the same shape for all operands and results}}
  %0 = tosa.clamp %arg0 {min_val = 0.0 : f32, max_val = 1.0: f32} : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_erf
func.func @test_mismatch_in_out_data_type_erf(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.erf' op requires the same element type for all operands and results}}
  %0 = tosa.erf %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_erf
func.func @test_mismatch_in_out_shape_erf(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.erf' op requires the same shape for all operands and results}}
  %0 = tosa.erf %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_sigmoid
func.func @test_mismatch_in_out_data_type_sigmoid(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.sigmoid' op requires the same element type for all operands and results}}
  %0 = tosa.sigmoid %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_sigmoid
func.func @test_mismatch_in_out_shape_sigmoid(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.sigmoid' op requires the same shape for all operands and results}}
  %0 = tosa.sigmoid %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_tanh
func.func @test_mismatch_in_out_data_type_tanh(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.tanh' op requires the same element type for all operands and results}}
  %0 = tosa.tanh %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_tanh
func.func @test_mismatch_in_out_shape_tanh(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.tanh' op requires the same shape for all operands and results}}
  %0 = tosa.tanh %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_cos
func.func @test_mismatch_in_out_data_type_cos(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.cos' op requires the same element type for all operands and results}}
  %0 = tosa.cos %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_cos
func.func @test_mismatch_in_out_shape_cos(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.cos' op requires the same shape for all operands and results}}
  %0 = tosa.cos %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_sin
func.func @test_mismatch_in_out_data_type_sin(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.sin' op requires the same element type for all operands and results}}
  %0 = tosa.sin %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_sin
func.func @test_mismatch_in_out_shape_sin(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.sin' op requires the same shape for all operands and results}}
  %0 = tosa.sin %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_abs
func.func @test_mismatch_in_out_data_type_abs(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.abs' op requires the same element type for all operands and results}}
  %0 = tosa.abs %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_abs
func.func @test_mismatch_in_out_shape_abs(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.abs' op requires the same shape for all operands and results}}
  %0 = tosa.abs %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_bitwise_not
func.func @test_mismatch_in_out_data_type_bitwise_not(%arg0: tensor<13x21x1xi32>) -> tensor<13x21x1xi16> {
  // expected-error@+1 {{'tosa.bitwise_not' op requires the same element type for all operands and results}}
  %0 = tosa.bitwise_not %arg0 : (tensor<13x21x1xi32>) -> tensor<13x21x1xi16>
  return %0 : tensor<13x21x1xi16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_bitwise_not
func.func @test_mismatch_in_out_shape_bitwise_not(%arg0: tensor<13x21x1xi32>) -> tensor<13x21x3xi32> {
  // expected-error@+1 {{'tosa.bitwise_not' op requires the same shape for all operands and results}}
  %0 = tosa.bitwise_not %arg0 : (tensor<13x21x1xi32>) -> tensor<13x21x3xi32>
  return %0 : tensor<13x21x3xi32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_ceil
func.func @test_mismatch_in_out_data_type_ceil(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.ceil' op requires the same element type for all operands and results}}
  %0 = tosa.ceil %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_ceil
func.func @test_mismatch_in_out_shape_ceil(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.ceil' op requires the same shape for all operands and results}}
  %0 = tosa.ceil %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_data_type_clz
func.func @test_mismatch_in_out_data_type_clz(%arg0: tensor<13x21x3xi32>) -> tensor<13x21x3xi16> {
  // expected-error@+1 {{'tosa.clz' op requires the same element type for all operands and results}}
  %0 = tosa.clz %arg0 : (tensor<13x21x3xi32>) -> tensor<13x21x3xi16>
  return %0 : tensor<13x21x3xi16>
}

// -----

// CHECK-LABEL: test_mismatch_in_out_shape_clz
func.func @test_mismatch_in_out_shape_clz(%arg0: tensor<13x21x3xi32>) -> tensor<13x21x1xi32> {
  // expected-error@+1 {{'tosa.clz' op requires the same shape for all operands and results}}
  %0 = tosa.clz %arg0 : (tensor<13x21x3xi32>) -> tensor<13x21x1xi32>
  return %0 : tensor<13x21x1xi32>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_data_type_cos
func.func @test_mismatch_in_out_data_type_cos(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.cos' op requires the same element type for all operands and results}}
  %0 = tosa.cos %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_shape_cos
func.func @test_mismatch_in_out_shape_cos(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.cos' op requires the same shape for all operands and results}}
  %0 = tosa.cos %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_data_type_exp
func.func @test_mismatch_in_out_data_type_exp(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.exp' op requires the same element type for all operands and results}}
  %0 = tosa.exp %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_shape_exp
func.func @test_mismatch_in_out_shape_exp(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.exp' op requires the same shape for all operands and results}}
  %0 = tosa.exp %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_data_type_floor
func.func @test_mismatch_in_out_data_type_floor(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.floor' op requires the same element type for all operands and results}}
  %0 = tosa.floor %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_shape_floor
func.func @test_mismatch_in_out_shape_floor(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.floor' op requires the same shape for all operands and results}}
  %0 = tosa.floor %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_data_type_log
func.func @test_mismatch_in_out_data_type_log(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x3xf16> {
  // expected-error@+1 {{'tosa.log' op requires the same element type for all operands and results}}
  %0 = tosa.log %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x3xf16>
  return %0 : tensor<13x21x3xf16>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_shape_log
func.func @test_mismatch_in_out_shape_log(%arg0: tensor<13x21x3xf32>) -> tensor<13x21x1xf32> {
  // expected-error@+1 {{'tosa.log' op requires the same shape for all operands and results}}
  %0 = tosa.log %arg0 : (tensor<13x21x3xf32>) -> tensor<13x21x1xf32>
  return %0 : tensor<13x21x1xf32>
}

// -----
// CHECK-LABEL: test_mismatch_in_out_shape_logical_not
func.func @test_mismatch_in_out_shape_logical_not(%arg0: tensor<1x21x3xi1>) -> tensor<13x21x3xi1> {
  // expected-error@+1 {{'tosa.logical_not' op requires the same shape for all operands and results}}
  %0 = tosa.logical_not %arg0 : (tensor<1x21x3xi1>) -> tensor<13x21x3xi1>
  return %0 : tensor<13x21x3xi1>
}

// -----

// Check validate pass doesn't run on non TOSA ops
func.func @test_non_tosa_ops() {
  %0 = arith.constant 6 : index
  %2 = tensor.empty(%0) : tensor<?x27xi64>
  return
}

// -----

// expected-error@+1 {{invalid rank (must be >= 0): -1}}
func.func @test_shape_type(%arg0: !tosa.shape<-1>) -> !tosa.shape<-1> {
  return %arg0 : !tosa.shape<-1>
}

// -----
func.func @test_const_shape() -> !tosa.shape<4> {
  // expected-error@+1 {{'tosa.const_shape' op attribute 'value' failed to satisfy constraint: index elements attribute}}
  %cst = tosa.const_shape {value = dense<[1, 2, 3, 4]> : tensor<4xi32>} : () -> !tosa.shape<4>
  return %cst : !tosa.shape<4>
}

// -----

func.func @test_const_shape_value() -> !tosa.shape<5> {
  // expected-error@+1 {{'tosa.const_shape' op expect number of elements in attribute value (4) to be equal to the rank (5) for the result shape type}}
  %cst = tosa.const_shape {value = dense<[1, 2, 3, 4]> : tensor<4xindex>} : () -> !tosa.shape<5>
  return %cst : !tosa.shape<5>
}

// -----

func.func @test_const_shape_value() -> !tosa.shape<4> {
  // expected-error@+1 {{'tosa.const_shape' op expect elements in attribute value with rank 1}}
  %cst = tosa.const_shape {value = dense<[[1, 2], [3, 4]]> : tensor<2x2xindex>} : () -> !tosa.shape<4>
  return %cst : !tosa.shape<4>
}

// -----

func.func @test_sub_with_unequal_operand_ranks(%arg0: tensor<1x21x3xf32>, %arg1: tensor<1x13x21x3xf32>) -> tensor<1x13x21x3xf32> {
  // expected-error@+1 {{'tosa.sub' op operands don't have matching ranks}}
  %0 = tosa.sub %arg0, %arg1 : (tensor<1x21x3xf32>, tensor<1x13x21x3xf32>) -> tensor<1x13x21x3xf32>
  return %0 : tensor<1x13x21x3xf32>
}

// -----

func.func @test_sub_with_unequal_result_ranks(%arg0: tensor<1x21x3xf32>, %arg1: tensor<13x21x3xf32>) -> tensor<1x13x21x3xf32> {
  // expected-error@+1 {{'tosa.sub' op result type has different rank than operands}}
  %0 = tosa.sub %arg0, %arg1 : (tensor<1x21x3xf32>, tensor<13x21x3xf32>) -> tensor<1x13x21x3xf32>
  return %0 : tensor<1x13x21x3xf32>
}

// -----
// CHECK-LABEL: test_mul_non_scalar_shift_2d
func.func @test_mul_non_scalar_shift_2d(%arg0: tensor<13x21x3xf32>, %arg1: tensor<13x1x3xf32>) -> tensor<13x21x3xf32> {
  %shift = "tosa.const"() <{value = dense<0> : tensor<1x1xi8>}> : () -> tensor<1x1xi8>
  // expected-error@+1 {{'tosa.mul' op operand #2 must be tosa-conformant scalar tensor of 8-bit signless integer values, but got 'tensor<1x1xi8>'}}
  %0 = tosa.mul %arg0, %arg1, %shift : (tensor<13x21x3xf32>, tensor<13x1x3xf32>, tensor<1x1xi8>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----
// CHECK-LABEL: test_mul_non_scalar_shift_1d
func.func @test_mul_non_scalar_shift_1d(%arg0: tensor<13x21x3xf32>, %arg1: tensor<13x1x3xf32>) -> tensor<13x21x3xf32> {
  %shift = "tosa.const"() <{value = dense<0> : tensor<2xi8>}> : () -> tensor<2xi8>
  // expected-error@+1 {{'tosa.mul' op operand #2 must be tosa-conformant scalar tensor of 8-bit signless integer values, but got 'tensor<2xi8>'}}
  %0 = tosa.mul %arg0, %arg1, %shift : (tensor<13x21x3xf32>, tensor<13x1x3xf32>, tensor<2xi8>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----
// CHECK-LABEL: test_mul_non_broadcast
func.func @test_mul_non_broadcast(%arg0: tensor<13x21x2xf32>, %arg1: tensor<3x1x3xf32>) -> tensor<13x21x3xf32> {
  %shift = "tosa.const"() <{value = dense<0> : tensor<1xi8>}> : () -> tensor<1xi8>
  // expected-error@+1 {{'tosa.mul' op operands don't have broadcast-compatible shapes}}
  %0 = tosa.mul %arg0, %arg1, %shift : (tensor<13x21x2xf32>, tensor<3x1x3xf32>, tensor<1xi8>) -> tensor<13x21x3xf32>
  return %0 : tensor<13x21x3xf32>
}

// -----
// CHECK-LABEL: test_resize_invalid_scale_values
func.func @test_resize_invalid_scale_values(%arg0: tensor<1x8x8x8xf32>) -> tensor<?x?x?x?xf32> {
  %scale = tosa.const_shape { value = dense<[2, 0, -1, 2]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op expect all scale values to be > 0, got 2, 0, -1, 2}}
  %1 = tosa.resize %arg0, %scale, %offset, %border { mode = "BILINEAR" } : (tensor<1x8x8x8xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<?x?x?x?xf32>
  return %1 : tensor<?x?x?x?xf32>
}

// -----

// CHECK-LABEL: test_resize_invalid_wholly_divisible_height
func.func @test_resize_invalid_wholly_divisible_height(%arg0: tensor<1x8x8x8xf32>) -> tensor<1x8x8x8xf32> {
  %scale = tosa.const_shape { value = dense<[1, 3, 1, 1]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op expected (input_height - 1) * scale_y_n - offset_y + border_y to be wholly divisible by scale_y_d, got ((8 - 1) * 1 - 0 + 0) / 3}}
  %1 = tosa.resize %arg0, %scale, %offset, %border { mode = "BILINEAR" } : (tensor<1x8x8x8xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x8x8x8xf32>
  return %1 : tensor<1x8x8x8xf32>
}

// -----

// CHECK-LABEL: test_resize_invalid_output_height
func.func @test_resize_invalid_output_height(%arg0: tensor<1x8x8x8xf32>) -> tensor<1x9x8x8xf32> {
  %scale = tosa.const_shape { value = dense<[2, 1, 1, 1]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op calculated output height did not match expected: calculated=15, expected=9}}
  %1 = tosa.resize %arg0, %scale, %offset, %border { mode = "BILINEAR" } : (tensor<1x8x8x8xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x9x8x8xf32>
  return %1 : tensor<1x9x8x8xf32>
}

// -----

// CHECK-LABEL: test_resize_invalid_wholly_divisible_width
func.func @test_resize_invalid_wholly_divisible_width(%arg0: tensor<1x8x8x8xf32>) -> tensor<1x8x8x8xf32> {
  %scale = tosa.const_shape { value = dense<[1, 1, 1, 3]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op expected (input_width - 1) * scale_x_n - offset_x + border_x to be wholly divisible by scale_x_d, got ((8 - 1) * 1 - 0 + 0) / 3}}
  %1 = tosa.resize %arg0, %scale, %offset, %border { mode = "BILINEAR" } : (tensor<1x8x8x8xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x8x8x8xf32>
  return %1 : tensor<1x8x8x8xf32>
}

// -----

// CHECK-LABEL: test_resize_invalid_output_width
func.func @test_resize_invalid_output_width(%arg0: tensor<1x8x8x8xf32>) -> tensor<1x8x9x8xf32> {
  %scale = tosa.const_shape { value = dense<[1, 1, 2, 1]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op calculated output width did not match expected: calculated=15, expected=9}}
  %1 = tosa.resize %arg0, %scale, %offset, %border { mode = "BILINEAR" } : (tensor<1x8x8x8xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<1x8x9x8xf32>
  return %1 : tensor<1x8x9x8xf32>
}

// -----

// CHECK-LABEL: broadcast_resize_nearest_f32
func.func @broadcast_resize_nearest_f32(%arg0 : tensor<3x1x1x7xf32>) -> tensor<3x1x5x7xf32> {
  %scale = tosa.const_shape { value = dense<[2, 1, 3, 1]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op calculated output width did not match expected: calculated=1, expected=5}}
  %resize = tosa.resize %arg0, %scale, %offset, %border {mode = "NEAREST_NEIGHBOR"} : (tensor<3x1x1x7xf32>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<3x1x5x7xf32>

  return %resize : tensor<3x1x5x7xf32>
}

// -----

// CHECK-LABEL: broadcast_resize_bilinear_i8
func.func @broadcast_resize_bilinear_i8(%arg0 : tensor<3x1x1x7xi8>) -> tensor<3x4x5x7xi32> {
  %scale = tosa.const_shape { value = dense<[2, 1, 3, 1]> : tensor<4xindex> } : () -> !tosa.shape<4>
  %offset = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  %border = tosa.const_shape { value = dense<0> : tensor<2xindex> } : () -> !tosa.shape<2>
  // expected-error@+1 {{'tosa.resize' op calculated output height did not match expected: calculated=1, expected=4}}
  %resize = tosa.resize %arg0, %scale, %offset, %border {mode = "BILINEAR"} : (tensor<3x1x1x7xi8>, !tosa.shape<4>, !tosa.shape<2>, !tosa.shape<2>) -> tensor<3x4x5x7xi32>

  return %resize : tensor<3x4x5x7xi32>
}

// -----

func.func @test_conv2d_invalid_padding(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op expect all padding values to be >= 0, got 0, 0, -1, 0}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, -1, 0>, stride = array<i64: 1, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}

// -----

func.func @test_conv2d_invalid_stride(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op expect all stride values to be >= 1, got 0, 1}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 0, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}

// -----

func.func @test_conv2d_invalid_dilation(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op expect all dilation values to be >= 1, got 1, 0}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 0>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}

// -----

func.func @test_conv2d_wholly_divisible_height(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op expected input_height - 1 + pad_top + pad_bottom - (kernel_height - 1) * dilation_y to be wholly divisible by stride_y, got (4 - 1 + 0 + 0 - (1 - 1) * 1) / 2}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 2, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}

// -----

func.func @test_conv2d_wholly_divisible_width(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op expected input_width - 1 + pad_left + pad_right - (kernel_width - 1) * dilation_x to be wholly divisible by stride_x, got (4 - 1 + 0 + 0 - (1 - 1) * 1) / 2}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 2>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}

// -----

func.func @test_conv2d_unexpected_output_height(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x6x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op calculated output height did not match expected: calculated=4, expected=6}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x6x4x8xf32>
  return %0 : tensor<1x6x4x8xf32>
}

// -----

func.func @test_conv2d_unexpected_output_width(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<8xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x6x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op calculated output width did not match expected: calculated=4, expected=6}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<8xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x6x8xf32>
  return %0 : tensor<1x4x6x8xf32>
}

// -----

func.func @test_conv2d_invalid_bias_size(%arg0: tensor<1x4x4x4xf32>, %arg1: tensor<8x1x1x4xf32>, %arg2: tensor<7xf32>, %arg3: tensor<1xf32>, %arg4: tensor<1xf32>) -> tensor<1x4x4x8xf32> {
  // expected-error@+1 {{'tosa.conv2d' op bias channels expected to be equal to output channels (8) or 1, got 7}}
  %0 = tosa.conv2d %arg0, %arg1, %arg2, %arg3, %arg4 {acc_type = f32, dilation = array<i64: 1, 1>, pad = array<i64: 0, 0, 0, 0>, stride = array<i64: 1, 1>, local_bound = true}
    : (tensor<1x4x4x4xf32>, tensor<8x1x1x4xf32>, tensor<7xf32>, tensor<1xf32>, tensor<1xf32>) -> tensor<1x4x4x8xf32>
  return %0 : tensor<1x4x4x8xf32>
}
