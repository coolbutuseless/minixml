

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Recursively parse an XML2 node tree into a `minixml` document
#'
#' This uses 'xml2' package to do the parsing.
#'
#' @param xml2_node root node of a document or an element node
#' @param as_document whether or not to make the root node a document node. Otherwise
#'        just create an element node.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_inner <- function(xml2_node, as_document = TRUE) {
  name     <- xml2::xml_name(xml2_node)
  attrs    <- xml2::xml_attrs(xml2_node)
  children <- xml2::xml_contents(xml2_node)

  if (as_document) {
    doc <- xml_doc(name = name)
  } else {
    doc <- xml_elem(name = name)
  }
  do.call(doc$update, as.list(attrs))

  child_nodes <- lapply(children, function(x) {
    if (xml2::xml_name(x) == 'text' && length(xml2::xml_attrs(x)) == 0) {
      as.character(x)
    } else {
      parse_inner(x, as_document = FALSE)
    }
  })
  do.call(doc$append, child_nodes)

  doc
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Parse xml text or file into an XMLDocument or XMLElement
#'
#' @param x,encoding,...,as_html,options options passed to \code{xml2::read_xml()}
#'
#' @return XMLDocument or XMLElement
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_xml_doc <- function(x, encoding='', ..., as_html = FALSE, options = 'NOBLANKS') {

  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("parse_xml_doc(): need 'xml2' installed to read XML", call. = FALSE)
  }

  xml2_node <- xml2::read_xml(x=x, encoding=encoding, ..., as_html=as_html, options=options)

  parse_inner(xml2_node, as_document = TRUE)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname parse_xml_doc
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
parse_xml_elem <- function(x, encoding='', ..., as_html = FALSE, options = 'NOBLANKS') {

  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("parse_xml_elem(): need 'xml2' installed to read XML", call. = FALSE)
  }

  xml2_node <- xml2::read_xml(x=x, encoding=encoding, ..., as_html=as_html, options=options)

  parse_inner(xml2_node, as_document = FALSE)
}
