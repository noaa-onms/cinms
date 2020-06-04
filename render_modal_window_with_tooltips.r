library(rmarkdown)
library(here)
library(tidyverse)

# Draft version of code to render modal windows with tooltips. The overall idea is to generate a markdown file from a 
# given modal rmd file. Within that markdown file, we then insert the javascript package tippy as well as inserting the
# specific tippy tooltip. We then generate a html file for the modal window from the modified markdown file and then
# delete the markdown file

# set the modal window
modal = "infauna"
modal = "_acidification"

# set the path 
modal_path = paste0(here::here("modals"),"/")

# create the intermediary markdown file
render(paste0(modal_path, modal, ".Rmd"), output_dir = modal_path, output_format = "md_document", clean=F)

# read the markdown file 
tx  <- readLines(paste0(modal_path, modal, ".knit.md"))

# load in the glossary that will be used to create the tooltips.  Reverse alphabetize the glossary, which will come in handy later
glossary_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=glossary"
glossary <- read_csv(glossary_csv)
glossary <- glossary[order(glossary$term, decreasing = TRUE),]

# initialize the string variable that will hold the javascrip tooltip

script_tooltip = ""

# go through each row of the glossary
for (q in 1:nrow(glossary)) {
  
  # set a variable to zero that is used to keep track of whether a particular glossary word is in the modal window
  flag = 0
  
  # load in a specific glossary term
  search_term = glossary$term[q]

  # there is probably a better way to do this with the use of regular expressions, but let's keep track of three 
  # versions of the search terms with various capitalizations, This is done this way in order to preserve the 
  # original capitalization pattern of the modal window when words are replaced in the markdown file
  search_text_lower = str_to_lower(search_term)
  search_text_capital = str_to_title(search_term)
  search_text_sentence = str_to_sentence(search_term)

  # the css to be wrapped around any glossary word
  span_definition = paste0('<span aria-describedby="tooltip', q, '" tabindex="0" style="border-bottom: 1px dashed #000000; font-size:110%" id="tooltip', q, '">')

  # the glossary word will be replaced by a combination of the glossary word with the wrapper css (preserving the 
  # original pattern of capitalization)    
  replacement_text_lower = paste0(span_definition, search_text_lower, '</span>')
  replacement_text_capital = paste0(span_definition, search_text_capital, '</span>')
  replacement_text_sentence = paste0(span_definition, search_text_sentence, '</span>')

  
  # let's look to see if the glossary term is a subset of a longer glossary term (that is: "aragonite" and "aragonite saturation")
  # if it is a subset, we want to identify the longer term (so that we don't put the tooltip for the
  # shorter term with the longer term). Here is why the prior alphabetizing of the glossary matters
#  glossary_match = glossary$term[startsWith (glossary$term, search_term)]
 # if (length(glossary_match)>1){
  #  glossary_subset = TRUE
   # longer_term = glossary_match[2]
 # }
  
  # let's go through every line of the markdown file looking for glossary words. We are skipping the first several
  # lines in order to avoid putting any tooltips in the modal window description
  for (i in 12:length(tx)) {
    
    # We want to avoid putting in tooltips in several situations that would cause the window to break.
    # 1. No tooltips on tabs (that is what the searching for "#" takes care of)
    # 2. No tooltips in the gray bar above the image (that is what the searching for the "</i>" and "</div> tags 
    # take care of)
    if (substr(tx[i],1,1) != "#" && str_sub(tx[i],-4) != "</i>" && str_sub(tx[i],-5) != "</div>"){

    # We also want to avoid inserting tooltips into the path of the image file, which is what the following
    # image_start is looking for. If a line does contain an image path, we want to separate that from the rest of
    # the line, do a glossary word replace on the image-less line, and then - later in this code - paste the image back on to the line 
      image_start = regexpr(pattern = "/img/cinms_cr", tx[i])[1] - 4
      
      if (image_start > 1) {
        line_content = substr(tx[i], 1, image_start)
        image_link = str_sub(tx[i], -(nchar(tx[i])-image_start))
      }
      else {
        line_content = tx[i]
      }

      # here is where we keep track of whether a glossary word shows up in the modal window - this will be used later 
      if (grepl(pattern = search_term, x = line_content, ignore.case = TRUE) ==TRUE){
        flag = 1
      }    
      
      # replace the glossary word with the glossary word plus tooltip, preserving the original pattern of capitalization
      line_content  <- gsub(pattern = search_text_lower, replace = replacement_text_lower, ignore.case = FALSE, x = line_content)      
      line_content  <- gsub(pattern = search_text_capital, replace = replacement_text_capital, ignore.case = FALSE, x = line_content)
      if (grepl(" ", search_term)==TRUE){
        line_content  <- gsub(pattern = search_text_sentence, replace = replacement_text_sentence, ignore.case = FALSE, x = line_content)
      }

      # if we separated the image path, let's paste it back on    
      if (image_start > 1) {
        tx[i] = paste0(line_content, image_link)
      }
      else {
        tx[i] = line_content
      }
      
    }
  }
  
  #if a glossary word was found in a modal window, let's add the javascript for that tooltip in
  if (flag == 1){
    script_tooltip = paste0(script_tooltip, '<script>tippy ("#tooltip', q, '",{content: "', glossary$definition[q], '"});</script>\r\n')
  }
}

# let's replace the markdown file with the modified version of the markdown file that contains all of the tooltip stuff 
# (if any)
writeLines(tx, con=paste0(modal_path, modal, ".knit.md"))

# if any glossary words are found, let's add in the javascript needed to make this all go
if (script_tooltip != ""){
  load_script=' <script src="https://unpkg.com/@popperjs/core@2"></script>
  <script src="https://unpkg.com/tippy.js@6"></script>\r\n'
  write(load_script, file=paste0(modal_path, modal, ".knit.md"),append=TRUE)
  write(script_tooltip, file=paste0(modal_path, modal, ".knit.md"),append=TRUE)
}

# write the html file and then delete the markdown file that we created at the beginning of this code
render(paste0(modal_path, modal, ".knit.md"), output_dir = modal_path, output_file=paste0(modal, ".html") )


#file.remove(paste0(modal_path, modal, ".knit.md"))  