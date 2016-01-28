package de.lhtechnologies;

import com.sun.xml.internal.ws.policy.privateutil.PolicyUtils;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.time.Duration;
import java.util.concurrent.*;

/**
 * Created by ludger on 27.01.16.
 */
public class TCPRelay implements Runnable {
    private String msgStart = "-----BEGIN MESSAGE-----";
    private String sigEnd = "-----END SIGNATURE-----";
    public static String newline = System.getProperty("line.separator");

    private TCPRelay counterpart;

    private ServerSocket server;
    private Socket socket;
    private OutputStream out;
    private BufferedReader br;

    public TCPRelay(int port) throws IOException {
        server = new ServerSocket(port);
    }

    public void setCounterpart(TCPRelay counterpart) {
        this.counterpart = counterpart;
    }

    public void send(byte[] message) {
        if(out != null) {
            try {
                out.write(message);
            } catch (IOException e) {
                e.printStackTrace();

                //Force connection reset
                resetConnection();
            }
        }
    }

    @Override
    public void run() {
        resetConnection();
        while(true) {
            try {
                String startLine = br.readLine();
                if (startLine != null && startLine.equals(msgStart)) {
                    final Duration timeout = Duration.ofSeconds(500);
                    ExecutorService executor = Executors.newSingleThreadExecutor();

                    final Future<String> handler = executor.submit(new Callable() {
                        @Override
                        public String call() throws Exception {
                            return readData();
                        }
                    });

                    try {
                        String rest = handler.get(timeout.toMillis(), TimeUnit.MILLISECONDS);
                        String message = startLine + newline + rest;
                        counterpart.send(message.getBytes());
                    } catch (TimeoutException e) {
                        e.printStackTrace();
                        handler.cancel(true);
                    }
                    executor.shutdownNow();
                }
            } catch (Exception e) {
                e.printStackTrace();

                //Force connection reset
                resetConnection();
            }
        }
    }

    public String readData() throws IOException {
        StringBuilder outStringBuilder = new StringBuilder();

        //Read a complete message
        for (String line = br.readLine(); line != null; line = br.readLine()) {
            outStringBuilder.append(line);
            outStringBuilder.append(newline);
            if (line.equals(sigEnd)) {
                break;
            }
        }
        return outStringBuilder.toString();
    }

    public void resetConnection() {
        if(br != null) {
            try {
                br.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        br = null;

        if(out != null) {
            try {
                out.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        out = null;

        if(socket != null) {
            try {
                socket.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        socket = null;

        try {
            socket = server.accept();
            InputStream in = socket.getInputStream();
            br = new BufferedReader(new InputStreamReader(in));
            out = socket.getOutputStream();
        } catch (IOException e) {
            System.out.println("Resetting connection failed!");
            e.printStackTrace();
            System.exit(-1);
        }
    }
}
