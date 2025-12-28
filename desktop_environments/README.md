Estos ficheros sirven para crear un entorno de escritorio listo para grabar,
situando aplicaciones en sus lugares correctos y permitiendo que con un
unico click se despliegue todo a una.

Paso 1: Copiar el script a un lugar concreto con acceso.

Paso 2 (Opcional) Copiar el fichero *.desktop a ~/.local/share/applications
y añadirlño a una barra de tareas para que con un click se lance
correctamente. 

Ej:
[Desktop Entry]
Name=Shell Exerc. environment
Comment=Abrir entorno de ejercicios de la shell
Exec=/home/sec2john/.../bash_exercises_env
Icon=utilities-x-terminal
Terminal=true
Type=Application

*.desktop debe tener permisos de ejecución

Paso3: (Ubuntu based distros) Buscar el nombre en el buscador de programas "Show applications" -> Añadir a favoritos
