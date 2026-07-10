<?php
/* vim: set noexpandtab tabstop=2 softtabstop=2 shiftwidth=2: */

/**
 * Builds an easy structured array out of a xml file.
 * Element names will be the keys and the data the values.
 *
 * Updated by Xymph
 */
class Examsly {
	private $struct;
	private $stack;
	private $utf8enc;

	/**
	 * Parses a XML structure into an array.
	 */
	function parseXml($source, $isfile = true, $utf8enc = false) {

		// clear last results
		$this->stack = array();
		$this->struct = array();
		$this->utf8enc = $utf8enc;

		// load the xml file
		if ($isfile) {
			$data = file_get_contents($source);
			if ($data === false) {
				trigger_error("[XML Error] Unable to read file $source", E_USER_WARNING);
				return false;
			}
		} else {
			$data = $source;
		}

		// escape '&' characters
		$data = str_replace('&', '<![CDATA[&]]>', $data);

		// create the parser
		$parser = xml_parser_create();
		xml_set_object($parser, $this);
		xml_set_element_handler($parser, 'openTag', 'closeTag');
		xml_set_character_data_handler($parser, 'tagData');

		// parse xml file
		$parsed = xml_parse($parser, $data);

		// display errors
		if (!$parsed) {
			$code = xml_get_error_code($parser);
			$err = xml_error_string($code);
			$line = xml_get_current_line_number($parser);

			// Destruct parser, due to PHP7 bug, we also need to release the resource by unset
			xml_parser_free($parser);
			unset($parser);
			trigger_error("[XML Error $code] $err on line $line", E_USER_WARNING);
			return false;
		}

		// Destruct parser, due to PHP7 bug, we also need to release the resource by unset
		xml_parser_free($parser);
		unset($parser);
		return $this->struct;
	}

	private function openTag($parser, $name, $attributes) {
		$this->stack[] = $name;
		$this->struct[$name] = '';
	}

	private function tagData($parser, $data) {
		if (trim($data) !== "") {
			$index = $this->stack[count($this->stack) - 1];
			// use raw, don't decode '+' into space
			//if (is_array($this->struct[$index]) && empty($this->struct[$index]))
			//	$this->struct[$index] = '';
			if ($this->utf8enc) {
				$this->struct[$index] .= rawurldecode($data);
			} else {
				$this->struct[$index] .= mb_convert_encoding(rawurldecode($data), 'ISO-8859-1', 'UTF-8');
			}
		}
	}

	private function closeTag($parser, $name) {
		if (count($this->stack) > 1) {
			$from = array_pop($this->stack);
			$to = $this->stack[count($this->stack) - 1];

			$top = $this->struct[$from];
			if (!is_array($this->struct[$to])) {
				$this->struct[$to] = array();
			}
			if (!isset($this->struct[$to][$from]) || !is_array($this->struct[$to][$from])) {
				$this->struct[$to][$from] = array();
			}
			$this->struct[$to][$from][] = $top;
			unset($this->struct[$from]);
		}
	}
}

