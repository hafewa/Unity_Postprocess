using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

namespace Motion.Tools
{
	public abstract class SingletonMonoBehaviour<T> : MonoBehaviour where T : MonoBehaviour
	{
		private static readonly string RESOURCES_PATH = "Prefabs/";

		private static T instance;
		public static T Instance
		{
			get
			{
				if (instance == null)
				{
					Type t = typeof(T);
					T instance = GameObject.FindObjectOfType(t) as T;

					if (instance == null)
					{
						string typeName = t.ToString();

						try
						{
							GameObject gameObject = Instantiate(Resources.Load(RESOURCES_PATH + t.Name)) as GameObject;
							instance = gameObject.GetComponent<T>();
							gameObject.name = t.Name;
						}
						catch (ArgumentException e)
						{
							Debug.LogError("Problem during the creation of " + typeName);
						}
					}
					DontDestroyOnLoad(instance);
				}

				return instance;
			}
		}

		protected virtual void Awake()
		{
			CheckInstance();
		}

		public virtual void Initialize()
		{
			Application.targetFrameRate = 60;
			QualitySettings.vSyncCount = 0;
		}

		protected bool CheckInstance()
		{
			if (instance == null)
			{
				instance = this as T;
				return true;
			}
			else if (Instance == this)
			{
				return true;
			}
			Destroy(this);
			return false;
		}
	}

}

