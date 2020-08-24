using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Motion.Tools
{
    public class SceneLoader : MonoBehaviour
    {

        void Start()
        {
            SceneSwicher.Instance.Initialize();
        }

    }

}

