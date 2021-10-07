transformSQLtoJSON <- function(filepath) {
  con = file(filepath, "r")
  sql.string <- ""
  
  sql_views <- list()
  sql_view <- list()
  while (TRUE) {
    line <- readLines(con, n = 1)
    
    #We hit the bottom of the file
    if (length(line) == 0) {
      sql_view$sqlQuery <-
        stringr::str_squish(stringr::str_replace_all(sql.string, "[\r\n]" , ""))
      sql_views <- rlist::list.append(sql_views, sql_view)
      break
    }
    
    line <- gsub("\\t", " ", line)
    #Start a new list and append the old one before resetting
    if (grepl("--type:", line) == TRUE) {
      if (grepl("details", line) == TRUE) {
        sql_view$sqlQuery <-
          stringr::str_squish(stringr::str_replace_all(sql.string, "[\r\n]" , ""))
        sql_views <- rlist::list.append(sql_views, sql_view)
      }
      sql.string = ""
      sql_view <-
        list(
          id = character(),
          name = character(),
          description = character(),
          sqlQuery = character(),
          sharing=list(
            external=FALSE,
            public="rwr-----"
          )
        )
    }
    
    if (grepl("--uid:", line) == TRUE) {
      sql_view$id <- sub("--uid: ", "", line)
    }
    
    if (grepl("--name:", line) == TRUE) {
      sql_view$name <- sub("--name: ", "", line)
    }
    if (grepl("--description:", line) == TRUE) {
      sql_view$description <- sub("--description: ", "", line)
    }
    if (!grepl("--", line)) {
      sql.string <- paste(sql.string, line)
    }
  }
  
  close(con)
  return(sql_views)
}



all_sql_files<-list.files("sql/",pattern="*.sql")

all_sql_views <-list()
for (this_file in all_sql_files) {
  filepath <- paste0("sql/",this_file)
  this_sql_sequence<-transformSQLtoJSON(filepath)
  all_sql_views <- append(all_sql_views,this_sql_sequence)
}

jsonlite::toJSON(list(sqlViews=all_sql_views),auto_unbox = TRUE)
