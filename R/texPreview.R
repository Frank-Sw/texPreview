#' @title Render and Preview snippets of TeX in R Viewer
#' @export
#' @description input TeX script into the function and it renders a pdf and converts it an image which is sent to Viewer.
#' @param obj character, TeX script
#' @param tex_lines vector of character, in case of special needs, instead of asking 
#' texPreview to build up, you may choose to pass in the contents of the 
#' complete LaTeX file directly. It should be a vector of character with each 
#' element as a line of raw TeX code. 
#' @param stem character, name to use in output files, Default: NULL
#' @param fileDir character, output destination. If NULL a temp.dir() 
#' will be used and no output will be saved, Default: tex_opts$get('fileDir')
#' @param overwrite logical, controls if overwriting of output stem* files given their existences
#' @param margin table margin for pdflatex call, Default: tex_opts$get('margin')
#' @param imgFormat character, defines the type of image the PDF is 
#' converted to Default: tex_opts$get('imgFormat')
#' @param returnType character, one of "viewer", "html", or "tex" determining appropriate 
#' return type for the rendering process, Default: tex_opts$get('returnType')
#' @param resizebox logical, forces a tabular tex object to be constrained on the
#'  margins of the document, Default: tex_opts$get('resizebox')
#' @param usrPackages character, vector of usepackage commands, see details for string format
#' @param engine character, specifies which latex to pdf engine to use
#'  ('pdflatex','xelatex','lualatex'), Default: tex_opts$get('engine')
#' @param cleanup character, vector of file extensions to clean up after building pdf,
#'  Default: tex_opts$get('cleanup')
#' @param keep_pdf logical, controls if the rendered pdf file should be kept
#'  or deleted, Default is FALSE
#' @param tex_message logical, controls if latex executing messages 
#' are displayed in console. Default is FALSE
#' @param density numeric, controls the density of the image. Default is 150: tex_opts$get('density)
#' @param svg_max numeric, maximum svg file size allowable to preview, Default: tex_opts$get('svg_max') 
#' @param print.xtable.opts list, contains arguments to pass to print.table, 
#' relevant only if xtable is used as the input, Default: tex_opts$get('print.xtable.opts')
#' @param opts.html list, html options, Default: tex_opts$get('opts.html')
#' @param ... passed to \code{\link[base]{system}}
#' @details The function assumes the system has pdflatex installed and it is defined in the PATH. The function does not return anything to R.
#' If fileDir is specified then two files are written to the directory. An image file of the name stem with the extension specified in imgFormat.
#' The default extension is png.The second file is the TeX script used to create the output of the name stem.tex.   If you do not wish to view the 
#' console output, pass the corresponding arguments to \code{...}, e.g., ignore.stdout=TRUE.
#' usrPackage accepts a vector of character strings built by the function \code{\link{build_usepackage}}, of the form
#'  \\\\usepackage[option1,option2,...]\{package_name\}, see the TeX wikibook for more information \url{https://en.wikibooks.org/wiki/LaTeX/Document_Structure#Packages}.
#' @return 
#' NULL
#' @examples
#' data('iris')
#' if(interactive()){
#' 
#' #use xtable to create tex output
#'  texPreview(obj = xtable::xtable(head(iris,10)))
#' 
#' #use knitr kable to create tex output
#'  texPreview(knitr::kable(mtcars, "latex"))
#' 
#' tex='\\begin{tabular}{llr}
#' \\hline
#' \\multicolumn{2}{c}{Item} \\\\
#' \\cline{1-2}
#' Animal    & Description & Price (\\$) \\\\
#' \\hline
#' Gnat      & per gram    & 13.65      \\\\
#' & each        & 0.01       \\\\
#' Gnu       & stuffed     & 92.50      \\\\
#' Emu       & stuffed     & 33.33      \\\\
#' Armadillo & frozen      & 8.99       \\\\
#' \\hline
#' \\end{tabular}'
#' 
#' texPreview(obj = tex,stem = 'eq',imgFormat = 'svg')
#' tikz_example <- system.file('examples/tikz/credit-rationing.tex',package = 'texPreview')
#' tikzEx=readLines(tikz_example,warn = FALSE)
#' 
#' #use tex_lines parameter to pass full document
#'   texPreview(tex_lines = tikzEx)
#' 
#' #use texPreview preamble to build document chunks
#'   usetikz=paste(tikzEx[14:23],collapse="\n")
#'   bodytikz=paste(tikzEx[25:90],collapse="\n")
#'   texPreview(obj = bodytikz,usrPackages = build_usepackage(pkg = 'tikz',uselibrary = usetikz))
#' }
#' 
texPreview <- function (obj, 
                        tex_lines = NULL,
                        stem = NULL,
                        fileDir = tex_opts$get('fileDir'), 
                        overwrite = TRUE, 
                        margin = tex_opts$get('margin'),
                        imgFormat = tex_opts$get('imgFormat'), 
                        returnType = tex_opts$get('returnType'),
                        resizebox = tex_opts$get('resizebox'),
                        usrPackages = NULL,
                        engine = tex_opts$get('engine'),
                        cleanup = tex_opts$get('cleanup'),
                        keep_pdf = FALSE, 
                        tex_message = FALSE, 
                        density = tex_opts$get('density'),
                        svg_max = tex_opts$get('svg_max'),
                        print.xtable.opts = tex_opts$get('print.xtable.opts'),
                        opts.html = tex_opts$get('opts.html'),
                        ...) 
{

  session_opts <- tex_opts$get()
  
  tex_opts$set(
    fileDir = fileDir,
    margin = margin,
    imgFormat = imgFormat,
    returnType = returnType,
    resizebox = resizebox,
    engine = engine,
    cleanup = cleanup,
    density = density,
    print.xtable.opts = print.xtable.opts,
    opts.html = opts.html,
    svg_max = svg_max
  )
  
  if(is.null(stem)){
    
    stem = "tex_temp"  
    
  }
  
  on.exit({
    
    tex_cleanup(cleanup,stem,keep_pdf)
    tex_opts$set(session_opts)
    
  },add = TRUE)

  write_flag <- tex_dir_setup()

  if (is.null(tex_lines)) {
  
    tex_lines <- build_lines(obj, stem, usrPackages)
  
  }
  
  tab_lines <- readLines(file.path(tex_opts$get('fileDir'),sprintf('%s.tex',stem)))
  
  tex_build(tex_lines,stem,tex_message,...)

  imgOut <- tex_image(obj,stem, write_flag, overwrite)

  tex_viewer(imgOut, stem)

  return(tex_return(obj = tab_lines,stem, img_format = imgFormat))
  
}
