generateUID<-function(codeSize=11){
  #Generate a random seed
  runif(1)
  allowedLetters<-c(LETTERS,letters)
  allowedChars<-c(LETTERS,letters,0:9)
  #First character must be a letter according to the DHIS2 spec
  firstChar<-sample(allowedLetters,1)
  otherChars<-sample(allowedChars,codeSize-1)
  uid<-paste(c(firstChar,paste(otherChars,sep="",collapse="")),sep="",collapse="")
  return(uid)}

uploadMetadata <- function(payload, d2_session) {
  url <-paste0(d2_session$url,"api/metadata")
  r <- httr::POST(url = url,
                  body = jsonlite::toJSON(payload,auto_unbox = TRUE),
                  content_type_json(),
                  handle = d2_session)
  return(r)
}

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
          type="QUERY",
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


transformYAMLtoJSON <- function(filepath) {
  r <- yaml::read_yaml(filepath)
  
  summary_sql <- list(id = r$summary_uid,
                      name = paste0(r$name,"_S"),
                      description = r$description,
                      sqlQuery = r$summary_sql,
                      type = "QUERY",
                      sharing=list(
                        external=FALSE,
                        public="rwr-----"
                      )
  )
  details_sql <- list(id = r$details_uid,
                      name = paste0(r$name,"_D"),
                      description = r$description,
                      sqlQuery = r$details_sql,
                      type = "QUERY",
                      sharing=list(
                        external=FALSE,
                        public="rwr-----"
                      ))
  list(summary_sql,details_sql)
  
}


transformYAMLtoControlFile<-function(file) {
  all_yaml_files<-list.files("yaml/",pattern="*.yaml",recursive = TRUE,full.names = TRUE)
  d <- purrr::map_dfr(all_yaml_files, yaml::read_yaml) %>% 
    dplyr::arrange(section,section_order)
  
  dups <-  d %>% dplyr::select(name,description,summary_uid,details_uid) %>% 
    dplyr::mutate_all(function(x) duplicated(x)) %>% 
    mutate(has_duplicate = rowSums(across(where(is.logical))) > 0) %>% 
    dplyr::pull(has_duplicate)
  
  if (any(dups)) {
    dups <- d %>% dplyr::filter(dups)
    print(dups)
    stop("Duplicates found!")
  }
  
  return(d)
}

transformYAMLtoMetadata <- function() {
 r <- transformYAMLtoControlFile()
 
 sql_views <- list()
 for (i in seq_len(NROW(r))) {
   summary_sql <- list(id = r$summary_uid[i],
                       name = paste0(r$name[i],"_S"),
                       description = r$description[i],
                       sqlQuery = r$summary_sql[i],
                       type = "QUERY",
                       sharing=list(
                         external=FALSE,
                         public="rwr-----"
                       ))
   
   details_sql <- list(id = r$details_uid[i],
                       name = paste0(r$name[i],"_D"),
                       description = r$description[i],
                       sqlQuery = r$details_sql[i],
                       type = "QUERY",
                       sharing=list(
                         external=FALSE,
                         public="rwr-----"
                       ))
   this_row <- list(summary_sql,details_sql)
   sql_views <- append(this_row,sql_views)
 }
 
 list(sqlViews=sql_views)
 
}

getSQLView <- function(uid,d2_session) {
  
  # #Execute the view first to be sure its fresh
  # url <- paste0(d2_session$url,"api/sqlViews/",uid,"/execute")
  # r <- httr::POST(url,content_type_json(), handle = d2_session)
  # if (r$status_code != 201L) {
  #   warning(paste0("Could not execute view ",uid))
  #   return(data.frame())
  # }
  
  resp  <- httr::GET(paste0(d2_session$url,"api/sqlViews/",uid,"/data.json"), 
                     handle=d2_session,
                     timeout(600)) %>% 
    httr::content("text") %>% 
    jsonlite::fromJSON(.)
  headers <- resp$listGrid$headers$column
  
  df <- as.data.frame(resp$listGrid$rows,stringsAsFactors = FALSE)
  
  
  colnames(df) <- headers
  if ( NROW(df) == 0) {
    return(NULL) } 
  
  df$uid <- uid
  df
  
}

getDetailsUID <- function(name,views) {
  new_name <- stringr::str_replace(name,"_S","_D")
  dplyr::filter(views,name == new_name) %>% 
    dplyr::pull(id)
}

