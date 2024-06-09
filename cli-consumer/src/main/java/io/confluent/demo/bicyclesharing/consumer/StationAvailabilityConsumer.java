package io.confluent.demo.bicyclesharing.consumer;


import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.confluent.demo.bicyclesharing.pojo.StationAvailability;
import org.apache.kafka.clients.consumer.*;
import org.apache.log4j.Logger;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

import static java.nio.file.Files.newInputStream;

public class StationAvailabilityConsumer implements Runnable {

    private static final Logger logger = Logger.getLogger(StationAvailabilityConsumer.class.getName());
    private static Properties props;
    private String topicNames;
    private String groupId;
    private String clientId;

    private Properties loadConfig(String propsPath) throws IOException {
        Properties props = new Properties();
        try (InputStream resourceAsStream = newInputStream(Paths.get(propsPath))) {
            props.load(resourceAsStream);
        }
        return props;
    }

    public StationAvailabilityConsumer(String propsPath) {
        try {
            props = loadConfig(propsPath);
            props.setProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
            props.setProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "io.confluent.kafka.serializers.json.KafkaJsonSchemaDeserializer");
            this.groupId = props.getProperty("group.id");
            this.clientId = this.groupId + "-0";
            props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
            props.put(ConsumerConfig.CLIENT_ID_CONFIG, clientId);
            props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
            this.topicNames = props.getProperty("stations.color.topic");
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public void runConsumer() throws Exception {


        try (Consumer<String, JsonNode> consumer = new KafkaConsumer<String, JsonNode>(props)) {
                // Subscribe to topic(s)
                consumer.subscribe(Arrays.asList(topicNames.split(",")));

                // Print stations stock with art work
                ASCIIArtGenerator art = new ASCIIArtGenerator();
                System.out.println("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
                System.out.print(ColouredSystemOutPrintln.ANSI_BRIGHT_PURPLE);
                art.bigBike();
                System.out.println("\n");
                ASCIIArtService.print(clientId);

                Thread.sleep(3000);

                while (true) {
                    ConsumerRecords<String, JsonNode> records = consumer.poll(Duration.ofMillis(100));
                    for (ConsumerRecord<String, JsonNode> record : records) {
                        StationAvailability station = new ObjectMapper().convertValue(record.value(), new TypeReference<StationAvailability>() {
                        });
                        PrettyPrintStationAvailability.print(station);
                    }
                }
        } catch (Exception e) {
            logger.error("Error in runConsumer method: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }

    /**
     * @param args resourcesDir propertiesFile topicName groupID clientID
     * @param args [0] The properties filename
     * @param args [1] The name of the topic to subscribe
     * @param args [2] The group Id
     * @param args [3] The client Id
     * @return Nothing.
     */
    public static void main(final String[] args) throws Exception {

        StationAvailabilityConsumer consumer = new StationAvailabilityConsumer(args[0]);
        consumer.runConsumer();
    }

    @Override
    public void run() {
        try {
            this.runConsumer();
        } catch (IOException e) {
            logger.error("IOException in run method: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            logger.error("Exception in run method: " + e.getMessage());
            e.printStackTrace();
        }
    }
}