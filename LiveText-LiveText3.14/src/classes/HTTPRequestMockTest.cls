@isTest
global class HTTPRequestMockTest implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String bodyAsString;
    protected Map<String, String> responseHeaders;
    Map<String, HttpCalloutMock> requests;

    public HTTPRequestMockTest() {
    }
    
    public HTTPRequestMockTest(Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.bodyAsString = body;
        this.responseHeaders = responseHeaders;
    }
    
    public HTTPRequestMockTest(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
        System.assert(req.getEndpoint() != null);
        if (requests == null) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(code);
            resp.setStatus(status);
            if (bodyAsString != null) {
                resp.setBody(bodyAsString);
            }
            if (responseHeaders != null) {
                for (String key : responseHeaders.keySet()) {
                    resp.setHeader(key, responseHeaders.get(key));
                }
            }
            return resp;
        } else {
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                return null;
            }
        }
    }
}