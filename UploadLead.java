package com.sfdc.rest;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.message.BasicHeader;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.HttpStatus;
import org.apache.http.util.EntityUtils;
import org.apache.http.client.ClientProtocolException;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONTokener;
import org.json.JSONException;
import com.sfdc.exceptions.SFDCException;
import com.sfdc.utils.CSVUtils;
import com.sfdc.utils.XMLParser;

public class UploadLead {

	static final String LOGINURL = "https://login.salesforce.com";
	static final String GRANTSERVICE = "/services/oauth2/token?grant_type=password";
	static final String leadXML = "Leads.xml";
	static final String csvFileName = "LeadData.csv";
	static final String configFile = "sfdc-config.xml";

	private static String REST_ENDPOINT = "/services/data";
	private static String API_VERSION = "/v32.0";
	private static String baseUri;
	private static Header oauthHeader;
	private static Header prettyPrintHeader = new BasicHeader("X-PrettyPrint","1");
	private static String leadId;

	public static void main(String[] args) throws SFDCException {

		HttpClient httpclient = HttpClientBuilder.create().build();
		XMLParser xml = new XMLParser(configFile);
		String loginURL = LOGINURL + GRANTSERVICE + "&client_id="
				+ xml.parseByElement("ConsumerKey") + "&client_secret="
				+ xml.parseByElement("ConsumerSecret") + "&username="
				+ xml.parseByElement("Username") + "&password="
				+ xml.parseByElement("Password")
				+ xml.parseByElement("SecurityToken");

		HttpPost httpPost = new HttpPost(loginURL);
		HttpResponse response = null;

		try {
			response = httpclient.execute(httpPost);
		} catch (ClientProtocolException cpException) {
			cpException.printStackTrace();
		} catch (IOException ioException) {
			ioException.printStackTrace();
		}

		final int statusCode = response.getStatusLine().getStatusCode();
		if (statusCode != HttpStatus.SC_OK) {
			System.out.println("Error authenticating to Force.com: "+ statusCode);
			return;
		}

		String getResult = null;
		try {
			getResult = EntityUtils.toString(response.getEntity());
		} catch (IOException ioException) {
			ioException.printStackTrace();
		}

		JSONObject jsonObject = null;
		String loginAccessToken = null;
		String loginInstanceUrl = null;

		try {
			jsonObject = (JSONObject) new JSONTokener(getResult).nextValue();
			loginAccessToken = jsonObject.getString("access_token");
			loginInstanceUrl = jsonObject.getString("instance_url");
		} catch (JSONException jsonException) {
			jsonException.printStackTrace();
		}

		baseUri = loginInstanceUrl + REST_ENDPOINT + API_VERSION;
		oauthHeader = new BasicHeader("Authorization", "OAuth "+ loginAccessToken);
		System.out.println("oauthHeader1: " + oauthHeader);
		System.out.println("\n" + response.getStatusLine());
		System.out.println("Successful login");
		System.out.println("instance URL: " + loginInstanceUrl);
		System.out.println("access token/session ID: " + loginAccessToken);
		System.out.println("baseUri: " + baseUri);
		createLeads();
		httpPost.releaseConnection();
	}

	public static void createLeads() throws SFDCException {
		System.out.println("\n_______________ Lead INSERT _______________");

		String uri = baseUri + "/sobjects/Lead/";
		try {
			HttpClient httpClient = HttpClientBuilder.create().build();

			HttpPost httpPost = new HttpPost(uri);
			httpPost.addHeader(oauthHeader);
			httpPost.addHeader(prettyPrintHeader);
			HttpClient httpClientGet = HttpClientBuilder.create().build();

			String uriGet = baseUri + "/query?q=Select+Id__c+From+Lead";
			System.out.println("Query URL: " + uriGet);
			HttpGet httpGet = new HttpGet(uriGet);
			httpGet.addHeader(oauthHeader);
			httpGet.addHeader(prettyPrintHeader);
			
			HttpResponse responseGet = httpClientGet.execute(httpGet);

			int leadSize = 0;
			int statusCodeGet = responseGet.getStatusLine().getStatusCode();
			if (statusCodeGet == 200) {
				String response_string = EntityUtils.toString(responseGet.getEntity());
				try {
					JSONObject json = new JSONObject(response_string);
					leadSize = (Integer) json.get("totalSize");
				} catch (JSONException je) {
					je.printStackTrace();
				}
			}
			JSONArray records = mapBean(leadXML,csvFileName);
			if (records != null) {
				for (int i = leadSize; i < records.length(); i++) {
					StringEntity body = new StringEntity(records.getJSONObject(i).toString());
					body.setContentType("application/json");
					httpPost.setEntity(body);
					HttpResponse response = httpClient.execute(httpPost);
					int statusCode = response.getStatusLine().getStatusCode();
					if (statusCode == 201) {
						String response_string = EntityUtils.toString(response.getEntity());
						JSONObject json = new JSONObject(response_string);
						leadId = json.getString("id");
						System.out.println("New Lead id from response: "+ leadId);
					} else {
						System.out.println("Insertion unsuccessful. Status code returned is "+ statusCode);
					}
				}
			} else {
				throw new SFDCException("No data received from CSV and XML");
			}
		} catch (JSONException e) {
			System.out.println("Issue creating JSON or processing results");
			e.printStackTrace();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		} catch (NullPointerException npe) {
			npe.printStackTrace();
		}
	}
	
	public static JSONArray mapBean(String xmlFile, String csvFile) throws SFDCException{
		JSONArray jsonArray = null;
		try {
			jsonArray = new JSONArray();
			XMLParser parser = new XMLParser(xmlFile);
			CSVUtils csvParser = new CSVUtils();
			List fields = parser.parseByList("Field");
			List values = csvParser.parseCSV(csvFile);
			String[][] data = new String[fields.size()][values.size()];
			Integer[] valuesCount = new Integer[values.size()];
			List<String> valueList = null;
			List csvValues = new ArrayList();
			for (int x = 0; x < values.size(); x++) {
				valueList = ((List<String>) values.get(x));
				valuesCount[x] = valueList.get(0).split(",").length;
				csvValues.add(Arrays.asList(valueList.get(0).split(",")));
			}
			for (int i = 0; i < values.size(); i++) {
				JSONObject json = new JSONObject();
				for (int j = 0; j < valuesCount[i]; j++) {
					json.put((String) fields.get(j),
							((List) csvValues.get(i)).get(j));
				}
				jsonArray.put(json);
			}
		} catch (SFDCException sfe) {
			sfe.printStackTrace();
		} catch(FileNotFoundException fne){
			fne.printStackTrace();
		} catch(JSONException je){
			je.printStackTrace();
		}
		return jsonArray;
	}

	private static class HttpPatch extends HttpPost {
		public HttpPatch(String uri) {
			super(uri);
		}

		public String getMethod() {
			return "PATCH";
		}
	}

	private static String getBody(InputStream inputStream) {
		String result = "";
		try {
			BufferedReader in = new BufferedReader(new InputStreamReader(
					inputStream));
			String inputLine;
			while ((inputLine = in.readLine()) != null) {
				result += inputLine;
				result += "\n";
			}
			in.close();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
		return result;
	}
}