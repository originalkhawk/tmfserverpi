#!/usr/bin/php -q
<?php
// vim: set noexpandtab tabstop=2 softtabstop=2 shiftwidth=2:

// Update a panel setting for all players in a XASECO[2] database
// Created Sep 2011 by Xymph <tm@gamers.org>

	$panelpath = '/home/tmf/aseco/panels';

	if (!isset($argv[1]) || !isset($argv[2])) {
		echo 'usage: ' . basename($argv[0]) . ' {admin|donate|records|vote} PanelName' . "\n";
		exit;
	}
	if (!file_exists($panelpath)) {
		echo "Panel path '$panelpath' not found\n";
		exit;
	}
	if ($argv[1] != 'admin' && $argv[1] != 'donate' &&
	    $argv[1] != 'records' && $argv[1] != 'vote') {
		echo "unknown panel type\n";
		exit;
	}
	$panelpath = rtrim($panelpath, '/');
	if (!file_exists($panelpath . '/' . ucfirst($argv[1]) . $argv[2] . '.xml')) {
		echo "unknown panel name\n";
		exit;
	}

	if (!$aseco->db = new mysqli('localhost','YOUR_MYSQL_LOGIN','YOUR_MYSQL_PASSWORD')) {
		echo "could not connect\n";
		exit;
	}
	if (!$aseco->db->select_db('aseco')) {
		echo "could not select\n";
		exit;
	}

	$query = 'SELECT PlayerID,Panels FROM players_extra ORDER BY PlayerID';
	$resply = $aseco->db->query($query);

	if ($resply->num_rows > 0) {
		echo 'Updating players_extra entries: ' . $resply->num_rows . " ...\n";

		while ($rowply = $resply->fetch_object()) {
			$panels = explode('/', $rowply->Panels);
			switch ($argv[1]) {
			case 'admin':
				$panels[0] = ucfirst($argv[1]) . $argv[2];
				break;
			case 'donate':
				$panels[1] = ucfirst($argv[1]) . $argv[2];
				break;
			case 'records':
				$panels[2] = ucfirst($argv[1]) . $argv[2];
				break;
			case 'vote':
				$panels[3] = ucfirst($argv[1]) . $argv[2];
				break;
			}

			$query = "UPDATE players_extra SET Panels = '" . implode('/', $panels) . "' WHERE PlayerID = " . $rowply->PlayerID;
			$result = $aseco->db->query($query);
			if ($aseco->db->affected_rows == -1) {
				$resply->free();
				echo "couldn't update panels for player ID " . $rowply->PlayerID . ":\n";
				echo $aseco->db->error . "\n";
				exit;
			}
		}
		echo "Done\n";

		$resply->free();
	} else {
		echo "no players_extra!\n";
	}
?>
