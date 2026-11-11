# Guía rápida para colaborar en el código

Esta guía es para quien se suma a trabajar en el código de la app de Ingemax. Todo lo que se sube a la rama `main` se publica **al instante** en la app que usa todo el equipo (GitHub Pages), así que hay que ir con cuidado: cambios chicos, de a uno, y probados.

## Una sola vez: preparar la compu

1. Crear una cuenta gratis en github.com y pasarle el usuario a Fran. Te llega una invitación al repo por mail: aceptala.
2. Instalar [Git](https://git-scm.com/downloads) y Claude Code.
3. Clonar el repo y abrir esa carpeta con Claude Code:

```bash
git clone https://github.com/ingemaxtallerfran/Planillas-Amarillas.git
```

4. Decirle a Git quién sos (cambiá los datos por los tuyos):

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-mail@ejemplo.com"
```

El archivo `CLAUDE.md` del proyecto ya le explica a tu Claude cómo funciona la app. No hace falta que se lo cuentes.

## Cada vez que hagas un cambio

**1. Traer lo último** (por si Fran u otra persona subió algo):

```bash
git pull
```

**2. Hacer el cambio con Claude Code.** Pedile algo concreto y chico. Antes de aceptar sus cambios, pedile que te explique qué tocó.

**3. Probarlo.** Los archivos son páginas web simples: se abren con doble clic en el navegador. Ojo: **la app de prueba escribe en las planillas reales**. Para mirar sin riesgo abrila con `?modo=lectura` al final de la dirección. Si el cambio es de algo que guarda datos, avisale a Fran antes de probar guardando.

**4. Subirlo:**

```bash
git add .
git commit -m "Describí en una frase qué cambiaste"
git push
```

Si el `git push` dice que fue rechazado, es porque alguien subió algo en el medio. Corré `git pull` y volvé a hacer `git push`.

En un minuto o dos el cambio ya está publicado. Abrí la app y verificá que ande.

## Reglas

- Si tu cambio toca alguna página `.html` o `manifest.json`, hay que subir el número de versión en `sw.js` (la línea `const CACHE = "ingemax-vN"`). Si no, los usuarios siguen viendo la versión vieja. Tu Claude ya lo sabe, pero verificá que lo haya hecho.
- **No tocar** la dirección del Apps Script (`const URL_ = "https://script.google.com/..."`) en ningún archivo.
- **No pegar nunca** claves, tokens ni contraseñas en el código ni en los mensajes de commit.
- Respetar el estilo: naranja de la marca, tipografías Barlow y Barlow Condensed, y el tema claro/oscuro que ya existe.
- Cambios chicos y de a uno, así es fácil ver qué se rompió si algo falla.
- El backend (Apps Script) no está en este repo y no se toca desde acá. Si un cambio necesita backend, pedíselo a Fran.

## Si algo se rompe: volver atrás

Git guarda todo, así que siempre se puede deshacer. Mirá el último cambio con `git log --oneline` y revertilo:

```bash
git revert HEAD
git push
```

Eso crea un cambio nuevo que deshace el anterior, sin borrar historia. También se puede hacer desde GitHub: entrar al commit y tocar **Revert**. Si no sabés cuál es el cambio que rompió algo, no sigas probando: avisale a Fran.
