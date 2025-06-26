weaviate_url        = "https://3hye6kpspq1j4xwl9qcsg.c0.us-west3.gcp.weaviate.cloud"
weaviate_api_key    = "l5ehhKdD7XmM5OYL2i2CkS2hLV7RuSNaFdHV"


# Extract the configuration values - These are the only values you need to configure in the .json files
huggingface_api_key = "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"
embedding_model     = "sentence-transformers/all-MiniLM-L6-v2"

# Extract LLM settings - These are the only values you need to configure in the .json files
openai_api_key  = "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"
openai_model    = "gpt-4o"

system_prompt   = """You are PixelProofys AI assistant, specializing in answering enterprise-related questions using the most relevant retrieved context. Your goal is to provide precise, well-structured, and professional responses based on the available context. If the provided context is insufficient, acknowledge it and avoid making assumptions. Always prioritize accuracy, clarity, and security when responding to sensitive topics.
Always exclude the parent path from your answer. Do not show this in your answer."""

user_prompt     = """You are answering as PixelProofy's AI Assistant. Use the retrieved context to generate an accurate response. If the context does not contain relevant information, state that explicitly rather than making assumptions.\n\nContext:\n{context}\n\nUser Question:\n{message}\n\nChat History:\n{history}\n\n---\nEnsure responses are concise yet informative, maintaining a professional tone. Cite sources from the provided context when applicable."""

temperature     = 0.8
max_tokens      = 1000



import json
import gradio as gr
import traceback
import os
import logging
import requests.exceptions
from openai import OpenAI, OpenAIError
from langchain_community.embeddings.huggingface import HuggingFaceInferenceAPIEmbeddings
import weaviate
from weaviate.classes.init import Auth
from weaviate.classes.query import MetadataQuery

# Get the current directory where the script is run
# In a Jupyter Notebook, __file__ is not defined. Use os.getcwd() instead.
current_dir = os.getcwd()

# Load configuration from config.json in the current directory
config_path = os.path.join(current_dir, 'config.json')
# Add a check to ensure the file exists before trying to open it
if not os.path.exists(config_path):
    print(f"Error: config.json not found at {config_path}")
    # You might want to handle this error more gracefully, e.g., exit or use default values
    # For this example, we'll print a message and continue, which will likely lead to other errors if the files are truly missing.
    # A more robust solution would be to raise an exception or provide a clear error message to the user.
    # Exit the program if the configuration file is essential.
    # import sys
    # sys.exit("Configuration file config.json not found.")
    # For demonstration, we'll just print a message.
    pass # Or add more robust error handling

# Load LLM settings from llm_settings.json
llm_settings_path = os.path.join(current_dir, 'llm_settings.json')
# Add a check to ensure the file exists before trying to open it
if not os.path.exists(llm_settings_path):
    print(f"Error: llm_settings.json not found at {llm_settings_path}")
    # Handle this error similarly to config.json
    pass # Or add more robust error handling


# Wrap file loading in a try-except block to catch potential FileNotFoundError
try:
    with open(config_path) as config_file:
        config = json.load(config_file)

    with open(llm_settings_path) as llm_settings_file:
        llm_settings = json.load(llm_settings_file)

    ##################################### CONFIGURATION START #####################################

    # Extract the configuration values - These are the only values you need to configure in the .json files
    huggingface_api_key = config["huggingface_api_key"]
    weaviate_url        = config["weaviate_url"]
    weaviate_api_key    = config["weaviate_api_key"]
    embedding_model     = config["embedding_model"]

    # Extract LLM settings - These are the only values you need to configure in the .json files
    openai_api_key  = llm_settings["openai_api_key"]
    openai_model    = llm_settings["openai_model"]
    system_prompt   = llm_settings["system_prompt"]
    user_prompt     = llm_settings["user_prompt"]
    temperature     = llm_settings["temperature"]
    max_tokens      = llm_settings["max_tokens"]

    ##################################### CONFIGURATION END #####################################

except FileNotFoundError as e:
    print(f"Error loading configuration files: {e}")
    # You might want to set default values or exit the program here
    # For now, we'll print the error and subsequent code might fail if these variables are needed.
    pass
except KeyError as e:
    print(f"Error extracting key from configuration files: {e}. Please ensure the keys exist in your config.json and llm_settings.json.")
    pass
except Exception as e:
    print(f"An unexpected error occurred while loading configurations: {e}")
    pass


# Initialize the OpenAI client
# Initialize clients only if API keys are available from configuration
if 'openai_api_key' in locals() and openai_api_key:
    openai_client = OpenAI(api_key=openai_api_key)
else:
    print("OpenAI API key not loaded. OpenAI client will not be initialized.")
    openai_client = None # Set to None to indicate it's not initialized

# Initialize Weaviate client
if 'weaviate_url' in locals() and weaviate_url and 'weaviate_api_key' in locals() and weaviate_api_key:
    try:
        weaviate_client = weaviate.connect_to_weaviate_cloud(
            cluster_url      = weaviate_url,
            auth_credentials = Auth.api_key(weaviate_api_key),
        )
        # Optional: Check connection
        # if weaviate_client.is_ready():
        #     print("Weaviate connection successful.")
        # else:
        #     print("Weaviate connection failed.")
        #     weaviate_client = None # Set to None if connection fails
    except Exception as e:
        print(f"Error connecting to Weaviate: {e}")
        weaviate_client = None # Set to None if connection fails
else:
    print("Weaviate URL or API key not loaded. Weaviate client will not be initialized.")
    weaviate_client = None # Set to None if not initialized


# Function to get available collections from Weaviate
def get_available_collections():
    # Check if the client is initialized before using it
    if weaviate_client:
        try:
            weaviate_collections = weaviate_client.collections.list_all()
            return list(weaviate_collections.keys())
        except Exception as e:
            print(f"Error getting collections from Weaviate: {e}")
            return []
    else:
        print("Weaviate client not initialized. Cannot get collections.")
        return []


# Function to get embeddings from HuggingFace
def get_embedding(text):
    # Check if the API key and model name are available
    if 'huggingface_api_key' in locals() and huggingface_api_key and 'embedding_model' in locals() and embedding_model:
        try:
            embeddings = HuggingFaceInferenceAPIEmbeddings(
                api_key    = huggingface_api_key,
                model_name = embedding_model
            )
            return embeddings.embed_query(text)
        except Exception as e:
            print(f"Error getting embedding from HuggingFace: {e}")
            return None # Return None or handle error appropriately
    else:
        print("HuggingFace API key or embedding model not loaded. Cannot generate embeddings.")
        return None


# Define the predict function
def predict(message, history, collection_names):
    if not collection_names:
        return "Please select at least one collection."

    # Ensure clients are initialized
    if openai_client is None or weaviate_client is None:
        return "Clients not initialized due to configuration errors."

    try:
        # Get embedding for the query
        query_embedding = get_embedding(message)

        if query_embedding is None:
            return "Failed to generate embedding for the query."

        # Initialize variables for response
        all_results = []

        # Search each selected collection
        for collection_name in collection_names:

            # Get the Weaviate collection
            weaviate_collection = weaviate_client.collections.get(collection_name)
            response            = weaviate_collection.query.near_vector(
                near_vector         = query_embedding,
                limit               = 10,
                return_metadata     = MetadataQuery(distance=True)
            )

            if response:
                all_results.extend(response.objects)

        if not all_results:
            return "No relevant information found in the selected collections."

        # Extract and format content from all_results
        context = "\n".join([
            f"Content: {obj.properties.get('content', '')}\n"
            f"Parent: {obj.properties.get('parent', '')}\n"
            f"Chunk: {obj.properties.get('chunk', '')}\n"
            f"Semantic Distance: {obj.metadata.distance}\n"
            for obj in all_results
        ])

        # Prepare messages for OpenAI
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_prompt.format(context=context, message=message, history=history)},
        ]

        # Get response from OpenAI
        response = openai_client.chat.completions.create(
            model=openai_model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )

        return response.choices[0].message.content

    except Exception as e:
        # Log the traceback for better debugging
        logging.error("Error in predict function:", exc_info=True)
        return f"Error: {str(e)}"


# Define the chat interface
def chat_interface(message, collection_names, history=[]):
    return predict(message, history, collection_names)

# Gradio Interface with collection selection and chat interface
def refresh_collections():
    return gr.Dropdown(choices=get_available_collections())

with gr.Blocks(css="""
    .gradio-container { background-color: #FFF5E1; height: 100vh; display: flex; flex-direction: column; }

    /* Styling for chatbot messages */
    .custom-chatbot .user-message {
        background-color: #FFEDD5 !important; /* Light Orange */
        text-align: right !important;
        padding: 10px 15px !important;
        border-radius: 10px !important;
        max-width: 70%;
        margin: 5px 0 5px auto; /* Right-align */
        display: block;
    }

    .custom-chatbot .assistant-message {
        background-color: #E5E7EB !important; /* Light Gray */
        text-align: left !important;
        padding: 10px 15px !important;
        border-radius: 10px !important;
        max-width: 70%;
        margin: 5px auto 5px 0; /* Left-align */
        display: block;
    }

    /* Ensure buttons and input fields are aligned */
    .send-btn button {
        height: 100% !important;
        width: 100% !important;
        font-size: 20px !important;
    }
""") as interface:

    with gr.Row():
        # Ensure 'logo.png' is in the same directory as your notebook, or provide the full path.
        # You might want to add error handling here as well if the image file is not found.
        try:
            gr.Image("logo.png", width=100, height=100, show_label=False, elem_id="logo")
        except FileNotFoundError:
             print("Warning: logo.png not found. Image will not be displayed.")
             # Optionally, display a placeholder or just skip the image.
             # gr.HTML("<span>Logo Placeholder</span>")
        collection_dropdown = gr.Dropdown(
            choices=get_available_collections(),
            label="Select Collection(s)",
            multiselect=True
        )

    chatbot = gr.Chatbot(elem_id="custom-chatbot")  # Apply styling to chatbot

    # Row Layout for Input Box + Send Button
    with gr.Row():
        with gr.Column(scale=3):  # Input box takes 75% of the row width
            message_input = gr.Textbox(show_label=False, placeholder="Type your message here...")
        with gr.Column(scale=1, elem_classes="send-btn"):  # Send button takes 25% of the row width
            send_button = gr.Button("→")  # Replaces "Send" with an arrow

    current_collections = gr.State([])

    # Function to format chat messages correctly
    def format_chat(history):
        formatted_messages = []
        for i, (sender, message) in enumerate(history):
            # Gradio expects tuples of (user_message, bot_message) for the chatbot component.
            # When adding to history, we added tuples like ("You", message) and ("Assistant", message).
            # We need to convert this list of individual messages into the correct format for the chatbot display.
            if i % 2 == 0: # This should be the user message
                 # Ensure the next message exists and is the bot message
                 if i + 1 < len(history) and history[i+1][0] == "Assistant":
                      formatted_messages.append((message, history[i+1][1])) # User message, Bot message
                 else:
                      # This case might happen if the last message is from the user and the bot hasn't responded yet.
                      formatted_messages.append((message, None)) # User message, No bot message yet
            # If i is odd, it's a bot message that was already paired with the previous user message.
        return formatted_messages


    # Function to handle user interaction
    def user_interaction(message, chat_history, collection_names):
        # Gradio's chatbot component passes the history as a list of [user_message, bot_message] pairs.
        # Our original `history` was a list of individual messages like [("You", msg1), ("Assistant", msg2), ...].
        # We need to convert the Gradio history format back to our format for the predict function.
        # Then, update the Gradio history format for display.

        if not message:
            # Return the current history and an empty string for the input field
            return chat_history, ""

        # Convert Gradio history format to our internal format
        # Each item in chat_history is [user_msg, bot_msg] or [user_msg, None]
        internal_history = []
        for user_msg, bot_msg in chat_history:
            if user_msg is not None:
                internal_history.append(("You", user_msg))
            if bot_msg is not None:
                internal_history.append(("Assistant", bot_msg))

        # Add the new user message to the internal history
        internal_history.append(("You", message))

        # Get bot response using the internal history format
        # Note: The predict function expects a list of tuples [('You', msg1), ('Assistant', msg2), ...]
        # We pass the internal_history here.
        bot_response = chat_interface(message, collection_names, internal_history)

        # Add the bot response to the internal history
        internal_history.append(("Assistant", bot_response))

        # Convert the updated internal history back to Gradio's chat history format
        # This is now a list of [user_message, bot_message] pairs
        gradio_history = []
        i = 0
        while i < len(internal_history):
            user_msg_tuple = internal_history[i]
            user_msg = user_msg_tuple[1] if user_msg_tuple[0] == "You" else None

            bot_msg = None
            if i + 1 < len(internal_history):
                bot_msg_tuple = internal_history[i+1]
                if bot_msg_tuple[0] == "Assistant":
                    bot_msg = bot_msg_tuple[1]
                    i += 2 # Move to the next user message
                else:
                     # This case shouldn't happen if messages strictly alternate,
                     # but handling it prevents infinite loops.
                     i += 1
            else:
                # Last message is from the user, no bot response yet in history
                i += 1
            gradio_history.append([user_msg, bot_msg])


        # Return the updated Gradio history and clear the input field
        return gradio_history, ""

    # Allow ENTER key to send messages
    # The inputs to the submit and click functions should match the parameters of user_interaction
    # The outputs should match the return values of user_interaction
    message_input.submit(
        user_interaction,
        inputs=[message_input, chatbot, collection_dropdown], # Pass message, current chatbot history, and selected collections
        outputs=[chatbot, message_input] # Update the chatbot and clear the input field
    )

    # Also allow clicking the Send button to send messages
    send_button.click(
        user_interaction,
        inputs=[message_input, chatbot, collection_dropdown], # Pass message, current chatbot history, and selected collections
        outputs=[chatbot, message_input] # Update the chatbot and clear the input field
    )

    # Reset the chat when collections change
    # The change function needs to return the initial state for the outputs.
    # For the chatbot, the initial state is an empty list [].
    collection_dropdown.change(
        lambda: [], # Return an empty list to clear the chatbot history
        outputs=[chatbot] # Update the chatbot component
    )

# Launch Gradio interface
interface.launch()
