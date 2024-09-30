import 'dart:isolate';

// This is the entry point for the isolate
void aiBackgroundTask(SendPort mainSendPort) {
  // Create a port for receiving messages from the main thread
  ReceivePort isolateReceivePort = ReceivePort();

  // Notify any listeners on the main thread what port this isolate listens to.
  mainSendPort.send(isolateReceivePort.sendPort);

  // Listening for incoming messages
  isolateReceivePort.listen((message) {
    // Check if the message contains a command to initialize AI
    if (message[0] == 'initializeAI') {
      String result = initializeAI(); // Your AI initialization function
      SendPort replyTo = message[1];
      replyTo.send(result); // Send the result back to the main thread
    }
  });
}

// Example function that might take significant time or resources
String initializeAI() {
  // Perform initialization or heavy computations
  // For demonstration, returning a simple string
  return "AI Initialized Successfully";
}



void startIsolate() async {
  // Create a receive port to receive messages from the isolate
  ReceivePort mainReceivePort = ReceivePort();
  Isolate isolate = await Isolate.spawn(aiBackgroundTask, mainReceivePort.sendPort);

  // Get the send port from the isolate
  SendPort isolateSendPort = await mainReceivePort.first;

  // Create another receive port to get the response from the isolate
  ReceivePort responsePort = ReceivePort();
  isolateSendPort.send(['initializeAI', responsePort.sendPort]);

  // Get the response from the isolate
  String result = await responsePort.first;
  print('Isolate said: $result');

  // Close the isolate once done
  isolate.kill(priority: Isolate.immediate);
  responsePort.close();
  mainReceivePort.close();
}
