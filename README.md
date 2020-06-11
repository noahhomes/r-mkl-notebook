# r-mkl-notebook
jupyter/r-notebook with mkl acceleration

## Overview

This image aims to take the base `jupyter/r-notebook` image and augment it with various enhancements including:

* mkl acceleration for R
* mkl acceleration for python numpy
* ability to mount GCS storage via fuse

## Quickstart:

__Method 1__: Using the Makefile

After cloning the repo, you can make use of the following directives:

* `make up` -- start the notebook
* `make down` -- stop the notebook
* `make pull` -- pull the latest version of the image (try this first if you're having any issues)
* `make bash` -- exec a bash shell inside an already running notebook container

__Method 2__: Using docker directly

Or run the image directly:

```
$ docker run -p 8888:8888 noahhomes/r-mkl-notebook
```

## Using GCS Storage

See the following config fragment for the helm jupyterhub/jupyterhub chart to mount GCS storage:

```
hub:
  extraConfig: |
    from kubernetes import client
    def modify_pod_hook(spawner, pod):
        pod.spec.containers[0].security_context = client.V1SecurityContext(
            privileged=True,
            capabilities=client.V1Capabilities(
                add=['SYS_ADMIN']
            )
        )
        return pod
    c.KubeSpawner.modify_pod_hook = modify_pod_hook
singleuser:
  # needed for mounting /dev/fuse inside the notebook container
  uid: 0
  gid: 0
  # This service account needs to be created and given access to the GCS bucket
  serviceAccountName: your-jupyter-sa
  extraEnv:
    GRANT_SUDO: "yes"
    JUPYTER_ENABLE_LAB: "yes"
  profileList:
    - display_name: "R Notebook"
      description: "Python & R with MKL acceleration"
      kubespawner_override:
        image: noahhomes/r-mkl-notebook
        cmd: ["start.sh", "start-singleuser.sh", "--allow-root"]
  lifecycleHooks:
    postStart:
      exec:
        command: ["mount-gcsfuse.sh", "your-data-bucket"]
    preStop:
      exec:
        command: ["fusermount", "-u", "/home/jovyan/your-data-bucket"]
  storage:
    extraVolumes:
      - name: fuse
        hostPath:
          path: /dev/fuse
    extraVolumeMounts:
      - name: fuse
        mountPath: /dev/fuse
```