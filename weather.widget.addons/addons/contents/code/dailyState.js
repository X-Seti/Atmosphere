.pragma library

function today() {
    return new Date().toISOString().slice(0, 10)
}

function shouldLogWeather(cfg) {
    return cfg.lastLoggedDate !== today()
}

function shouldPrompt(cfg, popupHour) {
    let hour = new Date().getHours()
    return hour >= popupHour && cfg.lastPromptDate !== today()
}
