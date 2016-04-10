package de.lhtechnologies;

import de.lhtechnologies.flightComputer.MockSerialPortManager;
import de.lhtechnologies.flightComputer.SerialPortManager;
import de.lhtechnologies.inetComms.InetManager;

public class Main {

    public static void main(String[] args) throws Exception {
        //Initialize the IRC bot
        InetManager inet = new InetManager();

        //Initialize the serial port
        SerialPortManager serial = new SerialPortManager();

        //Initialize the writer
        FileWriter fw = new FileWriter();
        serial.serialReceiver.addObserver(fw);

        //Initialize the UDP broadcaster
        UDPBroadcaster udp = new UDPBroadcaster();
        serial.serialReceiver.addObserver(udp);

        //Initialize the glue class
        InetSerialConnection connection = new InetSerialConnection(serial.serialTransmitter, inet.transmitter);
        inet.receiver.addObserver(connection);
        serial.serialReceiver.addObserver(connection);

        System.out.println("Initialization complete…");

        //Start the Inet thread
        new Thread(inet).start();

        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                try {
                    fw.cleanup();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
