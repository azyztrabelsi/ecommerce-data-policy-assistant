import os
from dotenv import load_dotenv
from langchain_groq import ChatGroq
from qdrant_client import QdrantClient

load_dotenv()

llm = ChatGroq(model="openai/gpt-oss-20b", groq_api_key=os.getenv("GROQ_API_KEY"))
print("Groq says:", llm.invoke("Say OK in one word.").content)

client = QdrantClient(url=os.getenv("QDRANT_URL", "http://localhost:6333"))
print("Qdrant collections:", client.get_collections())