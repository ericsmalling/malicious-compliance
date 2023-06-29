#!/usr/bin/env python3

from langchain.llms import OpenAI
from sys import argv
import docker
import io
import tarfile




def fileFromContainer(container, path):
    print("Retrieving file "+path+" from container "+container.name+"...")
    try:
        bits, stat = container.get_archive(path)
    except docker.errors.NotFound:
        print("File not found in container.")
        return None
    tar_data = b""
    for chunk in bits:
        tar_data += chunk
    tar_stream = io.BytesIO(tar_data)
    tar_file = tarfile.open(fileobj=tar_stream)
    return tar_file.extractfile(path.split("/")[-1]).read().decode('utf-8')


container_image = argv[1]
print("Creating (but not starting) container for image: "+container_image+"...")
client = docker.from_env()
c = client.containers.create(container_image)
print("Container created: "+c.name)
print("Retrieving image inspect...")
image_inspect = client.images.get(container_image).attrs

print("Asking OpenAI for files to retrieve for container image...")
llm = OpenAI(model_name="gpt-4")
files_to_retrieve = llm.predict( temperature=0.7, text=
    "I have a container image and am wanting to verify that the linux distribution and version looks valid. For reference the docker image inspect json response is as follows: "+str(image_inspect)+"\n Which files in the image would be interesting to look at for that information? Include all relevant real files that would exist in an image (no symlinks and no virtual files that only exist at runtime and no wildcard patterns), including files that determine os versions, etc. Return only the file names, one per line with no formatting.")

print("Files to inspect are:\n"+files_to_retrieve)

files = files_to_retrieve.strip().split("\n")

prompt = "The following text is contents of a container image filesystem. The structure of the text are sections that begin with ----, followed by a single line containing the file path and file name, followed by a variable amount of lines containing the file contents. The text representing the container image files ends when the symbols --END-- are encounted. Any further text beyond --END-- are meant to be interpreted as instructions using the aforementioned container image filesystem as context.\n"

for path in files:
    file = fileFromContainer(c, path)
    if file is not None:
        prompt += "----\n"
        prompt += "/etc/" + file + "\n"
        prompt += file + "\n"

prompt += "--END--\n"

prompt += "Do the contents of these files and image metadata look consistent with the linux distribution and version that the container image claims to be? If not, what discrepancies do you see?\n"

print(llm.predict(prompt))

print("Stopping container "+c.name+" ...")
c.remove()