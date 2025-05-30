// acting agent

/* Initial beliefs and rules */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start
    :  true
    <-  .print("Hello world");
    !send_witness_reputation
    .

/* 
 * Plan for reacting to the addition of the belief organization_deployed(OrgName)
 * Triggering event: addition of belief organization_deployed(OrgName)
 * Context: true (the plan is always applicable)
 * Body: joins the workspace and the organization named OrgName
*/
@organization_deployed_plan
+organization_deployed(OrgName)
    :  true
    <-  .print("Notified about organization deployment of ", OrgName);
        // joins the workspace
        joinWorkspace(OrgName);
        // looks up for, and focuses on the OrgArtifact that represents the organization
        lookupArtifact(OrgName, OrgId);
        focus(OrgId);
    .

/* 
 * Plan for reacting to the addition of the belief available_role(Role)
 * Triggering event: addition of belief available_role(Role)
 * Context: true (the plan is always applicable)
 * Body: adopts the role Role

@available_role_plan
+available_role(Role)
    : true
    <-  .print("Adopting the role of ", Role);
        adoptRole(Role);
    .
*/
+available_role(Role)
    :  (playing_role(temperature_manifestor) & Role == temperature_reader)
    |  (playing_role(temperature_reader) & Role == temperature_manifestor)
    <-  .print("Skipping adoption of incompatible role: ", Role).



/* 
 * Plan for reacting to the addition of the belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Triggering event: addition of belief interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
 * Context: true (the plan is always applicable)
 * Body: prints new interaction trust rating (relevant from Task 1 and on)
*/
+interaction_trust(TargetAgent, SourceAgent, MessageContent, ITRating)
    :  true
    <-  .print("Interaction Trust Rating: (", TargetAgent, ", ", SourceAgent, ", ", MessageContent, ", ", ITRating, ")");
    .

/* 
 * Plan for reacting to the addition of the certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Triggering event: addition of belief certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new certified reputation rating (relevant from Task 3 and on)
*/
+certified_reputation(CertificationAgent, SourceAgent, MessageContent, CRRating)
    :  true
    <-  .print("Certified Reputation Rating: (", CertificationAgent, ", ", SourceAgent, ", ", MessageContent, ", ", CRRating, ")");
    .

/* 
 * Plan for reacting to the addition of the witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
 * Triggering event: addition of belief witness_reputation(WitnessAgent, SourceAgent,, MessageContent, WRRating)
 * Context: true (the plan is always applicable)
 * Body: prints new witness reputation rating (relevant from Task 5 and on)
*/
+witness_reputation(WitnessAgent, SourceAgent, MessageContent, WRRating)
    :  true
    <-  .print("Witness Reputation Rating: (", WitnessAgent, ", ", SourceAgent, ", ", MessageContent, ", ", WRRating, ")");
    .

/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celsius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celsius)
 * Context: true (the plan is always applicable)
 * Body: unifies the variable Celsius with the 1st temperature reading from the list TempReadings
*/
@select_reading_task_0_plan
+!select_reading(TempReadings, Celsius)
    :  true
    <-  .nth(0, TempReadings, Celsius);
    .


/* 
 * Plan for reacting to the addition of the goal !select_reading(TempReadings, Celsius)
 * Triggering event: addition of goal !select_reading(TempReadings, Celsius)
 * Context: true (the plan is always applicable)
 * Body: selects the temperature reading from the agent with the highest average interaction trust rating
 */
@select_reading_task_1_plan
+!select_reading(TempReadings, Celsius)
    :  true
    <-  // Find all interaction trust ratings
        .findall(ITRating, interaction_trust(_, SourceAgent, temperature(Temp), ITRating), RatingsList);
        
        // Group ratings by SourceAgent and calculate average trust ratings
        .findall(SourceAgent, interaction_trust(_, SourceAgent, _, _), AgentsList);
        .remove_duplicates(AgentsList, UniqueAgents);
        .print("Unique agents: ", UniqueAgents);
        
        // Calculate average trust for each agent
        HighestTrust = -1;
        BestAgent = null;
        for (.member(Agent, UniqueAgents)) {
            .findall(Rating, interaction_trust(_, Agent, _, Rating), AgentRatings);
            .sum(AgentRatings, TotalTrust);
            .length(AgentRatings, Count);
            AvgTrust = TotalTrust / Count;
            .print("Agent: ", Agent, " AvgTrust: ", AvgTrust);
            
            // Update the agent with the highest trust
            if (AvgTrust > HighestTrust) {
                HighestTrust = AvgTrust;
                BestAgent = Agent;
            }
        };
        
        .print("Agent with highest trust: ", BestAgent, " Trust: ", HighestTrust);
        
        // Select the temperature reading from the agent with the highest trust
        .findall(Temp, interaction_trust(_, BestAgent, temperature(Temp), _), TempReadingsFromBestAgent);
        .nth(0, TempReadingsFromBestAgent, Celsius);
        .print("Selected temperature: ", Celsius);
    .

// Plan to request certified reputation ratings from all sensing agents
+!request_certified_reputation
    :  true
    <-  .print("Requesting certified reputation ratings from all sensing agents.");
        .broadcast(ask, certified_reputation(_, _, _, _)).

// Plan to process certified reputation ratings and select the best temperature reading (TASK 1,2, 3)
/*
+!select_temperature_reading
    :  true
    <-  .print("Selecting the best temperature reading based on IT_CR ratings.");
        // Collect all interaction trust ratings
        .findall(ITRating, interaction_trust(_, Agent, _, ITRating), InteractionTrustRatings);
        .print("Interaction Trust Ratings: ", InteractionTrustRatings);

        // Collect all certified reputation ratings
        .findall(CRRating, certified_reputation(_, Agent, _, CRRating), CertifiedReputationRatings);
        .print("Certified Reputation Ratings: ", CertifiedReputationRatings);

        // Combine IT and CR ratings to calculate IT_CR
        .findall(Agent, interaction_trust(_, Agent, _, _), Agents);
        .remove_duplicates(Agents, UniqueAgents);
        BestAgent = null;
        HighestIT_CR = -1;
        for (.member(Agent, UniqueAgents)) {
            .findall(ITRating, interaction_trust(_, Agent, _, ITRating), AgentITRatings);
            .sum(AgentITRatings, TotalIT);
            .length(AgentITRatings, CountIT);
            IT_AVG = TotalIT / CountIT;

            .findall(CRRating, certified_reputation(_, Agent, _, CRRating), AgentCRRatings);
            .nth(0, AgentCRRatings, CRRating); // Assume one CRRating per agent

            IT_CR = 0.5 * IT_AVG + 0.5 * CRRating;
            .print("Agent: ", Agent, " IT_CR: ", IT_CR);

            if (IT_CR > HighestIT_CR) {
                HighestIT_CR = IT_CR;
                BestAgent = Agent;
            }
        };

        .print("Best agent based on IT_CR: ", BestAgent);
        .findall(Temp, interaction_trust(_, BestAgent, temperature(Temp), _), BestAgentTemps);
        .nth(0, BestAgentTemps, SelectedTemp);
        .print("Selected temperature: ", SelectedTemp);

        // Manifest the selected temperature
        !manifest_temperature(SelectedTemp).
        .
*/

// Plan to process witness reputation ratings and select the best temperature reading TASK 4
+!select_temperature_reading
    :  true
    <-  .print("Selecting the best temperature reading based on IT_CR_WR ratings.");
        // Collect all interaction trust ratings
        .findall(ITRating, interaction_trust(_, Agent, _, ITRating), InteractionTrustRatings);
        .print("Interaction Trust Ratings: ", InteractionTrustRatings);

        // Collect all certified reputation ratings
        .findall(CRRating, certified_reputation(_, Agent, _, CRRating), CertifiedReputationRatings);
        .print("Certified Reputation Ratings: ", CertifiedReputationRatings);

        // Collect all witness reputation ratings
        .findall(WRRating, witness_reputation(_, Agent, _, WRRating), WitnessReputationRatings);
        .print("Witness Reputation Ratings: ", WitnessReputationRatings);

        // Combine IT, CR, and WR ratings to calculate IT_CR_WR
        .findall(Agent, interaction_trust(_, Agent, _, _), Agents);
        .remove_duplicates(Agents, UniqueAgents);
        BestAgent = null;
        HighestIT_CR_WR = -1;
        for (.member(Agent, UniqueAgents)) {
            // Calculate IT_AVG
            .findall(ITRating, interaction_trust(_, Agent, _, ITRating), AgentITRatings);
            .sum(AgentITRatings, TotalIT);
            .length(AgentITRatings, CountIT);
            IT_AVG = TotalIT / CountIT;

            // Get CRRating
            .findall(CRRating, certified_reputation(_, Agent, _, CRRating), AgentCRRatings);
            .nth(0, AgentCRRatings, CRRating); 

            // Calculate WR_AVG
            .findall(WRRating, witness_reputation(_, Agent, _, WRRating), AgentWRRatings);
            .sum(AgentWRRatings, TotalWR);
            .length(AgentWRRatings, CountWR);
            WR_AVG = TotalWR / CountWR;

            // Calculate IT_CR_WR
            IT_CR_WR = (1/3) * IT_AVG + (1/3) * CRRating + (1/3) * WR_AVG;
            .print("Agent: ", Agent, " IT_CR_WR: ", IT_CR_WR);

            if (IT_CR_WR > HighestIT_CR_WR) {
                HighestIT_CR_WR = IT_CR_WR;
                BestAgent = Agent;
            }
        };

        .print("Best agent based on IT_CR_WR: ", BestAgent);
        .findall(Temp, interaction_trust(_, BestAgent, temperature(Temp), _), BestAgentTemps);
        .nth(0, BestAgentTemps, SelectedTemp);
        .print("Selected temperature: ", SelectedTemp);

        // Manifest the selected temperature
        !manifest_temperature(SelectedTemp).


// Plan to request witness reputation ratings from all sensing agents
+!request_witness_reputation
    :  true
    <-  .print("Requesting witness reputation ratings from all sensing agents.");
        .broadcast(ask, witness_reputation(_, _, _, _)).

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celsius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celsius to binary degrees that are compatible with the 
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature
    :  temperature(Celsius) & robot_td(Location)
    <-  .print("I will manifest the temperature: ", Celsius);
        convert(Celsius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celsius to binary degrees based on the input scale
        .print("Temperature Manifesting (moving robotic arm to): ", Degrees);

        /* 
         * If you want to test with the real robotic arm, 
         * follow the instructions here: https://github.com/HSG-WAS-SS24/exercise-8/blob/main/README.md#test-with-the-real-phantomx-reactor-robot-arm
         */
        // creates a ThingArtifact based on the TD of the robotic arm
        makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], Leubot1Id); 
        
        // sets the API key for controlling the robotic arm as an authenticated user
        //setAPIKey("77d7a2250abbdb59c6f6324bf1dcddb5")[artifact_id(Leubot1Id)];

        // invokes the action onto:SetWristAngle for manifesting the temperature with the wrist of the robotic arm
        invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(Leubot1Id)];
    .


// Plan to send biased witness reputation ratings
+!send_witness_reputation
    :  true
    <-  .print("Sending biased witness reputation ratings.");
        // Favor the rogue leader and discredit honest agents
        .send(acting_agent, tell, witness_reputation(self, sensing_agent_9, temperature(-2), 1));
        .send(acting_agent, tell, witness_reputation(self, sensing_agent_1, temperature(11.8), -0.5))
    .



/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }

/* Import interaction trust ratings */
{ include("inc/interaction_trust_ratings.asl") }
