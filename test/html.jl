function notebook2html!(notebook; kwargs...)
    session = ServerSession()
    run_notebook!(notebook, session)
    return notebook2html(notebook; kwargs...)
end

@testset "html" begin
    html = "<b>foo</b>"
    block = PlutoStaticHTML.code_block(html)
    @test contains(block, "&lt;b&gt;foo&lt;/b&gt;")

    notebook = Notebook([
        Cell("x = 1 + 1"),
        Cell("using Images: load"),
        Cell("PKGDIR = \"$PKGDIR\""),
        Cell("""im_file(ext) = joinpath(PKGDIR, "test", "im", "im.\$ext")"""),
        Cell("""load(im_file("png"))""")
    ])
    html = notebook2html!(notebook)
    lines = split(html, '\n')

    @test contains(lines[1], "1 + 1")
    @test contains(lines[2], "2")

    @test contains(lines[end-1], """<img src=\"data:image/png;base64,""")

    notebook = Notebook([
        Cell("md\"This is **markdown**\"")
    ])
    html = notebook2html!(notebook)
    lines = split(html, '\n')
    @test contains(lines[2], "<strong>")

    notebook = Notebook([
        Cell("""("pluto", "tree", "object")"""),
        Cell("""["pluto", "tree", "object"]"""),
        Cell("""[1, (2, (3, 4))]""")
    ])
    html = notebook2html!(notebook)
    lines = split(html, '\n')
    @test contains(lines[2], "(\"pluto\", \"tree\", \"object\")")
    @test contains(lines[2], "<pre")
    @test contains(lines[5], "[\"pluto\", \"tree\", \"object\"]")

    @test contains(lines[8], "[1, (2, (3, 4))]")

    notebook = Notebook([
        Cell("struct A end"),
        Cell("""
            struct B
                x::Int
                a::A
            end
            """
            ),
        Cell("B(1, A())")
    ])
    html = notebook2html!(notebook)
    lines = split(html, '\n')
    @test contains(lines[end-1], "B(1, A())")

    notebook = Notebook([
        Cell("md\"my text\"")
    ])
    html = notebook2html!(notebook; hide_md_code=true)
    lines = split(html, '\n')
    @test lines[1] == ""

    html = notebook2html!(notebook; hide_md_code=false)
    lines = split(html, '\n')
    @test lines[1] != ""
end

@testset "from_file" begin
    mktempdir() do dir
        file = joinpath(dir, "tmp.jl")
        content = pluto_notebook_content("x = 1 + 2")
        write(file, content)
        html = notebook2html(file)
        @test contains(html, "3")
    end
end
