if (interactive() && Sys.getenv("RSTUDIO") == "1") {
  local({
    # RStudio has no WakaTime plugin: send a heartbeat for the open editor file
    # after each console command, at most every 2 min per file.
    cli <- Sys.which("wakatime-cli")
    if (!nzchar(cli)) cli <- path.expand("~/.wakatime/wakatime-cli")
    if (!file.exists(cli)) return(invisible())
    last <- list(file = "", time = 0)
    addTaskCallback(function(...) {
      ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
      f <- if (is.null(ctx)) "" else ctx$path
      now <- as.numeric(Sys.time())
      if (nzchar(f) && file.exists(f) && (f != last$file || now - last$time > 120)) {
        last <<- list(file = f, time = now)
        system2(cli, c("--entity", shQuote(f), "--plugin", shQuote("rstudio rstudio-wakatime-hook/0.1")),
                wait = FALSE, stdout = FALSE, stderr = FALSE)
      }
      TRUE
    }, name = "wakatime")
  })
}
