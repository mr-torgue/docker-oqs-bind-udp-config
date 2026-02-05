from ripe.atlas.cousteau import AtlasStream

def on_result_response(*args):
    """
    Function that will be called every time we receive a new result.
    Args is a tuple, so you should use args[0] to access the real message.
    """
    print(args[0])

atlas_stream = AtlasStream()
atlas_stream.connect()

# Bind function we want to run with every result message received
atlas_stream.bind("atlas_result", on_result_response)

# Subscribe to new stream for 1001 measurement results
stream_parameters = {"msm": 1001}
atlas_stream.subscribe(stream_type="result", **stream_parameters)

# Process incoming events for 5 seconds, calling the callback defined above.
# Make sure you have this line after you start *all* your streams
atlas_stream.timeout(seconds=5)

# Shut down everything
atlas_stream.disconnect()