fileConn<-file("deletethis.txt")
writeLines(as.character(Sys.time()), fileConn)
close(fileConn)
