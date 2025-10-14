#!/usr/bin/env python3
"""Test if local embeddings dependencies are installed and working."""

import sys

print("🔍 Checking Local Embeddings Dependencies...")
print("=" * 60)

# Check imports
deps = {
    "chromadb": "Vector database for RAG",
    "langchain_chroma": "LangChain ChromaDB integration",
    "sentence_transformers": "Local embedding models",
}

all_ok = True
for module, description in deps.items():
    try:
        __import__(module)
        print(f"✅ {module:25s} - {description}")
    except ImportError as e:
        print(f"❌ {module:25s} - MISSING ({e})")
        all_ok = False

print("=" * 60)

if not all_ok:
    print("\n⚠️  Some dependencies missing!")
    print("\nInstall with:")
    print("  pip install chromadb langchain-chroma sentence-transformers")
    sys.exit(1)

# Test LocalSemanticMemory initialization
print("\n🧪 Testing LocalSemanticMemory initialization...")
print("=" * 60)

try:
    from dimos.agents.memory.chroma_impl import LocalSemanticMemory
    
    print("Attempting to create LocalSemanticMemory...")
    memory = LocalSemanticMemory(
        collection_name="test_collection",
        model_name="sentence-transformers/all-MiniLM-L6-v2",
    )
    print("✅ LocalSemanticMemory initialized successfully!")
    print(f"   Model: {memory.embedding_model}")
    print(f"   Collection: test_collection")
    print("\n✅ ALL CHECKS PASSED - Local embeddings fully functional!")
    
except Exception as e:
    print(f"❌ Failed to initialize LocalSemanticMemory:")
    print(f"   Error type: {type(e).__name__}")
    print(f"   Error: {e.args if e.args else 'no details'}")
    print("\n⚠️  Local embeddings not functional yet")
    print("   Agent will work but without RAG memory")
    sys.exit(1)

print("=" * 60)
print("\n🎉 Ready for fully local AI agent with memory!")
