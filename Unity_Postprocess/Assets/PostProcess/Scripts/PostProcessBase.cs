using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace PostProcess
{
	public abstract class PostProcessBase : MonoBehaviour
	{
		protected Material material;

		protected virtual void OnDestroy()
		{
			if (material)
			{
				DestroyImmediate(material);
			}
		}

	}


}

