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

transformYAMLtoControlFile<-function(dir_path = getwd(), include_protected = FALSE, include_slow = FALSE) {
  all_yaml_files<-list.files("yaml/",pattern="*.yaml",recursive = TRUE,full.names = TRUE)

  d <- purrr::map_dfr(all_yaml_files, yaml::read_yaml) %>%
    dplyr::mutate(is_protected = FALSE)  %>%
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
    warning("Duplicates found!")
    return(duplicates)
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

transformYAMLtoExporter <- function(dir_path = getwd(),include_protected=TRUE,include_slow = FALSE) {
  r <- transformYAMLtoControlFile(dir_path = dir_path,include_protected,include_slow)
  #Prefix with dhis
  r$name <- paste0('dhis_', r$name)
  #Use ratio instead of percentage
  r$summary_sql <- gsub("100?([\\.0 ]+)\\*","", r$summary_sql)
  r$summary_sql <- gsub("as percent","as ratio", r$summary_sql)
  appendWithSpaces <-function(string,path,indent){
    if (indent > 0) {
      indent_prefix <- paste(rep(" ",indent),sep="",collapse="")
    } else {
      indent_prefix <- ""
    }


    cat(paste0(indent_prefix,string),file=path,append = TRUE, sep="\n")
  }

  file_name <- "dhis_metadata_sql_exporter.yaml"
  unlink(file_name)
  cat("collector_name: dhis_system",file=file_name, sep="\n")
  appendWithSpaces("metrics:", path=file_name,indent = 0)

  for (i in seq_len(NROW(r))) {
    appendWithSpaces(paste0("- metric_name: ",r$name[i]), path=file_name,indent = 2)
    appendWithSpaces("type: gauge", path=file_name,indent = 4)
    appendWithSpaces(paste0("help : ", paste0("'",r$description[i],"'")), path=file_name,indent = 4)
    appendWithSpaces("values: [ratio]", path=file_name,indent = 4)
    appendWithSpaces("query: |", path=file_name,indent = 4)
    appendWithSpaces(r$summary_sql[i], path=file_name,indent = 6)
  }

}

addcols <- function(data, cnames, type = "character") {
  add <- cnames[!cnames %in% names(data)] # Subsets column name list BY only
  # keeping names that are NOT in the supplied dataframes column names already.

  if (length(add) != 0) { #If their are columns that need to be filled in THEN
    #Impute the NA value based upon the type provided in the function.
    # TODO: #Automate the character type or at least a list variable for type.
    if (type == "character") {
      data[add] <- NA_character_
    } else if (type == "numeric") {
      data[add] <- NA_real_
    } else if (type == "logical") {
      data[add] <- NA
    }
  }

  return(data)

}

getSQLView <- function(uid, d2_session) {

  # #Execute the view first to be sure its fresh
  # url <- paste0(d2_session$url,"api/sqlViews/",uid,"/execute")
  # r <- httr::POST(url,content_type_json(), handle = d2_session)
  # if (r$status_code != 201L) {
  #   warning(paste0("Could not execute view ",uid))
  #   return(data.frame())
  # }


  r <- tryCatch( httr::GET(paste0(d2_session$url,"api/sqlViews/",uid,"/data.csv"),
                     handle=d2_session,
                     timeout(600)) ,
                 error = function(e) print(e) )

  if (is.null(r)) {
    print(paste("ERROR! View", uid, "did not respond in time."))
    return(NULL)
  }

  if (r$status_code != 200L) {
    return( list(
      uid = uid,
      response_code = r$status_code,
      message = ifelse(is.null(httr::content(r)$message),"Unknown error",httr::content(r)$message)
    ) )
  }

  if (r$status_code == 200L) {

    r %>%
      httr::content("text") %>%
      { # nolint
        suppressWarnings(readr::read_csv(
          .,
          col_names = TRUE,
          col_types = readr::cols(
            .default = "c"
          )
        ))
      }
     }

}

getSummaryView <- function(uid,d2_session) {
   x <- getSQLView(uid,d2_session)

   if (inherits(x,"list")) {
     return(x)
   }

   if (inherits(x, "data.frame")) {
     x %>%
       addcols(.,c("value","percent","count")) %>%
       dplyr::mutate(uid = uid) %>%
       dplyr::select(c("uid","value","percent","count"))
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

