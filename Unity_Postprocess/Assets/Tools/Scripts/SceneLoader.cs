using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Motion.Tools
{
    public class SceneLoader : MonoBehaviour
    {
        PostProcess.FXAA fxaa = default;

        public PostProcess.FXAA FXAA => fxaa;


        void Start()
        {
            fxaa = GetComponent<PostProcess.FXAA>() ?? gameObject.AddComponent<PostProcess.FXAA>();

            SceneSwicher.Instance.Initialize();

            if (fxaa)
            {
                SceneSwicher.Instance.UpdateFXAA(fxaa.enabled);
            }

        }

    }

}

