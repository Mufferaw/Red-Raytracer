# Red-Raytracer

This is a very basic ray tracer written as an exercise to learn about Red.
The main part of the ray tracer is written in Red/System, the interface and 
scene parsing are written in Red.

![picture alt](https://github.com/Mufferaw/Red-Raytracer/blob/master/screenshot.jpg)

## Usage:

The camera's position and target can be set by changing the values in their respective fields.

_Samples:_  This is the number of anti-aliasing samples, increasing this number will improve the final 
image quality but will also increase rendering time.

_Depth:_  This is the maximum number of reflective bounces when using the 'Metal' material

_Scene:_ The text area at the bottom allows us to define the scene to be drawn. Currently, the only 
object available is the sphere. Also, we may choose between two material types, Metal (reflective) and
Lambert (Matte).

The syntax for describing the scene is very simple:

`NameofSphere sphere radius 0.5 position 0.0 0.0 -1.0 metal 0.6 0.2 0.2 0.2`

`AnotherSphere sphere radius 0.5 position 1.0 0.0 -1.0 lambert 0.2 0.2 0.4 0.0`

`BigSphere sphere radius 100.0 position 0.0 -100.5 -1.0 lambert 0.7 0.7 0.7 0.0`

The last argument for the Metal material is the amount of blur in the reflections, the Lambert material
does not use the last argument (but it is still needed)



