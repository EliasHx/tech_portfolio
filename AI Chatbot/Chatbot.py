


weaviate_url        = {link}
weaviate_api_key    = {weviate_api_key}


# Extract the configuration values - These are the only values you need to configure in the .json files
huggingface_api_key = {huggingface_api_key}
embedding_model     = "sentence-transformers/all-MiniLM-L6-v2"

# Extract LLM settings - These are the only values you need to configure in the .json files
openai_api_key  = {openai_api_key}
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
current_dir = os.path.dirname(os.path.abspath(__file__))

# Load configuration from config.json in the current directory
config_path = os.path.join(current_dir, 'config.json')
with open(config_path) as config_file:
    config = json.load(config_file)

# Load LLM settings from llm_settings.json
llm_settings_path = os.path.join(current_dir, 'llm_settings.json')
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

# Initialize the OpenAI client
openai_client = OpenAI(api_key=openai_api_key)

# Initialize Weaviate client
weaviate_client = weaviate.connect_to_weaviate_cloud(
    cluster_url      = weaviate_url,
    auth_credentials = Auth.api_key(weaviate_api_key),
)

# Function to get available collections from Weaviate
def get_available_collections():
    try:
        weaviate_collections = weaviate_client.collections.list_all()
        return list(weaviate_collections.keys())
    except Exception as e:
        print(f"Error getting collections: {e}")
        return []

# Function to get embeddings from HuggingFace
def get_embedding(text):
    embeddings = HuggingFaceInferenceAPIEmbeddings(
        api_key    = huggingface_api_key,
        model_name = embedding_model
    )
    return embeddings.embed_query(text)

# Define the predict function
def predict(message, history, collection_names):
    if not collection_names:
        return "Please select at least one collection."
    
    try:
        # Get embedding for the query
        query_embedding = get_embedding(message)
        
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
        gr.Image("logo.png", width=100, height=100, show_label=False, elem_id="logo")
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
        for sender, message in history:
            if sender == "You":
                formatted_messages.append(("", f'<div class="user-message">{message}</div>'))  # Only message, no "You"
            else:
                formatted_messages.append(("", f'<div class="assistant-message">{message}</div>'))  # Only message, no "Assistant"
        return formatted_messages

    # Function to handle user interaction
    def user_interaction(message, history, collection_names, current_collections):
        if not message:
            return history, current_collections, ""  # Clear input field

        user_message = ("You", message)
        history.append(user_message)

        bot_response = chat_interface(message, collection_names, history)
        bot_message = ("Assistant", bot_response)
        history.append(bot_message)

        return format_chat(history), current_collections, ""  # Return formatted chat & clear input field

    # Allow ENTER key to send messages
    message_input.submit(
        user_interaction,
        inputs=[message_input, chatbot, collection_dropdown, current_collections],
        outputs=[chatbot, current_collections, message_input]  # Clears input field after sending
    )

    # Also allow clicking the Send button to send messages
    send_button.click(
        user_interaction,
        inputs=[message_input, chatbot, collection_dropdown, current_collections],
        outputs=[chatbot, current_collections, message_input]  # Clears input field after sending
    )

    # Reset the chat when collections change
    collection_dropdown.change(
        lambda: ([], []),
        outputs=[chatbot, current_collections]
    )


# Launch Gradio interface
interface.launch()
