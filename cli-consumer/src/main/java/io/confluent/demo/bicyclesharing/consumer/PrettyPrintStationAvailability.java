package io.confluent.demo.bicyclesharing.consumer;

import io.confluent.demo.bicyclesharing.pojo.StationAvailability;

public class PrettyPrintStationAvailability {

    public static void print(StationAvailability value) throws Exception {

        ASCIIArtGenerator art = new ASCIIArtGenerator();
        double availability = value.getRatio();
        double availableBikes = value.getNumBikesAvailable();
        String stationName = value.getName();

        if (availability >= 0.5)
            System.out.print( ColouredSystemOutPrintln.ANSI_BLACK + ColouredSystemOutPrintln.ANSI_BG_GREEN);
        else if (availability >= 0.1)
            System.out.print( ColouredSystemOutPrintln.ANSI_BLACK + ColouredSystemOutPrintln.ANSI_BG_YELLOW);
        else System.out.print( ColouredSystemOutPrintln.ANSI_BLACK + ColouredSystemOutPrintln.ANSI_BG_RED);

        System.out.print( ColouredSystemOutPrintln.ANSI_BLACK + ColouredSystemOutPrintln.ANSI_BRIGHT_BG_WHITE);
        System.out.print("The station on ");
        System.out.print(stationName);
        System.out.println(" has " + availableBikes + " bikes available ...       \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t");
        System.out.print(ColouredSystemOutPrintln.ANSI_BRIGHT_BG_WHITE);
        if (availability >= 0.5)
            System.out.print(ColouredSystemOutPrintln.ANSI_BG_GREEN + ColouredSystemOutPrintln.ANSI_BLACK);
        else if (availability >= 0.1)
            System.out.print( ColouredSystemOutPrintln.ANSI_BG_YELLOW + ColouredSystemOutPrintln.ANSI_BLACK);
        else System.out.print( ColouredSystemOutPrintln.ANSI_BG_RED + ColouredSystemOutPrintln.ANSI_BLACK);

        art.bike();
        System.out.println("\n" + ColouredSystemOutPrintln.ANSI_BG_BLACK);

}
}
