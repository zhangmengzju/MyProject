/******************************************************************************
 * 
 * Copyright 2010-2012 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 * 
 ******************************************************************************/

/******************************************************************************
 * Kernel utilities for initializing 2D arrays (tiles)
 ******************************************************************************/

#pragma once

namespace b40c {
namespace util {
namespace io {


/**
 * Initialize a tile of items
 */
template <
	int LOG_LOADS_PER_TILE,
	int LOG_LOAD_VEC_SIZE,
	int ACTIVE_THREADS>
struct InitializeTile
{
	enum {
		LOADS_PER_TILE 				= 1 << LOG_LOADS_PER_TILE,
		LOAD_VEC_SIZE 				= 1 << LOG_LOAD_VEC_SIZE,
		LOG_ELEMENTS_PER_THREAD		= LOG_LOADS_PER_TILE + LOG_LOAD_VEC_SIZE,
		ELEMENTS_PER_THREAD			= 1 << LOG_ELEMENTS_PER_THREAD,
		TILE_SIZE 					= ACTIVE_THREADS * ELEMENTS_PER_THREAD,
	};

	//---------------------------------------------------------------------
	// Helper Structures
	//---------------------------------------------------------------------

	// Iterate over vec-elements
	template <int LOAD, int VEC>
	struct Iterate
	{
		template <typename T, typename S>
		static __device__ __forceinline__ void Copy(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE])
		{
			target[LOAD][VEC] = source[LOAD][VEC];
			Iterate<LOAD, VEC + 1>::Copy(target, source);
		}

		template <typename T, typename S>
		static __device__ __forceinline__ void Init(
			T target[][LOAD_VEC_SIZE],
			S datum)
		{
			target[LOAD][VEC] = datum;
			Iterate<LOAD, VEC + 1>::Init(target, datum);
		}

		template <typename T, typename S, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op)
		{
			target[LOAD][VEC] = transform_op(source[LOAD][VEC]);
			Iterate<LOAD, VEC + 1>::Transform(target, source, transform_op);
		}

		template <typename T, typename S, typename TransformOp, typename SizeT>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op,
			const SizeT &guarded_elements,
			T oob_default)
		{
			SizeT thread_offset = (threadIdx.x << LOG_LOAD_VEC_SIZE) + (LOAD * ACTIVE_THREADS * LOAD_VEC_SIZE) + VEC;

			target[LOAD][VEC] = (thread_offset < guarded_elements) ?
				transform_op(source[LOAD][VEC]) :
				oob_default;

			Iterate<LOAD, VEC + 1>::Transform(
				target,
				source,
				transform_op,
				guarded_elements,
				oob_default);
		}

		template <typename SoaT, typename SoaS, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			SoaT target_soa,
			SoaS source_soa,
			TransformOp transform_op)
		{
			SoaS source;
			source_soa.Get(source, LOAD, VEC);
			SoaT target = transform_op(source);
			target_soa.Set(target, LOAD, VEC);
			Iterate<LOAD, VEC + 1>::Transform(target, source, transform_op);
		}
	};

	// Iterate over loads
	template <int LOAD>
	struct Iterate<LOAD, LOAD_VEC_SIZE>
	{
		template <typename T, typename S>
		static __device__ __forceinline__ void Copy(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE])
		{
			Iterate<LOAD + 1, 0>::Copy(target, source);
		}

		template <typename T, typename S>
		static __device__ __forceinline__ void Init(
			T target[][LOAD_VEC_SIZE],
			S datum)
		{
			Iterate<LOAD + 1, 0>::Init(target, datum);
		}

		template <typename T, typename S, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op)
		{
			Iterate<LOAD + 1, 0>::Transform(target, source, transform_op);
		}

		template <typename T, typename S, typename TransformOp, typename SizeT>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op,
			const SizeT &guarded_elements,
			T oob_default)
		{
			Iterate<LOAD + 1, 0>::Transform(target, source, transform_op, guarded_elements, oob_default);
		}

		template <typename SoaT, typename SoaS, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			SoaT target_soa,
			SoaS source_soa,
			TransformOp transform_op)
		{
			Iterate<LOAD + 1, 0>::Transform(target_soa, source_soa, transform_op);
		}
	};

	// Terminate
	template <int VEC>
	struct Iterate<LOADS_PER_TILE, VEC>
	{
		template <typename T, typename S>
		static __device__ __forceinline__ void Copy(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE]) {}

		template <typename T, typename S>
		static __device__ __forceinline__ void Init(
			T target[][LOAD_VEC_SIZE],
			S datum) {}

		template <typename T, typename S, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op) {}

		template <typename T, typename S, typename TransformOp, typename SizeT>
		static __device__ __forceinline__ void Transform(
			T target[][LOAD_VEC_SIZE],
			S source[][LOAD_VEC_SIZE],
			TransformOp transform_op,
			const SizeT &guarded_elements,
			T oob_default) {}

		template <typename SoaT, typename SoaS, typename TransformOp>
		static __device__ __forceinline__ void Transform(
			SoaT target_soa,
			SoaS source_soa,
			TransformOp transform_op) {}
	};


	//---------------------------------------------------------------------
	// Interface
	//---------------------------------------------------------------------

	/**
	 * Copy source to target
	 */
	template <typename T, typename S>
	static __device__ __forceinline__ void Copy(
		T target[][LOAD_VEC_SIZE],
		S source[][LOAD_VEC_SIZE])
	{
		Iterate<0, 0>::Copy(target, source);
	}


	/**
	 * Initialize target with datum
	 */
	template <typename T, typename S>
	static __device__ __forceinline__ void Init(
		T target[][LOAD_VEC_SIZE],
		S datum)
	{
		Iterate<0, 0>::Init(target, datum);
	}


	/**
	 * Apply unary transform_op operator to source
	 */
	template <typename T, typename S, typename TransformOp>
	static __device__ __forceinline__ void Transform(
		T target[][LOAD_VEC_SIZE],
		S source[][LOAD_VEC_SIZE],
		TransformOp transform_op)
	{
		Iterate<0, 0>::Transform(target, source, transform_op);
	}

	/**
	 * Apply unary transform_op operator to source (guarded)
	 */
	template <typename T, typename S, typename TransformOp, typename SizeT>
	static __device__ __forceinline__ void Transform(
		T target[][LOAD_VEC_SIZE],
		S source[][LOAD_VEC_SIZE],
		TransformOp transform_op,
		const SizeT &guarded_elements,
		T oob_default)
	{
		if (guarded_elements >= TILE_SIZE) {

			// unguarded
			Transform(target, source, transform_op);

		} else {

			// guarded
			Iterate<0, 0>::Transform(
				target,
				source,
				transform_op,
				guarded_elements,
				oob_default);
		}
	}

	/**
	 * Apply structure-of-array transform_op operator to source
	 */
	template <typename SoaT, typename SoaS, typename TransformOp>
	static __device__ __forceinline__ void Transform(
		SoaT target_soa,
		SoaS source_soa,
		TransformOp transform_op)
	{
		Iterate<0, 0>::Transform(target_soa, source_soa, transform_op);
	}
};


} // namespace io
} // namespace util
} // namespace b40c

