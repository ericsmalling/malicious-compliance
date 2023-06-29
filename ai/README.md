Prototype Python LangChain app for querying ChatGPT for suspicious container images.
As of now, the app attepmts to detect the changes in the sig-honk/malicious-compliance:1-os taged image

## Usage
1. Build the test images in the parent folder
```bash
$ make build-all
...
$ docker images
REPOSITORY                      TAG       IMAGE ID       CREATED        SIZE
sig-honk/malicious-compliance   3-lang    96bd626d4bea   2 months ago   240MB
sig-honk/malicious-compliance   2-pkg     75a12e6ce9f4   2 months ago   240MB
sig-honk/malicious-compliance   1-os      343e1fb2d256   2 months ago   240MB
sig-honk/malicious-compliance   0-base    dc3a4f83989b   2 months ago   240MB
```
_Note: On an ARM machine, the build will fail after the 4th image is built (tag `3-lang`) - this is fine for the purposes of this test as we only care about the first two for now._
2. Ensure your OpenAI API key is set in the environment variable `OPENAI_API_KEY`
```bash
export OPENAI_API_KEY="sk-..."
```
3. Run the app with the image you want to inspect as the argument
```text
```./many.py [image:tag]
$ ./main.py sig-honk/malicious-compliance:0-base
Creating (but not starting) container for image: sig-honk/malicious-compliance:0-base...
Container created: elegant_nightingale
Retrieving image inspect...
Asking OpenAI for files to retrieve for container image...
/opt/homebrew/lib/python3.11/site-packages/langchain/llms/openai.py:189: UserWarning: You are trying to use a chat model. This way of initializing it is no longer supported. Instead, please use: `from langchain.chat_models import ChatOpenAI`
  warnings.warn(
/opt/homebrew/lib/python3.11/site-packages/langchain/llms/openai.py:769: UserWarning: You are trying to use a chat model. This way of initializing it is no longer supported. Instead, please use: `from langchain.chat_models import ChatOpenAI`
  warnings.warn(
Files to inspect are:
/etc/os-release
...
The names and versions in the file content seem to match up with what the container image claims to be, which is Alpine Linux v3.7. However, it's unusual that the same content seems to be repeated twice in both the "/etc/os-release" and "/etc/issue" files. This is not a discrepancy with the claimed linux distribution and version, but it might indicate a mistake or unnecessary redundancy in the container image. Other than this, no clear discrepancies can be identified based only on the provided information.

For more accurate validation, the actual content of these files could be compared with verified examples from the claimed distribution and version, and additional files (like specific versioned packages) in the container image filesystem could be examined. It's also worth mentioning that this doesn't validate that the actual running kernel or core components of the OS match the claimed version, only that these specific files in the filesystem do.
```
... or ...
```text
$ ./main.py sig-honk/malicious-compliance:1-os
Creating (but not starting) container for image: sig-honk/malicious-compliance:1-os...
Container created: gallant_volhard
Retrieving image inspect...
Asking OpenAI for files to retrieve for container image...
/opt/homebrew/lib/python3.11/site-packages/langchain/llms/openai.py:189: UserWarning: You are trying to use a chat model. This way of initializing it is no longer supported. Instead, please use: `from langchain.chat_models import ChatOpenAI`
  warnings.warn(
/opt/homebrew/lib/python3.11/site-packages/langchain/llms/openai.py:769: UserWarning: You are trying to use a chat model. This way of initializing it is no longer supported. Instead, please use: `from langchain.chat_models import ChatOpenAI`
  warnings.warn(
Files to inspect are:
/etc/os-release
...
The content of the filesystem seems inconsistent. While initially it suggests that the Linux distribution is some generic Linux version 99 tagged as "honk", in the last file, the content suggests that the container image is for Alpine Linux 3.7. This is a major discrepancy as these represent two different major versions of two different Linux distributions, not a difference in minor versions or builds. The container image file content does not match with the supposed Linux version and distribution that the image claims to be.
```
