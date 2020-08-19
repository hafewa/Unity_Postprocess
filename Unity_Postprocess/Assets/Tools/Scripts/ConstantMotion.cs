using UnityEngine;

namespace Motion.Tools
{
	public class ConstantMotion : MonoBehaviour
	{

		public enum TranslationMode
		{
			Off,
			XAxis,
			YAxis,
			ZAxis,
			Vector,
			Random
		};

		public enum RotationMode
		{
			Off,
			XAxis,
			YAxis,
			ZAxis,
			Vector,
			Random
		}

		public TranslationMode translationMode { get => _translationMode; set => _translationMode = value; }

		public Vector3 translationVector { get => _translationVector; set => _translationVector = value; }

		public float translationSpeed { get => _translationSpeed; set => _translationSpeed = value; }

		public RotationMode rotationMode { get => _rotationMode; set => _rotationMode = value; }

		public Vector3 rotationAxis { get => _rotationAxis; set => _rotationAxis = value; }

		public float rotationSpeed { get => _rotationSpeed; set => _rotationSpeed = value; }

		public bool useLocalCoordinate { get => _useLocalCoordinate; set => _useLocalCoordinate = value; }

		[SerializeField]
		private TranslationMode _translationMode = TranslationMode.Off;

		[SerializeField]
		private Vector3 _translationVector = Vector3.forward;

		[SerializeField]
		private float _translationSpeed = 1.0f;

		[SerializeField]
		private RotationMode _rotationMode = RotationMode.Off;

		[SerializeField]
		private Vector3 _rotationAxis = Vector3.up;

		[SerializeField]
		private float _rotationSpeed = 30.0f;

		[SerializeField]
		private bool _useLocalCoordinate = true;

		Vector3 _randomVectorT;
		Vector3 _randomVectorR;

		Vector3 TranslationVector
		{
			get
			{
				switch (_translationMode)
				{
					case TranslationMode.XAxis: return Vector3.right;
					case TranslationMode.YAxis: return Vector3.up;
					case TranslationMode.ZAxis: return Vector3.forward;
					case TranslationMode.Vector: return _translationVector;
				}
				// TranslationMode.Random
				return _randomVectorT;
			}
		}

		Vector3 RotationVector
		{
			get
			{
				switch (_rotationMode)
				{
					case RotationMode.XAxis: return Vector3.right;
					case RotationMode.YAxis: return Vector3.up;
					case RotationMode.ZAxis: return Vector3.forward;
					case RotationMode.Vector: return _rotationAxis;
				}
				// RotationMode.Random
				return _randomVectorR;
			}
		}


		private void Start()
		{
			_randomVectorT = Random.onUnitSphere;
			_randomVectorR = Random.onUnitSphere;
		}

		private void Update()
		{
			var dt = Time.deltaTime;

			if (_translationMode != TranslationMode.Off)
			{
				var dp = TranslationVector * _translationSpeed * dt;

				if (_useLocalCoordinate)
				{
					transform.localPosition += dp;
				}
				else
				{
					transform.position += dp;
				}
			}

			if (_rotationMode != RotationMode.Off)
			{
				var dr = Quaternion.AngleAxis(_rotationSpeed * dt, RotationVector);

				if (_useLocalCoordinate)
				{
					transform.localRotation = dr * transform.localRotation;
				}
				else
				{
					transform.rotation = dr * transform.rotation;
				}
			}
		}

	}
}
