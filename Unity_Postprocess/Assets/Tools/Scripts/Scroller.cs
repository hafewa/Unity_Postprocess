using UnityEngine;

namespace Motion.Tools
{
	public class Scroller : MonoBehaviour
	{
		[SerializeField] float speed = 1;
		[SerializeField] float wrapPoint = 10;

		float position;

		private void Start()
		{
			position = Vector3.Dot(transform.position, transform.forward);
		}

		private void Update()
		{
			position += Time.deltaTime * speed;

			if (position > wrapPoint)
			{
				position -= wrapPoint * 2;
			}
			transform.position = transform.forward * position;
		}
	}
}

