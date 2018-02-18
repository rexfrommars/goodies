Goodies for the deployment of Celery in AWS Ealstic Beanstalk envronment
========================================================================

* make sure to install the package libcurl-devel:
    ```
    packages:
      yum:
        libcurl-devel: []  # => curl-config => pycurl
    ```

* make sure this line is included in _requirements_:
	```
	pycurl==7.43.0.1 --global-option="--with-nss"
	```
