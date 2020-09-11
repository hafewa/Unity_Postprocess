using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Motion.Tools
{
    public class SceneLoader : MonoBehaviour
    {
		[SerializeField]
        PostProcess.FXAA fxaa = default;

        public PostProcess.FXAA FXAA => fxaa;


        void Start()
        {
			SceneSwicher.Instance.Initialize();

            if (fxaa)
            {
                SceneSwicher.Instance.UpdateFXAA(fxaa.enabled);
            }

        }

    }

}

