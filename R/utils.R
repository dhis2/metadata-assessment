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

deleteMetadata <- function(payload, d2_session) {

  url <-paste0(d2_session$url,"api/metadata?importStrategy=DELETE")
  r <- httr::POST(url = url,
                  body = jsonlite::toJSON(payload,auto_unbox = TRUE),
                  content_type_json(),
                  handle = d2_session)

  return(r)
}

transformYAMLtoJSON <- function(filepath) {
  r <- yaml::read_yaml(filepath)

  summary_sql <- list(id = r$summary_uid,
                      name = paste0(r$name,"_S"),
                      description = r$description,
                      sqlQuery = r$summary_sql,
                      type = "QUERY",
                      cacheStrategy="NO_CACHE",
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
                      cacheStrategy="NO_CACHE",
                      sharing=list(
                        external=FALSE,
                        public="rwr-----"
                      ))
  list(summary_sql,details_sql)

}

transformYAMLtoControlFile<-function(include_protected = FALSE, include_slow = FALSE) {
  all_yaml_files<-list.files("yaml/",pattern="*.yaml",recursive = TRUE,full.names = TRUE)

  d <- purrr::map_dfr(all_yaml_files, yaml::read_yaml) %>%
    dplyr::mutate(is_protected = dplyr::case_when(is.na(is_protected) ~ FALSE,
    TRUE ~ is_protected))  %>%
    dplyr::mutate(is_slow = dplyr::case_when(is.na(is_slow) ~ FALSE,
                                                  TRUE ~ is_slow))  %>%
    dplyr::arrange(section,section_order)

  dups <-  d %>% dplyr::select(name,description,summary_uid,details_uid) %>%
    dplyr::mutate_all(function(x) duplicated(x)) %>%
    dplyr::mutate(has = rowSums(.) > 0) %>%
    purrr::set_names(paste0(names(.),"_dup"))

  if ( any(colSums(dups)!=0) ) {
    duplicates <- d %>%
      dplyr::select(name,description,summary_uid,details_uid) %>%
      dplyr::bind_cols(dups) %>%
      dplyr::filter(has_dup > 0)
    print(duplicates)
    stop("Duplicates found!")
  }

#Filter any protected tables
 if (!include_protected) {
   d <- d  %>% dplyr::filter(!is_protected)
 }

 if (!include_slow) {
   d <- d %>% dplyr::filter(!is_slow)
 }

  return(d)
}

transformYAMLtoMetadata <- function(include_protected=FALSE,include_slow = FALSE) {
 r <- transformYAMLtoControlFile(include_protected,include_slow)

 sql_views <- list()
 for (i in seq_len(NROW(r))) {
   summary_sql <- list(id = r$summary_uid[i],
                       name = paste0(r$name[i],"_S"),
                       description = r$description[i],
                       sqlQuery = r$summary_sql[i],
                       type = "QUERY",
                       cacheStrategy="NO_CACHE",
                       sharing=list(
                         external=FALSE,
                         public="rwr-----"
                       ))

   details_sql <- list(id = r$details_uid[i],
                       name = paste0(r$name[i],"_D"),
                       description = r$description[i],
                       sqlQuery = r$details_sql[i],
                       type = "QUERY",
                       cacheStrategy="NO_CACHE",
                       sharing=list(
                         external=FALSE,
                         public="rwr-----"
                       ))
   this_row <- list(summary_sql,details_sql)
   sql_views <- append(this_row,sql_views)
 }

 list(sqlViews=sql_views)

}

getSQLView <- function(uid, d2_session) {

  # #Execute the view first to be sure its fresh
  # url <- paste0(d2_session$url,"api/sqlViews/",uid,"/execute")
  # r <- httr::POST(url,content_type_json(), handle = d2_session)
  # if (r$status_code != 201L) {
  #   warning(paste0("Could not execute view ",uid))
  #   return(data.frame())
  # }


  r <- tryCatch( httr::GET(paste0(d2_session$url,"api/sqlViews/",uid,"/data.json"),
                     handle=d2_session,
                     content_type_json(),
                     timeout(600)) ,
                 error = function(e) print(e) )

  if (is.null(r)) {
    print(paste("ERROR! View", uid, "did not respond in time."))
    return(NULL)
  }

  if (r$status_code == 500L) {
    return( list(
      uid = uid,
      response_code = r$status_code,
      message = httr::content(r)$message
    ) )
  }

  if (r$status_code == 200L) {
   resp <-  r %>%
      httr::content("text") %>%
      jsonlite::fromJSON(.)

   data <- as.data.frame(resp$listGrid$rows)
   #If there are no rows...this should never happen
   if (NROW(data) == 0) {
     return(NULL)
   }

   names(data) <- resp$listGrid$headers$name
   data$uid <- uid
   return(data)
  }

}

getDetailsUID <- function(name,views) {
  new_name <- stringr::str_replace(name,"_S","_D")
  dplyr::filter(views,name == new_name) %>%
    dplyr::pull(id)
}

createRegistryYAML<- function() {
  all_yaml_files<-list.files("yaml/",pattern="*.yaml",recursive = TRUE,full.names = FALSE)
  r <- list(checks = all_yaml_files)
  yaml::write_yaml(r,"data-integrity-checks.yaml")
}

