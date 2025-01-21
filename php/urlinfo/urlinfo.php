<?php
/**
 * Simple PHP CLI wrapper around cURL
 * @package barabasz/urlinfo
 * @author Andrzej Barabasz <cellog@php.net>
 * @link https://github.com/barabasz/urlinfo
 * @version 1.0.2
 */

namespace barabasz\UrlInfo;

use Exception;

define("DEFAULT_SCHEME", "https");
define("VERSION", "1.0.2");
define("TIMEOUT", 2000);
define("MIN_PHP_VER", 8.2);
define("DATE_TIME", 'Y-m-d H:i e');
define("PHP_DEOL", PHP_EOL . PHP_EOL);
define("REDIRECT_CODES", [301, 302, 307, 308]);
define("USER_SYSTEM", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7");
define("USER_PLATFORM", "AppleWebKit/537.36 (KHTML, like Gecko)");
define("USER_BROWSER", "Chrome/115.0.0.0 Safari/537.36");
define("USER_AGENT", USER_SYSTEM . " " . USER_PLATFORM . " " . USER_BROWSER);
define("IPINFO_TOKEN", "");

/** @package barabasz\UrlInfo */
class Time
{
	public int $started;
	public int $finished;
	public int $elapsed;

	public function __construct()
	{
		$this->started = hrtime(true);
	}
	
	public function __destruct()
	{
		global $params;
		if ($params->time) echo $this->total();
	}

	/**
	 * Calculate script's total running time
	 * @return string 
	 */
	public function total(): string
	{
		$this->finished = hrtime(true);
		$this->elapsed = (int)(($this->finished - $this->started) / 1000);
		return colorLog("Script time:\t" . hrm($this->elapsed), 'c') . PHP_EOL;
	}
}

/** @package barabasz\UrlInfo */
readonly class Errors
{
	private string $error_message;

	public function error(string $error_type): void
	{
		match ($error_type) {
			'VERSION' => $this->error_message = "URLInfo version " . VERSION,
			'ONLY_ONE_ARGUMENT' => $this->error_message = "Too many arguments. Use -H for help.",
			'NO_ARGUMENT' => $this->error_message = "No URL specified. Use -H for help.",
			'INVALID_URL' => $this->error_message = "Incorrect URL.",
			'INVALID_SCHEME' => $this->error_message = "Only " . colorLog("http://", "i") . " and " . colorLog("https://", "i") . " schemes are allowed.",
			'CANNOT_PARSE_URL' => $this->error_message = "Cannot parse url.",
			'HELP' => $this->error_message = <<< HELP
			Usage: php urlinfo.php [options] URL
			
			Argument:
				URL     url to request
			Options:
				-b      show body (only for unencoded text/plain content)
				-c      print verbose cURL info (without SSL info)
				-f      ignore SSL errors
				-H      print this info and exit
				-h      print verbose response headers (without cookies and CSP)
				-i      print verbose ipinfo
				-m      mute standard output
				-p      force plain text content response (consider using with -b)
				-t      show script execution time
				-v      print version and exit
			HELP,
			default => $this->error_message = $error_type,
		};
		throw new \Exception($this->error_message . PHP_EOL);
	}

	public function print(string $exception): void
	{
		echo PHP_EOL . $exception;
	}

}

/** @package barabasz\UrlInfo */
readonly class Params
{ 
	public string $url;
	public bool $body;
	public bool $headers;
	public bool $help;
	public bool $ipinfo;
	public bool $curlinfo;
	public bool $mute;
	public bool $plaintext;
	public bool $forcessl;
	public bool $time;
	public bool $version;

	/**
	 * Read options/argument from CLI and assign internal flags
	 * @return void 
	 * @throws Exception 
	 */
	public function __construct()
	{
		global $argv;
		global $error;
		
		$rest_index = null;
		$short_options = "bcfHhimptv";
		$options = getopt($short_options, [], $rest_index);
		$pos_args = array_slice($argv, $rest_index);

		$this->body = !($options["b"] ?? true);
		$this->forcessl = !($options["f"] ?? true);
		$this->headers = !($options["h"] ?? true);
		$this->help = !($options["H"] ?? true);
		$this->ipinfo = !($options["i"] ?? true);
		$this->curlinfo = !($options["c"] ?? true);
		$this->mute = !($options["m"] ?? true);
		$this->plaintext = !($options["p"] ?? true);
		$this->time = !($options["t"] ?? true);
		$this->version = !($options["v"] ?? true);

		if ($this->version) {
			$error->error('VERSION');
		} elseif ($this->help) {
			$error->error('HELP');
		} elseif (count($pos_args) > 1) {
			$error->error('ONLY_ONE_ARGUMENT');
		} elseif (count($pos_args) < 1) {
			$error->error('NO_ARGUMENT');
		} else {
			$this->url = $pos_args[0];
		}
	}
}

/** @package barabasz\UrlInfo */
readonly class Url
{

	public string $final;

	public function __construct(string $url)
	{
		global $error;
		if (!parse_url($url, PHP_URL_SCHEME)) {
			$url = DEFAULT_SCHEME . '://' . $url;
		}
		if (!filter_var($url, FILTER_VALIDATE_URL)) {
			$error->error('INVALID_URL');
		}
		$components = parse_url($url) ?: [];
		if (empty($components)) {
			$error->error('CANNOT_PARSE_URL');
		}
		$scheme = mb_strtolower($components['scheme']);
		if ($scheme != "http" && $scheme != "https") {
			$error->error('INVALID_SCHEME');
		}
		$this->final = 
			$scheme . "://" .
			($components['host'] ?? '') .
			($components['path'] ?? '') .
			(isset($components['query']) ? "?" . $components['query'] : "") .
			(isset($components['fragment']) ? "#" . $components['fragment'] : "");
	}

}

/** @package barabasz\UrlInfo */
class CurlData
{
	public object $curlinfo;
	public object $headers;

	/**
	 * @global Error $error
	 * @global Params $params
	 * @param string $url 
	 * @return void 
	 * @throws Exception 
	 */
	public function __construct(string $url)
	{
		global $error, $params;
		$ch = curl_init();
		$headers = array(
			"Content-type: text/xml;charset=\"utf-8\"",
			"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
			"Accept-Language: en-GB,en-US;q=0.9,en;q=0.8,pl;q=0.7",
			"Cache-Control: no-cache",
			"Pragma: no-cache",
			"Referer: https://www.google.com/",
			"Sec-CH-UA-Platform: macOS",
			"Sec-Fetch-Dest: document",
			"Sec-Fetch-Mode: navigate",
			"Sec-Fetch-Site: cross-site",
			"Sec-Fetch-User: ?1"
		);
		if (!$params->plaintext) {
			array_unshift($headers, "Accept-Encoding: br;q=1.0, gzip;q=0.8, deflate;q=0.6, compress;q=0.4, *;q=0.1");
		}

		$options = array(
			CURLOPT_URL => $url,
			CURLOPT_HEADER => true,
			CURLOPT_CERTINFO => true,
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_USERAGENT => USER_AGENT,
			CURLOPT_CONNECTTIMEOUT => 2,
			CURLOPT_HTTPHEADER => $headers,
		);
		if ($params->forcessl) {
			$options[CURLOPT_SSL_VERIFYPEER] = false;
		}
		curl_setopt_array($ch, $options);
		$response = curl_exec($ch);
		if(!$response) $error->error(curl_error($ch));
		curl_close($ch);
		$this->curlinfo = (object)curl_getinfo($ch);

		if (empty($this->curlinfo->redirect_url)) {
			$this->get_headers_arr($response, $this->curlinfo->header_size);
			if ($params->body && !isset($this->curlinfo->headers->content_encoding)) {
				$this->get_body($response, $this->curlinfo->header_size);
			}
			$this->get_ipinfo($this->curlinfo->primary_ip);
			$this->curlinfo->isRedirect = false;
		} else {
			$this->curlinfo->isRedirect = true;
		}
	}

	/**
	 * Create object from response headers
	 * @param string $response 
	 * @param int $header_size 
	 * @return void 
	 */
	private function get_headers_arr(string $response, int $header_size): void
	{
		$headers = substr($response, 0, $header_size);
		$headers_indexed_arr = array_filter(explode("\r\n", $headers));
		$headers_indexed_arr[0] = 'status: ' . $headers_indexed_arr[0];
		$this->curlinfo->headers = new \stdClass();
		foreach ($headers_indexed_arr as $value) {
			if(false !== ($matches = explode(':', $value, 2))) {
				$this->curlinfo->headers->{strtolower(str_replace('-', '_', $matches[0]))} = trim($matches[1]);
			}
		}
	}

	/**
	 * Extract body from curl response
	 * @param string $response 
	 * @param int $header_size 
	 * @return void 
	 */
	private function get_body(string $response, int $header_size): void
	{
		$body = substr($response, $header_size);
		$this->curlinfo->body = $body;
	}

	/**
	 * Get IP info (via ipinfo.io API)
	 * @param string $ip 
	 * @return void 
	 */
	private function get_ipinfo(string $ip): void
	{
		$ipinfo_url = "https://ipinfo.io/" . $ip . "?token=" . IPINFO_TOKEN;
		$scc = stream_context_create(
			['http'=>['timeout' => 1, 'ignore_errors' => true]]
		);
		$ipinfo_response = @file_get_contents($ipinfo_url, false, $scc);
		$ipinfo = json_decode($ipinfo_response);
		$this->curlinfo->ipinfo = $ipinfo;
	}
}

/** @package barabasz\UrlInfo */
readonly class PrintData
{
	public bool $isRedirect;

	public function __construct(object $data)
	{
		global $params;
		global $error;

		echo PHP_EOL;
		if (!$data->isRedirect) {
			echo $this->verboseInfo($data);
		}
		if (!$params->mute) {
			echo $this->requestInfo($data);
			echo $this->connectionInfo($data);
			echo $this->responseInfo($data);
			if ($data->isRedirect) {
				echo PHP_EOL . colorLog("Redirecting...", "c") . PHP_EOL;
			} 
			if ($data->http_code == 200) {
				echo $this->ipinfoInfo($data->ipinfo);
				echo $this->serverInfo($data->headers);
				echo $this->proxyInfo($data->headers);
				echo $this->cacheInfo($data->headers);
				if (strtolower($data->scheme) == "https") {
					echo $this->sslInfo($data);
				}
				echo $this->serverFlags($data->headers);
				echo $this->contentInfo($data);
				echo $this->speedInfo($data);
			}
		}
	}

	/**
	 * Prepare additional output (cURL data, headers, IPinfo response and body)
	 * @param object $data 
	 * @return string|bool 
	 */
	private function verboseInfo(object $data): string|bool
	{
		global $params;
		$info = false;
		if ($params->curlinfo) {
			$cdata = clone $data;
			$info .= colorLog("cURL info:", 'be') . PHP_DEOL;
			unset($cdata->body, $cdata->isRedirect, $cdata->certinfo, $cdata->headers, $cdata->ipinfo);
			$info .= parse_object($cdata) . PHP_EOL;
			unset($cdata);
		}
		if ($params->headers) {
			$hdata = clone $data;
			$info .= colorLog("Response headers:", 'be') . PHP_DEOL;
			unset($hdata->headers->set_cookie, $hdata->headers->content_security_policy);
			$info .= parse_object($hdata->headers) . PHP_EOL;
			unset($hdata);
		}
		if ($params->ipinfo) {
			$idata = clone $data;
			$info .= colorLog("IP info response:", 'be') . PHP_DEOL;
			$info .= parse_object($idata->ipinfo) . PHP_EOL;
			unset($idata);
		}
		if ($params->body) {
			$info .= colorLog("Body content:", 'be');
			if (isset($data->body)) {
				$info .= PHP_DEOL . $data->body . PHP_DEOL;
			} else {
				$info .= "\t" . "encoded with " . colorLog($data->headers->content_encoding, 'w') . PHP_EOL;
			}
		}
		return $info;
	}

	/**
	 * Format IP info
	 * @param mixed $data 
	 * @return string 
	 */
	private function ipinfoInfo($data): string
	{
		$info = "IP info:\t";
		if (isset($data->error)) {
			$info .= colorLog('API error ' . $data->status . ': ' . $data->error->title, 'e');
		} elseif ($data->bogon ?? false) {
			$info .= 'private class bogon IP';
		} else {
			$info .= "company " . colorLog($data->org, 'w');
			$info .= " from " . colorLog($data->city, 'w');
			$info .= " (" . $data->region . ', ' . $data->country . ")";
		}

		if (isset($data->hostname)) {
			$info .= PHP_EOL . "IP hostname:\t" . colorLog($data->hostname, 'w');
		}

		return $info . PHP_EOL;
	}

	/**
	 * Format server info
	 * @param object $data 
	 * @return string|bool 
	 */
	private function serverInfo(object $data): string|bool
	{
		if (isset($data->server) || isset($data->date)) {
			$info = "Server info:\t";
			if (isset($data->server) && !empty($data->server)) $info .= 'name ' . colorLog($data->server, 'w') . ' ';
			if (isset($data->date)) $info .= 'date ' . colorLog(date(DATE_TIME, strtotime($data->date)), 'w');
			return $info . PHP_EOL;
		} else {
			return false;
		}
	}

	/**
	 * Format proxy info
	 * @param object $data 
	 * @return string|bool 
	 */
	private function proxyInfo(object $data): string|bool
	{
		if (isset($data->via)) {
			$info = "Proxy info:\t";
			if (isset($data->via)) $info .= 'via ' . colorLog($data->via, 'w') . ' ';
			return $info . PHP_EOL;
		} else {
			return false;
		}
	}

	/**
	 * Format server flags
	 * @param object $data 
	 * @return string|bool 
	 */
	private function serverFlags(object $data): string|bool
	{
		if (isset($data->strict_transport_security) || isset($data->x_frame_options)) {
			$info = "Other flags:\t";
			if (isset($data->strict_transport_security)) $info .= "HSTS " . colorLog($data->strict_transport_security, 'w') . ' ';
			if (isset($data->x_frame_options)) $info .= "X-Frame-Options " . colorLog(strtolower($data->x_frame_options), 'w');
			return $info . PHP_EOL;
		} else {
			return false;
		}
	}

	/**
	 * Format cache info
	 * @param object $data 
	 * @return string|bool 
	 */
	private function cacheInfo(object $data): string|bool
	{
		if (isset($data->cache_control) || isset($data->pragma)) {
			$info = "Cache info:\t";
			if (isset($data->cache_control)) $info .= "cache control " . colorLog($data->cache_control, 'w') . ' ';
			if (isset($data->pragma)) $info .= "pragma " . colorLog($data->pragma, 'w');
			return $info . PHP_EOL;
		} else {
			return false;
		}
	}

	/**
	 * Format connection info
	 * @param object $data 
	 * @return string 
	 */
	private function connectionInfo(object $data): string
	{
		$info = "Connection:\t";
		$info .= colorLog($data->local_ip, "w") . ":" . colorLog($data->local_port, "w") . " → ";
		if ($data->scheme == "HTTP") {
			$info .= colorLog('HTTP', "be") . "/" . $data->http_version . " → ";
		} elseif ($data->scheme == "HTTPS") {
			$info .= colorLog('HTTPS', "bs") . "/" . $data->http_version . " → ";
		} else {
			$info .= " → ";
		}
		$info .= colorLog($data->primary_ip, "w") . ":" . colorLog($data->primary_port, "w"). PHP_EOL;
		return $info;
	}

	/**
	 * Extract data from SSL info
	 * @param string $name 
	 * @param string $field 
	 * @return string 
	 */
	private function parseSslName(string $name, string $field): string
	{
		$re = '/([^\s=]+)\s*=\s*([^,]*)/';
		$str = $name;
		$arr = [];
		$str = preg_replace_callback ($re,
			function ($matches) use (&$arr) {
				$arr[$matches[1]] = $matches[2];
				return null;
			},
			$str
		);
		return $arr[$field];
	}
	
	/**
	 * Formal SSL info
	 * @param object $data 
	 * @return string 
	 */
	private function sslInfo(object $data): string
	{
		$subject = colorLog($this->parseSslName($data->certinfo[0]["Subject"], 'CN'), "w");
		$issuer = colorLog($this->parseSslName($data->certinfo[0]["Issuer"], 'CN'), "w");
		$until = strtotime($data->certinfo[0]["Expire date"]);
		if ($until < time()) {
			$until = colorLog(date(DATE_TIME, $until), 'be');
		} else {
			$until = colorLog(date(DATE_TIME, $until), 'w');
		}
		$from = strtotime($data->certinfo[0]["Start date"]);
		$from = colorLog(date(DATE_TIME, $from), 'w');
		$info = "SSL subject:\t" . "for " . $subject . " by " . $issuer . PHP_EOL;
		$info .= "SSL validity:\t" . "from " . $from . " until " . $until . PHP_EOL;
		return $info;
	}

	/**
	 * Format request info
	 * @param object $data 
	 * @return string 
	 */
	private function requestInfo(object $data): string
	{
		$requestedUrl = (strlen($data->url) > 80) ? substr($data->url, 0, 80) . "[...]" : $data->url;
		return "Request:\t" . $data->effective_method . ": " . colorLog($requestedUrl, "l") . PHP_EOL;
	}

	/**
	 * Format response info
	 * @param object $data 
	 * @return string 
	 */
	private function responseInfo(object $data): string
	{
		$response = "Response:\t";
		if (isset($data->redirect_url)) {
			$redirectUrl = (strlen($data->redirect_url) > 80) ? substr($data->redirect_url, 0, 85) . "[...]" : $data->redirect_url;
		}
		$response .= match ($data->http_code) {
			200 => colorLog($data->http_code, "bs") . " OK",
			301 => colorLog($data->http_code, "bw") . " Moved Permanently",
			302 => colorLog($data->http_code, "bw") . " Moved Temporarily",
			304 => colorLog($data->http_code, "bs") . " Not Modified",
			307 => colorLog($data->http_code, "bw") . " Permanent Redirect",
			308 => colorLog($data->http_code, "bw") . " Moved Temporarily",
			400 => colorLog($data->http_code, "be") . " Bad Request",
			401 => colorLog($data->http_code, "be") . " Unauthorized",
			403 => colorLog($data->http_code, "be") . " Forbidden",
			404 => colorLog($data->http_code, "be") . " Not Found",
			500 => colorLog($data->http_code, "be") . " Server Error",
			502 => colorLog($data->http_code, "be") . " Bad Gateway",
			504 => colorLog($data->http_code, "be") . " Gateway Timeout",
		default => colorLog($data->http_code, "be")
		};
		$response .= (isset($data->headers->status)) ? ' (' . $data->headers->status . ')' : '';
		$response .= ($data->isRedirect) ? (PHP_EOL ."Redirection:\t" . colorLog($redirectUrl, "l")) : '';
		return $response . PHP_EOL;
	}

	/**
	 * Format content info
	 * @param object $data 
	 * @return string 
	 */
	private function contentInfo(object $data): string
	{
		global $params;

		if (strpos($data->content_type, ';') > 0) {
			$charset = ' charset ';
			$str_indexed_arr = array_filter(explode(";", $data->content_type));
			$type = colorLog($str_indexed_arr[0], 'w');
			if (count($str_indexed_arr) > 1) {
				if (strpos($str_indexed_arr[1], '=') > 0) {
					$charset .= colorLog(substr($str_indexed_arr[1], strpos($str_indexed_arr[1], '=') + 1), 'w');
				}
			}
		} else {
			$type = colorLog($data->content_type, 'w');
		}

		if ($data->size_download > 1000) {
			$size = colorLog(hrb($data->size_download, 2), 'w');
		} else {
			$size = colorLog(hrb($data->size_download, 2), 'be');
		}
		$speed = colorLog(hrb($data->speed_download, 2) . '/s', 'w');

		$info = "Content type:\t" . $type . ($charset ?? '');
		if (isset($data->headers->content_encoding)) {
			$encoding = match ($data->headers->content_encoding) {
				'gzip'      => colorLog('gzip', 'w') . ' (LZ77 with CRC)',
				'compress'  => colorLog('compress', 'w') . ' (LZW)',
				'deflate'   => colorLog('deflate', 'w') . ' (zlib with deflate)',
				'br'        => colorLog('br', 'w') . ' (Brotli)',
				default     => $data->content_encoding,
			};
			$info .= " encoded with " . colorLog($encoding, 'w');
		} else {
			$info .= " as " . colorLog('plain text', 'w');
			if ($params->plaintext) $info .= " (" . colorLog('forced', 'e') . ")";
		}
		$info .= PHP_EOL . "Content size:\t" . $size;
		$info .= " downloaded at " . $speed . PHP_EOL;
		return $info;
	}

	/**
	 * Format speed info (lookup, handshakes, transfers)
	 * @param object $data 
	 * @return string 
	 */
	private function speedInfo(object $data): string
	{
		$namelookup    = $data->namelookup_time_us;
		$tcpconnect    = $data->connect_time_us;
		$appconnect    = $data->appconnect_time_us;
		$pretransfer   = $data->pretransfer_time_us;
		$starttransfer = $data->starttransfer_time_us;
		$totaltime     = $data->total_time_us;

		$tcphandshake  = $tcpconnect - $namelookup;
		$sslhandshake  = $appconnect - $tcpconnect;
		$ttfb          = $starttransfer - $pretransfer;
		$transfer      = $totaltime - $starttransfer;

		if ($namelookup > 100000) {
			$namelookup = colorLog(hrm($namelookup), 'be');
		} else {
			$namelookup = colorLog(hrm($namelookup), 'w');
		}

		if ($tcphandshake > 200000) {
			$tcphandshake = colorLog(hrm($tcphandshake), 'be');
		} else {
			$tcphandshake = colorLog(hrm($tcphandshake), 'w');
		}

		if ($sslhandshake > 200000) {
			$sslhandshake = colorLog(hrm($sslhandshake), 'be');
		} else {
			$sslhandshake = colorLog(hrm($sslhandshake), 'w');
		}

		if ($ttfb > 500000) {
			$ttfb = colorLog(hrm($ttfb), 'be');
		} else {
			$ttfb = colorLog(hrm($ttfb), 'w');
		}
		$transfer = colorLog(hrm($transfer), 'w');
		$totaltime = colorLog(hrm($totaltime), 'w');

		$info = "Pretransfer:\t";
		$info .= "DNS lookup " . $namelookup;
		$info .= " TCP handshake " . $tcphandshake;
		if (strtolower($data->scheme) == "https") {
			$info .= " SSL handshake " . $sslhandshake;
		} else {
			$info .= " no SSL handshake (HTTP)";
		}
		$info .= PHP_EOL . "Transfer:\t";
		$info .= "time to first byte " . $ttfb;
		$info .= " transfer time " . $transfer;
		$info .= " total time " . $totaltime;
		return $info . PHP_EOL;
	}
}

/**
 * AUXILIARY FUNCTIONS
 */

/**
 * hrm - Human Readable Microseconds
 * Convert microseconds into μs / ms / s
 * @param int $microseconds
 * @return string 
 */
function hrm(int $microseconds): string
{
	$decimals = match (true) {
		$microseconds > 1000000 => 2,
		$microseconds > 1000 => 1,
		default => 0,
	};
	$units = array('μs', 'ms', 's');
	$factor = floor((strlen($microseconds) - 1) / 3);
	return sprintf("%.{$decimals}f %s", $microseconds / pow(1000, $factor), $units[$factor]);
}

/**
 * hmb - Human Readable Bytes
 * Convert bytes into multiple binary/metric units
 * @param int $bytes 
 * @param int $decimals 
 * @param string $system 
 * @return string 
 */
function hrb(int $bytes, int $decimals = 2, $system = 'binary'): string
{
	$mod = ($system === 'binary') ? 1024 : 1000;
	if ($bytes > $mod) {
		$units = array(
			'binary' => array('B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB','YiB',),
			'metric' => array('B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB',),
		);
		$factor = floor((strlen($bytes) - 1) / 3);
		return sprintf("%.{$decimals}f %s", $bytes / pow($mod, $factor), $units[$system][$factor]);
	} else {
		return "$bytes B";
	}
}

/**
 * Simple function for printing objects
 * @param object $obj 
 * @return string 
 */
function parse_object(object $obj): string
{
	$output = '';
	foreach ($obj as $key => $val) {
		$key = ucwords(str_replace('_', ' ', $key));
		$output .= $key . ": " . colorLog($val, 'w') . PHP_EOL;
	}
	return $output;
}


/**
 * Color CLI output with ANSI escape sequences 
 * @param string $str 
 * @param string $type 
 * @return string 
 */
function colorLog(string $str, string $type = 'i'): string
{
	$bold   = "\033[1m";
	$underl = "\033[4m";

	$clear  = "\033[0m";
	$cyan   = "\033[36m";
	$gray   = "\033[38;5;238m";
	$green  = "\033[32m";
	$red    = "\033[31m";
	$yellow = "\033[33m";
	
	return match ($type) {
		'b'  => "$bold$str$clear",          //bold
		'e'  => "$red$str$clear",           //error
		'be' => "$bold$red$str$clear",      //bold error
		's'  => "$green$str$clear",         //success
		'bs' => "$bold$green$str$clear",    //bold success
		'w'  => "$yellow$str$clear",        //warning
		'bw' => "$bold$yellow$str$clear",   //bold warning
		'i'  => "$cyan$str$clear",          //info
		'bi' => "$bold$cyan$str$clear",     //bold info
		'l'  => "$underl$cyan$str$clear",   //link
		'c'  => "$gray$str$clear",          //comment
		default => $str,
	};
}

/*
MAIN PROGRAM
*/

try {
	$error = new Errors();
	$params = new Params();
	$time = new Time();
	do {
		$url = new Url($data->curlinfo->redirect_url ?? $params->url);
		$data = new CurlData($url->final);
		$print = new PrintData($data->curlinfo);
	} while ($data->curlinfo->isRedirect);
} catch (\Exception $e) {
	$error->print($e->getMessage());
}
