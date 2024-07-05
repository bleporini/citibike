package io.confluent;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.confluent.demo.bicyclesharing.pojo.StationAvailability;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

import static java.nio.file.Files.newInputStream;

public class StationAvailabilityConsumer {


    private Properties props;

    private static final List<BiConsumer<String, StationAvailability>> consumers = new CopyOnWriteArrayList<>();


    private Properties loadConfig(InputStream propsIS) throws IOException {
        Properties props = new Properties();
        props.load(propsIS);
        return props;
    }

    private void setupConsumer() {
        final Properties props;
        try (InputStream propsIS = getClass().getResourceAsStream("/bicyclesharing.nyc.properties")) {
            props = loadConfig(propsIS);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        props.setProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
        props.setProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "io.confluent.kafka.serializers.json.KafkaJsonSchemaDeserializer");
        String groupId = props.getProperty("group.id");
        String clientId = groupId + "-0";
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        props.put(ConsumerConfig.CLIENT_ID_CONFIG, clientId);
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
        String topicName = props.getProperty("stations.color.topic");
        org.apache.kafka.clients.consumer.Consumer<String, JsonNode> consumer = new KafkaConsumer<String, JsonNode>(props);
        consumer.subscribe(Collections.singletonList(topicName));
        while (true) {
            ConsumerRecords<String, JsonNode> records = consumer.poll(Duration.ofMillis(1000));
            for (ConsumerRecord<String, JsonNode> record : records) {
                if (record.value() == null) continue;
                StationAvailability station = new ObjectMapper().convertValue(record.value(), new TypeReference<StationAvailability>() {
                });
                consumers.forEach(c -> c.accept(record.key(), station));
            }
        }

    }

    public static void register(BiConsumer<String, StationAvailability> c) {
        consumers.add(c);
    }
    public static void start() {
        StationAvailabilityConsumer that = new StationAvailabilityConsumer();
        new Thread(that::setupConsumer).start();
    }
}
