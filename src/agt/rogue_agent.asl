// rogue agent is a type of sensing agent

/* Initial beliefs and rules */
// initially, the agent believes that it hasn't received any temperature readings
received_readings([]).

/* Initial goals */
!set_up_plans. // the agent has the goal to add pro-rogue plans

/* 
 * Plan for reacting to the addition of the goal !set_up_plans
 * Triggering event: addition of goal !set_up_plans
 * Context: true (the plan is always applicable)
 * Body: adds pro-rogue plans for colluding with the rogue leader
*/
+!set_up_plans
    :  true
    <-  // removes plans for reading the temperature with the weather station
        .relevant_plans({ +!read_temperature }, _, LL);
        .remove_plan(LL);
        .relevant_plans({ -!read_temperature }, _, LL2);
        .remove_plan(LL2);

        // adds a new plan for colluding with the rogue leader
        .add_plan({ +!read_temperature
            :  true
            <-  .print("Reading the temperature");
                // waits for 2000 milliseconds and finds all beliefs about received temperature readings
                .wait(2000);
                .findall(TempReading, temperature(TempReading)[source(Ag)], TempReadings);
                .print("Received temperature readings: ", TempReadings);

                // filters the temperature reading from the rogue leader
                .findall(Temp, temperature(Temp)[source(sensing_agent_9)], RogueLeaderReadings);
                
                if (RogueLeaderReadings == []) {
                    .print("No temperature readings received yet.");
                    .broadcast(tell, temperature(-2));
                } else {
                    .nth(0, RogueLeaderReadings, RogueLeaderTemp);

                    // broadcasts the rogue leader's temperature reading
                    .print("Colluding with rogue leader. Broadcasting temperature: ", RogueLeaderTemp);
                    .broadcast(tell, temperature(RogueLeaderTemp));
                    }
            });
    .

/* Import behavior of sensing agent */
{ include("sensing_agent.asl")}