from ripe.atlas.cousteau import AtlasStream

atlas_stream = AtlasStream()
atlas_stream.connect()

stream_parameters = {"enrichProbes": True}
atlas_stream.subscribe(stream_type="probestatus", **stream_parameters)

# Iterate over the incoming results for 5 seconds
for event_name, payload in atlas_stream.iter(seconds=5):
    print(event_name, payload)

# Shut down everything
atlas_stream.disconnect()