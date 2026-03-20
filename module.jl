using Javis
using Animations
using ForwardDiff
using LaTeXStrings

const AZUL      = "#001489"
const VERDE     = "#00b140"
const ROJO      = "#DA291C"
const NARANJA   = "#EA7600"

const W_WIDTH, W_HEIGHT     = 1800, 750
const FRAMES, FPS           = 120, 30
const ESCALA_X, ESCALA_Y    = 500, -100

to_screen(x, y) = Point(x * ESCALA_X, y * ESCALA_Y)
to_screen(x, f::Function) = Point(x * ESCALA_X, f(x) * ESCALA_Y)

function ground(args...)
    sethue("white")
    box(BoundingBox(), :fill)
end

function titulo(args...; titulo = "título")
    sethue(AZUL)
    fontsize(160)
    fontface("Lux Sans Black")
    text(titulo; valign = :middle, halign = :center)
end

function autor(args...)
    sethue(AZUL)
    fontsize(30)
    fontface("Lux Sans Black")
    text("Prof. Jonatán Perren"; valign = :baseline, halign = :right)
end

function ejes(args...; n_axis = 1)
    xmin, xmax = -1.6, 1.6
    ymin, ymax = -1, 3.5
    offsetx, offsety = 0.08, 0.4
    
    setcolor(sethue("black")..., 0.1)
    map(x -> line(to_screen(x, ymin + offsety), to_screen(x, ymax - offsety), :stroke), -1.5:0.1:1.5)
    map(y -> line(to_screen(xmin + offsetx, y), to_screen(xmax - offsetx, y), :stroke), -0.5:0.5:3)
    
    if n_axis == 1
        setcolor(sethue("black")..., 1)
        map(t -> arrow(O, to_screen(t...); arrowheadlength = 20), [(-1.6, 0),  (1.6, 0), (0, -1), (0, ymax)])
    elseif n_axis == 2
        setcolor(sethue("black")..., 1)
        translate(to_screen(0.1,0))
        map(t -> arrow(O, to_screen(t...); arrowheadlength = 20), [(0, -1), (0, ymax), (1.4, 0)])
        origin(); translate(to_screen(-1.5,0))
        map(t -> arrow(O, to_screen(t...); arrowheadlength = 20), [(0, -1), (0, ymax), (1.4, 0)])
    end
end

function plot_curva(args...; puntos = O, action = :stroke, color = "black", showarrow = false)
    sethue(color)
    setline(8)
    setlinecap(:round)
    poly(puntos, action)
    
    if showarrow && length(puntos) >= 2
        p_fin, p_ant = puntos[end], puntos[end-1]    
        dx, dy = p_fin.x - p_ant.x, p_fin.y - p_ant.y
        angulo = atan(dy, dx) + pi
        arrowhead(p_fin + Point(dx, dy); shaftangle = angulo, headlength = 25)
    end
end

function punto(args...; punto = O, centro = O)
    color(sethue(AZUL)..., 1)
    circle(centro, 7, :fill)
end

function agujero(args...; punto = O, color = "black", radio = 8)
    setcolor("white")
    circle(punto, radio, :fill)
    sethue(color)
    setline(4)
    circle(punto, radio, :stroke)
end

function curva(x)
    x = x + 1.5
    if 0 <= x < 1
        return sin(3pi/2*x) + 2
    elseif 1 <= x < 1.5
        return ((x-1)*3)^4 + 1
    elseif 1.5 <= x
        return sin(3pi/2 * (x - 1/2)) + 2
    end
end

macro make_video(filename, titulo_texto, ejes_valor, cuerpo)
    return quote
        video = Video(W_WIDTH, W_HEIGHT)
        Background(1:FRAMES, ground)

        Object((args...) -> ejes(; n_axis = $ejes_valor)) 
        Object((args...) -> titulo(;titulo = $titulo_texto), to_screen(0,-2.5))
        Object(autor, to_screen(1.5,-0.5))

        $(esc(cuerpo))

        render(video; pathname = $filename, framerate = 30)
    end
end

