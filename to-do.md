First, ensure to read the system prompt at gemini.md. strictly follow the system prompt.

now, these are the things you need to do. 

1. comment out the usage of encryption in scanning for the qr codes.
- ensure that it is commented out so that i can revert back to it.
- the new one just uses the plaintext lrn from the qr code. it is not json. it just plaintext.

2. also make the importing of the master list automated by importing it from firestore.
- the master list can be found in the collection master_list and has the same structure.
- ensure that at the tap of a button, the device can import everything and that they are notified and shown a progress bar. 

3. also make the importing of the student photos automated as well using google drive api.
- the student photos can be found in a specific public folder in google drive.
- ensure that at the tap of a button, the device can import everything and that they are notified and shown a progress bar.
- ensure that all files can be downloaded. 
- i will supply the folder link later on or the folder id and the credentials and the api key to be used for the google drive api.

4. clean up the things that are not needed anymore.


5. ensure that the entire system is coherent and that the flow is seamless.
- advise me on things that might need improvement or that there are things that are needed or not needed.
- ensure that the workflows support the user flows.