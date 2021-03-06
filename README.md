# Forti WIFI api

El siguiente servicio ofrece una API para crear usuarios en la aplicación de Forti
realizando un POST logueandose como un usuario con privilegios que creará un
nuevo usuario guest con acceso al WI_FI

## Cómo instalar el servicio

* Instalar ruby 2.x: para ello se aconseja emplear [rbenv +
  ruby-build](https://github.com/rbenv/ruby-build)
  * Una vez completada la instalación de rbenv y ruby-build correr `rbenv
    install 2.3.0` 
* Instalar la gema **bundler** `gem install bundler`
* En este mismo proyecto, correr `bundle install`
* Instanciar el servicio: `bundle exec puma -b tcp://0.0.0.0:8080` para iniciar
  el servicio en el puerto 8080

### Configuración

La configuración del servicio se realiza con el archivo `config/app.yml`. Este
archivo **no se versiona** por lo que puede crear este archivo a partir de
`config/app.yml-sample`


## Servicios ofrecidos

La API provee los siguientes endpoints:

* **POST /get_guest_user**: debe enviar un argumento **name**: 
  Ejemplo curl: `curl -X POST http://localhost:8080/get_guest_user -d 'name=some_name'`

## Dando de alta el servicio con systemd

Inicialmente se recomienda correr bundle de la siguiente forma:

```bash
bundle binstubs puma --path ./sbin
```
*Esto creará el directorio ./sbin localente donde se pondrá el ejecutable de
puma*

Agregar el archivo `/etc/systemd/system/forti-wifi.service` con el siguiente
contenido

```ini
[Unit]
Description=Forti Wifi API
After=network.target

[Service]
Type=simple
User=forti-wifi
WorkingDirectory=/home/app/api
ExecStart=/bin/bash -lc '/home/app/api/sbin/puma -b tcp://0.0.0.0:8080'
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target

```
