
RopePanel (Godot 4) — Cómo usar

1) Copia estos ficheros a tu proyecto (sugiero res://scenes/ui/):
   - panel_center.png
   - rope_corner.png
   - rope_side_h.png
   - rope_side_v.png
   - RopePanel.tscn
   - RopePanel.gd

2) En el Import de Godot para rope_side_h.png y rope_side_v.png:
   - Repeat = Enabled
   - Filter = On (si no es pixel art)
   - Mipmaps = On

3) Abre RopePanel.tscn:
   - El script ajusta posiciones y tamaños al redimensionar.
   - Ajusta @export var border_thickness si ves descuadre (valor actual ≈ 80px).

4) CenterFill (NinePatchRect):
   - Usa panel_center.png con patch margins recomendadas:
     left/top/right/bottom = 16/16/16/16
   - Puedes cambiar STRETCH por TILE/TILE_FIT si quieres patrón repetido.

5) Composición final:
   - Esquinas no se estiran (TextureRect).
   - Laterales se repiten con TILE (TextureRect).
   - Centro se estira con 9-slice (NinePatchRect).

Así evitas la deformación de la cuerda y puedes escalar el panel a cualquier tamaño.
