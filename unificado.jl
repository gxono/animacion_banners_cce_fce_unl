include("module.jl")


function gif_calculo_diferencial()
    x_var1, x_var2 = -1.5:0.01:-0.08, 0:0.01:1.5
    x_tan, x_limB  = 0.5:0.01:1.5, 0.5:-0.01:0

    pts_1, pts_2, pts_tan = map(
        var -> [to_screen(x, curva) for x in var], [x_var1, x_var2, x_tan])
    pts_tan_rev = [p - to_screen(1.5, curva) for p in reverse(pts_tan)]
    pts_limB    = [to_screen(x, curva) for x in x_limB]

    function flecha(v, o, f; punto = O, color = "black", radio = 15)
        pos_actual = getworldposition(punto)
        
        if !haskey(o.opts, :pos_anterior)
            o.opts[:pos_anterior] = pos_actual
            o.opts[:angulo] = 0.0
        end
        pos_anterior = o.opts[:pos_anterior]
        
        if distance(pos_actual, pos_anterior) > 0.01
            o.opts[:angulo] = atan(pos_actual.y - pos_anterior.y, pos_actual.x - pos_anterior.x)
        end
        o.opts[:pos_anterior] = pos_actual
        
        translate(punto)
        rotate(o.opts[:angulo])
        sethue(color)
        ngon(O, radio, 3, 0, :fill)
    end

    begin
        function rectangulo(args...; x_vec, y_vec, color = "black")
            setcolor(sethue("white")..., 1)
            rect(O, x_vec * ESCALA_X, y_vec * ESCALA_Y, action = :fill)
            setcolor(sethue(color)..., 0.5)
            rect(O, x_vec * ESCALA_X, y_vec * ESCALA_Y, action = :fill)
            setline(2)
            setcolor(sethue(color)..., 0.75)
            rect(O, x_vec * ESCALA_X, y_vec * ESCALA_Y, action = :stroke)
        end

        dx = 0.1
        rectangulos = []
        for i in (-1.5+dx):dx:(-2dx)
            dy = curva(i+dx)-curva(i)
            color = dy >= 0 ? VERDE : ROJO
            push!(rectangulos, (x = i, dx = dx, dy = dy, color = color))
        end
    end

    function dibujar_tangente(args...; anim, x_start, x_end)
        video, object, frame = args
        t = (frame - 1) / (FRAMES - 1)
        prog = anim(t) 
        
        x_actual = x_start + prog * (x_end - x_start)
        m = ForwardDiff.derivative(curva, x_actual)
        angulo = atan(m * ESCALA_Y, ESCALA_X)

        sethue(NARANJA)
        setline(4)
        largo = 200
        p1 = Point(largo, 0)
        p2 = Point(-largo, 0)
        
        rotate(angulo)
        line(p1, p2, :stroke)
    end

    @make_video "diferencial.gif" "Cálculo diferencial" 1 begin
        for (i, rec) in enumerate(rectangulos)
            r = Object((args...) -> rectangulo(args...; x_vec = rec.dx, y_vec = rec.dy, color = rec.color), to_screen(rec.x, curva))
            i -= 1
            esperaA = 10
            esperaB = 30
            duracion = 15
            act!(r, Action((esperaA+2i):(esperaA+duracion+2i), sineio(), anim_translate(0, -curva(rec.x) * ESCALA_Y)))
            act!(r, Action(RFrames((esperaB+2i):(esperaB+duracion+2i)), sineio(), anim_translate(0, curva(rec.x) * ESCALA_Y)))
        end

        anim_ida_vuelta = Animation(
            [0.0, 0.5, 1.0], 
            [0.0, 1.0, 0.0], 
            [sineio(), sineio()])

        ptdv = Object(1:FRAMES, (args...) -> punto(args...))
        tangente = Object(1:FRAMES, (args...) -> dibujar_tangente(args...; anim = anim_ida_vuelta, x_start = 0.5, x_end = 1.5))
        act!(tangente, Action(1:60, sineio(), follow_path(pts_tan; closed = false)))
        act!(ptdv, Action(1:60, sineio(), follow_path(pts_tan; closed = false)))
        act!(tangente, Action(61:120, sineio(), follow_path(pts_tan_rev; closed = false)))
        act!(ptdv, Action(61:120, sineio(), follow_path(pts_tan_rev; closed = false)))

        Object((args...) -> plot_curva(; puntos = pts_1, color =  AZUL, showarrow = true))
        Object((args...) -> plot_curva(; puntos = pts_2, color =  AZUL))
        Object((args...) -> agujero(; punto = to_screen(0, curva(0)), color =  AZUL))

        for i in -20:10:FRAMES-1
            inicio = 1 + i
            
            if inicio < 1
                frames_perdidos = 1 - inicio
                duracion = 30 - frames_perdidos
                
                if duracion <= 0
                    continue
                end
                
                idxB = max(1, round(Int, (frames_perdidos / 30) * length(pts_limB)))
                idxB = min(idxB, length(pts_limB) - 1)
                inicio_fade = max(1, duracion - 5)
                
                ptlimB = Object(1:duracion, (args...) -> flecha(args...;))
                act!(ptlimB, Action(1:duracion, follow_path(pts_limB[idxB:end]; closed = false)))
                act!(ptlimB, Action(inicio_fade:duracion, sineio(), disappear(:fade)))
                act!(ptlimB, Action(inicio_fade:duracion, disappear(:scale)))
            else
                ptlimB = Object(inicio:min(30+i, FRAMES), (args...) -> flecha(args...;))
                act!(ptlimB, Action(1:10, sineio(), appear(:fade)))
                act!(ptlimB, Action(1:10, appear(:scale)))
                act!(ptlimB, Action(1:30, follow_path(pts_limB; closed = false)))            
                act!(ptlimB, Action(25:30, sineio(), disappear(:fade)))
                act!(ptlimB, Action(25:30, disappear(:scale)))
            end
        end
    end
end








function gif_calculo_integral()
    x_var1 = -1.5:0.01:-0.08
    x_var2 = 0:0.01:1.5

    pts_1, pts_2 = map(var -> [to_screen(x, curva) for x in var], [x_var1, x_var2])

    function fanimacion(a, b)
        return Animation(
            [1, 50, 70, 120],
            [a, b, b, a],
            [polyio(6), noease(),polyio(6)])
    end

    function suma_riemman(v, o, frame; curva = curva, a = -1.4, b = -0.1)
        part_min, part_max = 4.0, 100.0
        
        animacion = fanimacion(part_min, part_max)
        n = floor(animacion(frame)) |> Int
        dx = (b-a) / n
        rectangulos = []
        for x in a:dx:(b-dx/2)
            push!(rectangulos, (x = x, y = curva(x)))
        end

        for rec in rectangulos
            setcolor(sethue(NARANJA)..., 0.5)
            rect(to_screen(rec.x,0), dx * ESCALA_X, rec.y * ESCALA_Y, :fill)
            setcolor(sethue(NARANJA)..., 0.75)
            rect(to_screen(rec.x,0), dx * ESCALA_X, rec.y * ESCALA_Y, :stroke)
        end

        fontsize(40)
        setcolor(sethue("black")..., 1)
        latex(L"""\begin{equation*} \sum_{i=1}^{%$n}f(x_i)\Delta x \end{equation*}""", to_screen(-0.5, 2.5); valign = :middle,  halign = :center)
    end

    function plot_area(v, o, frame; curva = curva, a = 0.1, b = 1.4)
        pos_min, pos_max = 0.5, b
        
        animacion = fanimacion(pos_min, pos_max)

        x_actual = animacion(frame)
        pts_curva = [p for p in pts_2 if (a*ESCALA_X) < p.x < (x_actual*ESCALA_X)] |> reverse

        pAI, pAF = to_screen(a,0), to_screen(a, curva)
        pBI, pBF = to_screen(x_actual, 0), to_screen(x_actual, curva)
        lista = [pAF, pAI, pBI, pBF, pts_curva...]

        setcolor(sethue(VERDE)..., 0.5)
        poly(lista, action = :fill)

        setcolor(sethue(VERDE)..., 1)
        setline(4)
        line(pAI, pAF, :stroke)
        line(pBI, pBF, :stroke)
        sethue("black")
        circle(pAI, 4, :fill)
        circle(pBI, 4, :fill)

        fontsize(40)
        setcolor(sethue("black")..., 1)
        latex(L"""\begin{equation*} \int_{a}^{b}f(x)\,\mathrm{d}x\end{equation*}""", to_screen(1.3, 2.5); valign = :middle,  halign = :center)
    end

    @make_video "integral.gif" "Cálculo integral" 1 begin
        Object((args...) -> suma_riemman(args...))
        Object((args...) -> plot_area(args...))
        Object((args...) -> plot_curva(; puntos = pts_1, color =  AZUL, showarrow = true))
        Object((args...) -> plot_curva(; puntos = pts_2, color =  AZUL))
        Object((args...) -> agujero(; punto = to_screen(0, curva(0)), color =  AZUL))
    end 
end 







function gif_sucesiones_series()
    function fanimacion(a, b)
        return Animation(
            [1, 55, 65, 120],
            [a, b, b, a],
            [sineio(), noease(),sineio()])
    end

    function plot_sucesion(v, o, frame;)
        x_var = -1.4:0.1:-0.1
        pts   = [to_screen(x, curva) for x in x_var]

        animacion = fanimacion(1.0, 120.0)
        frame = animacion(frame)

        pos = ceil(frame/120 * 14) |> Int64
        setcolor(sethue("black")..., 1)
        setdash("longdashed")
        line(pts[pos], Point(pts[pos].x,0), :stroke)
        setcolor(sethue(NARANJA)..., 1)
        circle(pts[pos], 15, :fill)

        map(p -> punto(; centro = p), pts)

        pos -= 1 
        fontsize(40)
        setcolor(sethue("black")..., 1)
        latex(L"""a_{%$pos}""", to_screen(-0.5, 2.5); valign = :middle,  halign = :left)
    end

    function plot_serie(v, o, frame;)
        x_var = 0.1:0.1:1.4
        pts   = [to_screen(x, curva) for x in x_var]

        animacion = fanimacion(1.0, 120.0)
        frame = animacion(frame)
        
        pos = ceil(frame/120 * 14) |> Int64
        for i in 1:pos
            pt = pts[i]
            setcolor(sethue(NARANJA)..., 0.5)
            rect(pt, 0.1*ESCALA_X, -pt.y, :fill)
            setcolor(sethue(NARANJA)..., 0.75)
            rect(pt, 0.1*ESCALA_X, -pt.y, :stroke)
        end
        
        map(p -> punto(; centro = p), pts)

        pos -= 1 
        fontsize(40)
        setcolor(sethue("black")..., 1)
        latex(L"""\begin{equation*} \sum_{i=0}^{%$pos}a_i\end{equation*}""", to_screen(1.3, 1.93); valign = :bottom,  halign = :center)
    end

    @make_video "sucesiones_series.gif" "Sucesiones y series" 2 begin
        Object((args...) -> plot_sucesion(args...))
        Object((args...) -> plot_serie(args...))
    end
end







gif_calculo_diferencial()
gif_calculo_integral()
gif_sucesiones_series()