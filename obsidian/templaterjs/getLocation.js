function getFullCountryName(code) {
    let regionNames = new Intl.DisplayNames(['pl'], { type: 'region' });
    let country = regionNames.of(code);
    if (country == "Stany Zjednoczone") return "USA";
    return country;
}

function getProperCityName(city) {
    let cities = {
        'cracow': 'Kraków',
        'mokotów': 'Warszawa',
        'new york': 'Nowy Jork',
        'warsaw': 'Warszawa'
    };
    return (city.toLowerCase() in cities) ? cities[city.toLowerCase()] : city;
}


function getLocation() {
    class HTTPError extends Error { }
    let api = 'https://ipinfo.io?token=';
    let token = 'e4e4e42a915c14';
    let url = api + token;
    let opt = {
        method: 'GET',
        headers: { 'accept': 'application/json', 'host': 'ipinfo.io', 'user-agent': 'curl/8.6.0' }
    }
    let obj = {};

    const response = fetch(url, opt)
        .then(response => {
            if (!response.ok) {
                throw new HTTPError(`Fetch error: ${response.statusText}`);
            } else {
                return response.json();
            }
        })
        .then(data => {
            obj.ip = data.ip;
            obj.city = getProperCityName(data.city);
            obj.country = getFullCountryName(data.country);
            obj.longitude = data.loc.split(",")[0];
            obj.latitude = data.loc.split(",")[1];
        })
        .catch(error => console.error('Error fetching data:', error))
        .finally(console.log('Fetching completed'));

    return obj;
}

module.exports = getLocation;
