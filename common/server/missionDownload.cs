//-----------------------------------------------------------------------------
// Torque Game Engine 
// Copyright (C) GarageGames.com, Inc.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Mission Loading
// The server portion of the client/server mission loading process
//-----------------------------------------------------------------------------

//--------------------------------------------------------------------------
// Loading Phases:
// Phase 1: Transmit Datablocks
//          Transmit targets
// Phase 2: Transmit Ghost Objects
// Phase 3: Start Game
//
// The server invokes the client MissionStartPhase[1-3] function to request
// permission to start each phase.  When a client is ready for a phase,
// it responds with MissionStartPhase[1-3]Ack.

function GameConnection::loadMission(%this)
{
   // Send over the information that will display the server info
   // when we learn it got there, we'll send the data blocks
   %this.currentPhase = 0;

   echo("### loadMission - client=" @ %this @ " missionSeq=" @ $missionSequence @ " missionRunning=" @ $missionRunning);

   if (%this.isAIControlled())
   {
      // Cut to the chase...
      %this.onClientEnterGame();
   }
   else
   {
      echo("### MissionStartPhase1 params: seq=" @ $missionSequence @ " file=" @ $Server::MissionFile @ " music=" @ MissionGroup.musicTrack);
      commandToClient(%this, 'MissionStartPhase1', $missionSequence,
         $Server::MissionFile, MissionGroup.musicTrack);
      echo("*** Sending mission load to client: " @ $Server::MissionFile);

      // BYPASS: Try to proceed without waiting for Phase1Ack
      // This simulates what happens when Phase1Ack is received
      echo("### BYPASS: Proceeding without Phase1Ack after 2 seconds");
      %this.schedule(2000, "bypassPhase1", $missionSequence);
   }
}

// BYPASS function - proceed as if Phase1Ack was received
function GameConnection::bypassPhase1(%this, %seq)
{
   echo("### bypassPhase1 called - client=" @ %this @ " seq=" @ %seq @ " currentPhase=" @ %this.currentPhase);

   // Only proceed if we haven't already moved past phase 0
   if (%this.currentPhase != 0)
   {
      echo("### bypassPhase1 - already past phase 0, skipping");
      return;
   }

   if (%seq != $missionSequence || !$MissionRunning)
   {
      echo("### bypassPhase1 - seq mismatch or not running, skipping");
      return;
   }

   echo("### bypassPhase1 - proceeding with mission load");
   %this.currentPhase = 1;

   // Start with the CRC
   %this.setMissionCRC($missionCRC);

   // Skip datablocks, go to phase 1.5
   %this.currentPhase = 1.5;

   // Send Phase 2
   echo("### bypassPhase1 - sending Phase2");
   commandToClient(%this, 'MissionStartPhase2', $missionSequence, $Server::MissionFile);

   // Schedule server-driven Phase2 progression in case client doesn't respond
   %this.schedule(2000, "serverDrivenPhase2", $missionSequence);
}

// Server-driven Phase2 - proceed without waiting for Phase2Ack
function GameConnection::serverDrivenPhase2(%this, %seq)
{
   echo("### serverDrivenPhase2 called - client=" @ %this @ " seq=" @ %seq @ " currentPhase=" @ %this.currentPhase);

   // Only proceed if we haven't already moved past phase 1.5
   if (%this.currentPhase != 1.5)
   {
      echo("### serverDrivenPhase2 - not at phase 1.5 (at " @ %this.currentPhase @ "), skipping");
      return;
   }

   if (%seq != $missionSequence || !$MissionRunning)
   {
      echo("### serverDrivenPhase2 - seq mismatch or not running, skipping");
      return;
   }

   echo("### serverDrivenPhase2 - proceeding with ghosting");
   %this.currentPhase = 2;

   // Update mod paths, this needs to get there before the objects.
   %this.transmitPaths();

   // Start ghosting objects to the client
   %this.activateGhosting();
}

// Server-driven Phase3 - proceed without waiting for Phase3Ack
function GameConnection::serverDrivenPhase3(%this, %seq)
{
   echo("### serverDrivenPhase3 called - client=" @ %this @ " seq=" @ %seq @ " currentPhase=" @ %this.currentPhase);

   // Only proceed if we haven't already moved past phase 2
   if (%this.currentPhase != 2)
   {
      echo("### serverDrivenPhase3 - not at phase 2 (at " @ %this.currentPhase @ "), skipping");
      return;
   }

   if (%seq != $missionSequence || !$MissionRunning)
   {
      echo("### serverDrivenPhase3 - seq mismatch or not running, skipping");
      return;
   }

   echo("### serverDrivenPhase3 - entering game");
   %this.currentPhase = 3;

   // Server is ready to drop into the game
   %this.startMission();
   %this.onClientEnterGame();
}

function serverCmdMissionStartPhase1Ack(%client, %seq)
{
   echo("### serverCmdMissionStartPhase1Ack - client=" @ %client @ " seq=" @ %seq @ " missionSeq=" @ $missionSequence @ " running=" @ $MissionRunning);
   // Make sure to ignore calls from a previous mission load
   if (%seq != $missionSequence || !$MissionRunning)
      return;
   if (%client.currentPhase != 0)
      return;
   %client.currentPhase = 1;
   echo("### Phase1Ack accepted, moving to phase 1");

   // Start with the CRC
   %client.setMissionCRC( $missionCRC );

   // Send over the datablocks...
   // OnDataBlocksDone will get called when have confirmation
   // that they've all been received.
   //%client.transmitDataBlocks($missionSequence);
 
  //skipping ahead
   %client.currentPhase = 1.5;

   // On to the next phase
   commandToClient(%client, 'MissionStartPhase2', $missionSequence, $Server::MissionFile);

   // Schedule server-driven Phase2 progression in case client doesn't respond
   %client.schedule(2000, "serverDrivenPhase2", $missionSequence);
}

function GameConnection::onDataBlocksDone( %this, %missionSequence )
{
   // Make sure to ignore calls from a previous mission load
   if (%missionSequence != $missionSequence)
      return;
   if (%this.currentPhase != 1)
      return;
   %this.currentPhase = 1.5;

   // On to the next phase
   commandToClient(%this, 'MissionStartPhase2', $missionSequence, $Server::MissionFile);

   // Schedule server-driven Phase2 progression in case client doesn't respond
   %this.schedule(2000, "serverDrivenPhase2", $missionSequence);
}

function serverCmdMissionStartPhase2Ack(%client, %seq)
{
   echo("### serverCmdMissionStartPhase2Ack - client=" @ %client @ " seq=" @ %seq);
   // Make sure to ignore calls from a previous mission load
   if (%seq != $missionSequence || !$MissionRunning)
      return;
   if (%client.currentPhase != 1.5)
      return;
   %client.currentPhase = 2;
   echo("### Phase2Ack accepted, starting ghosting");

   // Update mod paths, this needs to get there before the objects.
   %client.transmitPaths();

   // Start ghosting objects to the client
   %client.activateGhosting();
   
}

function GameConnection::clientWantsGhostAlwaysRetry(%client)
{
   if($MissionRunning)
      %client.activateGhosting();
}

function GameConnection::onGhostAlwaysFailed(%client)
{

}

function GameConnection::onGhostAlwaysObjectsReceived(%client)
{
   echo("### onGhostAlwaysObjectsReceived - sending Phase3");
   // Ready for next phase.
   commandToClient(%client, 'MissionStartPhase3', $missionSequence, $Server::MissionFile);

   // Schedule server-driven Phase3 progression in case client doesn't respond
   %client.schedule(2000, "serverDrivenPhase3", $missionSequence);
}

function serverCmdMissionStartPhase3Ack(%client, %seq)
{
   echo("### serverCmdMissionStartPhase3Ack - client=" @ %client @ " seq=" @ %seq);
   // Make sure to ignore calls from a previous mission load
   if(%seq != $missionSequence || !$MissionRunning)
      return;
   if(%client.currentPhase != 2)
      return;
   %client.currentPhase = 3;
   echo("### Phase3Ack accepted, calling startMission and onClientEnterGame");

   // Server is ready to drop into the game
   %client.startMission();
   %client.onClientEnterGame();
}
