
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Escape XML text
#'
#' @param x string to escape
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
esc <- function(x) {
  x <- gsub('&', '&amp;' , x, useBytes = TRUE, fixed = TRUE)
  x <- gsub('<', '&lt;'  , x, useBytes = TRUE, fixed = TRUE)
  x <- gsub('>', '&gt;'  , x, useBytes = TRUE, fixed = TRUE)
  x <- gsub("'", '&apos;', x, useBytes = TRUE, fixed = TRUE)
  x <- gsub('"', '&quot;', x, useBytes = TRUE, fixed = TRUE)
  x
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' XML element builder
#'
#' @docType class
#'
#' @section Usage:
#' \preformatted{doc <- XMLDocument$new()
#' doc <- xml_doc()
#'
#' elem <- XMLElement$new("meta", type = "info")
#' elem <- xml_elem("meta", type = "info")
#'
#' elem$update(margin = "auto")
#'
#' new_elem <- elem$copy()
#'
#' }
#'
#' @usage NULL
#' @format NULL
#'
#' @section Methods:
#'
#' \describe{
#'
#'
#'
#' \item{\code{$new(name, ...)}}{
#' Create a new \code{XMLElement} with the given name. Extra named arguments
#' are treated as tag attributes, and unnamed arguments are considered child
#' nodes.
#' \tabular{ll}{
#'   \code{name} \tab name of xml tag to create \cr
#'   \code{...} \tab attribute name/value pairs, and child nodes \cr
#' }
#' }
#'
#'
#' \item{\code{$update(...)}}{
#' Updates the attributes and children.
#'
#' Named arguments are considered attributes and will overwrite
#' existing attributes with the same name. Set to NULL to delete the attribute.
#' Set to NA to make this a bare attribute without a value.
#'
#' Unnamed arguments are appended to the list of child nodes.  These
#' should be text, other XMLElements or any ojbect that can be represented
#' as a single text string using "as.character()".  To be specific about
#' where in the child list a node will be placed, use \code{$append()}
#' \tabular{ll}{
#'   \code{...} \tab attribute name/value pairs, and child nodes \cr
#' }
#' }
#'
#'
#' \item{\code{$append(...)}}{
#' Append \code{XMLElement} objects as children to this element
#' \tabular{ll}{
#'   \code{...} \tab all arguments treated as XMLElement objects and added as the children of this element \cr
#' }
#' }
#'
#'
#' \item{\code{$add(name, ...)}}{
#' Create a new \code{XMLElement} and add it as a  child to this element. Return the
#' new element.  \emph{See \code{$new()} for description of arguments.}
#' }
#'
#' \item{\code{$remove(indices)}}{
#' Remove \code{XMLElement} child objects from this element by index.
#' \tabular{ll}{
#'   \code{indices} \tab indices of XMLElement objects to remove \cr
#' }
#' }
#'
#' \item{\code{$as_character()}}{
#' Convert \code{XMLElement} to a character string.
#' }
#'
#' \item{\code{$print()}}{
#' Print \code{XMLElement} to terminal.
#' }
#'
#' \item{\code{$copy()}}{
#' Copy \code{XMLElement}.
#' }
#'
#'}
#'
#'
#' @examples
#' \dontrun{
#' XMLElement$new('div', class = ".big", "DIV contents")
#' }
#'
#'
#' @import R6
#' @import glue
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
XMLElement <- R6::R6Class(
  "XMLElement",

  public = list(
    name     = NULL,
    attribs  = NULL,
    children = NULL,

    initialize = function(name, ...) {
      self$name     <- name
      self$attribs  <- list()
      self$children <- list()

      self$update(...)

      invisible(self)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Update the XML Element.
    #   - Named arguments are considered attributes and will overwrite
    #     existing attributes with the same name. Set to NULL to delete the attribute
    #   - Unnamed arguments are appended to the list of child nodes.  These
    #     should be text, other XMLElements or any ojbect that can be represented
    #     as a single text string using "as.character()"
    #   - to print just the attribute name, but without a value, set to NA
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    update = function(...) {
      varargs      <- list(...)
      vararg_names <- names(varargs)
      if (is.null(vararg_names)) {
        vararg_names <- character(length = length(varargs))
      }
      has_name   <- nzchar(vararg_names)

      children <- varargs[!has_name]
      attribs  <- varargs[ has_name]

      self$attribs  <- modifyList(self$attribs, attribs, keep.null = FALSE)
      do.call(self$append, children)

      invisible(self)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Insert a child node. by default at the end of the list of children nodes
    # but 'position' argument can be used to set location
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    append = function(..., position = NULL) {
      child_objects <- list(...)

      if (is.null(position)) {
        self$children <- append(self$children, child_objects)
      } else {
        self$children <- append(self$children, child_objects, after = position - 1)
      }

      invisible(self)
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # create an XML element and add it to the document. return the newly
    # created element
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    add = function(name, ...) {
      if (!is.character(name)) {
        stop("XMLElement$add(): 'name' must be a character string")
      }
      new_elem <- XMLElement$new(name, ...)
      self$append(new_elem)
      invisible(new_elem)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Remove child objects at the given indicies
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    remove = function(indicies) {
      self$children[indices] <- NULL
      invisible(self)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Recursively convert this XMLElement and children to text and concatenate
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    as_character_inner = function(..., depth = 0) {
      indent1   <- create_indent(depth)
      indent2   <- create_indent(depth + 1)

      na_attribs    <- Filter(       is.na , self$attribs)
      value_attribs <- Filter(Negate(is.na), self$attribs)

      if (length(na_attribs) > 0) {
        na_attribs  <- names(na_attribs)
        na_attribs  <- paste(na_attribs, sep = " ")
        na_attribs  <- paste0(" ", na_attribs)
      } else {
        na_attribs <- NULL
      }

      if (length(value_attribs) > 0) {
        value_attribs <- paste(names(value_attribs),
                               paste0('"', unlist(value_attribs), '"'),
                               sep = "=", collapse = " ")
        value_attribs <- paste0(" ", value_attribs)
      } else {
        value_attribs <- NULL
      }

      attribs <- paste0(c(value_attribs, na_attribs), sep = "")
      open    <- glue::glue("{indent1}<{self$name}{attribs}>")
      close   <- glue::glue("{indent1}</{self$name}>")

      if (length(self$children) > 0) {
        children <- lapply(
          self$children,
          function(x, depth) {
            if (is.character(x)) {
              paste0(indent2, x)
            } else {
              x$as_character_inner(depth = depth)
            }
          }
          , depth = depth + 1)
        children <- unlist(children, use.names = FALSE)
      } else {
        children = NULL
      }

      if (is.null(children)) {
        open  <- glue::glue("{indent1}<{self$name}{attribs} />")
        close <- NULL
      }

      c(open, children, close)
    },


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Recursively convert this XMLElement and children to text and concatenate
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    as_character = function(..., depth = 0, include_declaration = FALSE) {
      xml_string <- paste0(self$as_character_inner(depth = depth), collapse = "\n")

      if (include_declaration) {
        xml_string <- paste('<?xml version="1.0" encoding="UTF-8"?>', xml_string, sep = "\n")
      }

      xml_string
    },



    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Print the XML string
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    print = function(include_declaration = FALSE, ...) {
      cat(self$as_character(include_declaration = include_declaration, ...))
      invisible(self)
    },

    save = function(filename, include_declaration = FALSE, ...) {
      xml_string <- self$as_character(include_declaration = include_declaration)

      writeLines(xml_string, filename)
      invisible(self)
    },

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Deep copy needed as 'styles' is a list of R6 objects
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    copy = function() {
      self$clone(deep = TRUE)
    }
  ),

  private = list(
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # When called with `$clone(deep = TRUE)`, the 'deep_clone' function is
    # called for every name/value pair in the object.
    # See: https://r6.r-lib.org/articles/Introduction.html
    # Need special handling for:
    #   - 'children' is a list of R6 objects
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    deep_clone = function(name, value) {
      if (name %in% c('children')) {
        lapply(value, function(x) {if (inherits(x, "R6")) x$clone(deep = TRUE) else x})
      } else {
        value
      }
    }
  )
)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Retrieve character representation of XMLElement
#'
#' @param x XMLElement object
#' @param include_declaration Include the XML declaration at the top? Default: FALSE
#' @param ... other arguments
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
as.character.XMLElement <- function(x, include_declaration = FALSE, ...) {
  x$as_character(include_declaration = include_declaration, ...)
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname XMLElement
#' @usage NULL
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
xml_elem <- function(name, ...) {
  XMLElement$new(name = name, ...)
}

