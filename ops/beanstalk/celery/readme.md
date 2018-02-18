Goodies for the deployment of Celery in Ealstic Beanstalk
========================================================================

MAKE SURE THAT
--------------

* install the package _libcurl-devel_:
    ```
    packages:
      yum:
        libcurl-devel: []  # => curl-config => pycurl
    ```

* incude this line in _requirements.txt_:
	```
	pycurl==7.43.0.1 --global-option="--with-nss"
	```
