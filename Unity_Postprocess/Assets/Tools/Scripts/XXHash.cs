

namespace Klak.Tools
{
	/// xxHash algorithm
	public struct XXHash
	{
		const uint PRIME32_1 = 2654435761U;
		const uint PRIME32_2 = 2246822519U;
		const uint PRIME32_3 = 3266489917U;
		const uint PRIME32_4 = 668265263U;
		const uint PRIME32_5 = 374761393U;

		static uint rotl32(uint x, int r) => (x << r) | (x >> 32 - r);

		public static uint GetHash(int data, int seed)
		{
			uint h32 = (uint)seed + PRIME32_5;
			h32 += 4U;
			h32 += (uint)data * PRIME32_3;
			h32 = rotl32(h32, 17) * PRIME32_4;
			h32 ^= h32 >> 15;
			h32 *= PRIME32_2;
			h32 ^= h32 >> 13;
			h32 *= PRIME32_3;
			h32 ^= h32 >> 16;
			return h32;
		}


		static int _counter;

		public int seed;

		public static XXHash RandomHash => new XXHash((int)XXHash.GetHash(0xcafe, _counter++));

		public uint GetHash(int data) => GetHash(data, seed);

		public int Range(int max, int data) => (int)GetHash(data) % max;

		public int Range(int min, int max, int data) => (int)GetHash(data) % (max - min) + min;

		public float Value01(int data) => GetHash(data) / (float)uint.MaxValue;

		public float Range(float min, float max, int data) => Value01(data) * (max - min) + min;

		/// <summary>
		/// Constructor
		/// </summary>
		/// <param name="seed"></param>
		public XXHash(int seed)
		{
			this.seed = seed;
		}

	}
}
