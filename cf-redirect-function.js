function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;

    // Redirect www to non-www
    if (host === 'www.rcfconnect.in') {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: 'https://rcfconnect.in' + request.uri }
            }
        };
    }

    return request;
}
