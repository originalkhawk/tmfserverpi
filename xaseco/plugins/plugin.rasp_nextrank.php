<?php
/* vim: set noexpandtab tabstop=2 softtabstop=2 shiftwidth=2: */

/**
 * Nextrank plugin.
 * Shows the next better ranked player.
 * Created by Xymph
 *
 * Dependencies: none
 */

Aseco::addChatCommand('nextrank', 'Shows the next better ranked player');

function chat_nextrank($aseco, $command) {
	global $rasp, $minrank, $feature_ranks, $nextrank_show_rp;

	$login = $command['author']->login;

	// check for relay server
	if ($aseco->server->isrelay) {
		$message = formatText($aseco->getChatMessage('NOTONRELAY'));
		$aseco->client->query('ChatSendServerMessageToLogin', $aseco->formatColors($message), $login);
		return;
	}

	if ($feature_ranks) {
		// find current player's avg
		$query = 'SELECT avg FROM rs_rank
		          WHERE playerID=' . $command['author']->id;
		$res = $aseco->db->query($query);

		if ($res->num_rows > 0) {
			$row = $res->fetch_array();
			$avg = $row['avg'];

			// find players with better avgs
			$query = 'SELECT playerid,avg FROM rs_rank
			          WHERE avg<' . $avg . ' ORDER BY avg';
			$res2 = $aseco->db->query($query);

			if ($res2->num_rows > 0) {
				// find last player before current one
				while ($row2 = $res2->fetch_array()) {
					$pid = $row2['playerid'];
					$avg2 = $row2['avg'];
				}

				// obtain next player's info
				$query = 'SELECT login,nickname FROM players
				          WHERE id=' . $pid;
				$res3 = $aseco->db->query($query);
				$row3 = $res3->fetch_array();

				$rank = $rasp->getRank($row3['login']);
				$rank = preg_replace('|^(\d+)/|', '{#rank}$1{#record}/{#highlite}', $rank);

				// show chat message
				$message = formatText($rasp->messages['NEXTRANK'][0],
				                      stripColors($row3['nickname']), $rank);
				// show difference in record positions too?
				if ($nextrank_show_rp) {
					// compute difference in record positions
					$diff = ($avg - $avg2) / 10000 * $aseco->server->gameinfo->numchall;
					$message .= formatText($rasp->messages['NEXTRANK_RP'][0], ceil($diff));
				}
				$aseco->client->query('ChatSendServerMessageToLogin', $aseco->formatColors($message), $login);
				$res3->free();
			} else {
				$message = $rasp->messages['TOPRANK'][0];
				$aseco->client->query('ChatSendServerMessageToLogin', $aseco->formatColors($message), $login);
			}
			$res2->free();
		} else {
			$message = formatText($rasp->messages['RANK_NONE'][0], $minrank);
			$aseco->client->query('ChatSendServerMessageToLogin', $aseco->formatColors($message), $login);
		}
		$res->free();
	}
}  // chat_nextrank
?>
