
using UnityEngine;

namespace Motion.Tools
{
	/// Noise generator that provides Vector3/Quaternion values
	struct NoiseGenerator
	{
		const float _fbmNorm = 1 / 0.75f;

		XXHash _hash1;
		XXHash _hash2;
		XXHash _hash3;

		int _fractal;
		float _frequency;
		float _time;


		public NoiseGenerator(float frequency)
		{
			_hash1 = XXHash.RandomHash;
			_hash2 = XXHash.RandomHash;
			_hash3 = XXHash.RandomHash;
			_fractal = 2;
			_frequency = frequency;
			_time = 0;
		}

		public NoiseGenerator(int seed, float frequency)
		{
			_hash1 = new XXHash(seed);
			_hash2 = new XXHash(seed ^ 0x1327495a);
			_hash3 = new XXHash(seed ^ 0x3cbe84f2);
			_fractal = 2;
			_frequency = frequency;
			_time = 0;
		}

		public int FractalLevel
		{
			get { return _fractal; }
			set { _fractal = value; }
		}

		public float Frequency
		{
			get { return _frequency; }
			set { _frequency = value; }
		}

		public void Step()
		{
			_time += _frequency * Time.deltaTime;
		}

		public float Value01(int seed2)
		{
			var i1 = _hash1.Range(-100.0f, 100.0f, seed2);
			return Perlin.Fbm(_time + i1, _fractal) * _fbmNorm * 0.5f + 0.5f;
		}

		public float Value(int seed2)
		{
			var i1 = _hash1.Range(-100.0f, 100.0f, seed2);
			return Perlin.Fbm(_time + i1, _fractal) * _fbmNorm;
		}

		public Vector3 Vector(int seed2)
		{
			var i1 = _hash1.Range(-100.0f, 100.0f, seed2);
			var i2 = _hash2.Range(-100.0f, 100.0f, seed2);
			var i3 = _hash3.Range(-100.0f, 100.0f, seed2);
			return new Vector3(
				Perlin.Fbm(_time + i1, _fractal) * _fbmNorm,
				Perlin.Fbm(_time + i2, _fractal) * _fbmNorm,
				Perlin.Fbm(_time + i3, _fractal) * _fbmNorm);
		}

		public Quaternion Rotation(int seed2, float angle)
		{
			var i1 = _hash1.Range(-100.0f, 100.0f, seed2);
			var i2 = _hash2.Range(-100.0f, 100.0f, seed2);
			var i3 = _hash3.Range(-100.0f, 100.0f, seed2);
			return Quaternion.Euler(
				Perlin.Fbm(_time + i1, _fractal) * _fbmNorm * angle,
				Perlin.Fbm(_time + i2, _fractal) * _fbmNorm * angle,
				Perlin.Fbm(_time + i3, _fractal) * _fbmNorm * angle);
		}

		public Quaternion Rotation(int seed2, float rx, float ry, float rz)
		{
			var i1 = _hash1.Range(-100.0f, 100.0f, seed2);
			var i2 = _hash2.Range(-100.0f, 100.0f, seed2);
			var i3 = _hash3.Range(-100.0f, 100.0f, seed2);
			return Quaternion.Euler(
				Perlin.Fbm(_time + i1, _fractal) * _fbmNorm * rx,
				Perlin.Fbm(_time + i2, _fractal) * _fbmNorm * ry,
				Perlin.Fbm(_time + i3, _fractal) * _fbmNorm * rz);
		}

	}
}
