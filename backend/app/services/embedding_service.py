"""Embedding service using Ollama for local text embeddings.

Uses nomic-embed-text model (768-dim) for generating embeddings
without external API dependencies.
"""

from typing import List, Optional
import ollama
from ..config import get_settings


class EmbeddingService:
    """Generate embeddings using Ollama nomic-embed-text model."""

    def __init__(self):
        self.settings = get_settings()
        self.model = "nomic-embed-text"
        self.base_url = getattr(self.settings, 'OLLAMA_BASE_URL', 'http://localhost:11434')
        self.client = ollama.Client(host=self.base_url)

    async def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding for a single text.

        Args:
            text: Text to embed

        Returns:
            List of float values (768-dim for nomic-embed-text)
        """
        try:
            response = self.client.embeddings(
                model=self.model,
                prompt=text,
            )
            return response["embedding"]
        except Exception as e:
            raise Exception(f"Failed to generate embedding: {str(e)}")

    async def generate_embeddings_batch(
        self, texts: List[str], batch_size: int = 10
    ) -> List[List[float]]:
        """Generate embeddings for multiple texts.

        Args:
            texts: List of texts to embed
            batch_size: Number of texts to process in parallel

        Returns:
            List of embedding vectors
        """
        embeddings = []

        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            batch_embeddings = []

            for text in batch:
                try:
                    embedding = await self.generate_embedding(text)
                    batch_embeddings.append(embedding)
                except Exception as e:
                    print(f"Failed to embed text: {str(e)}")
                    # Return zero vector as fallback
                    batch_embeddings.append([0.0] * 768)

            embeddings.extend(batch_embeddings)

        return embeddings

    async def generate_query_embedding(self, query: str) -> List[float]:
        """Generate embedding for a search query.

        Args:
            query: Search query text

        Returns:
            Query embedding vector
        """
        return await self.generate_embedding(query)

    def check_connection(self) -> bool:
        """Check if Ollama service is available.

        Returns:
            True if Ollama is running and model is available
        """
        try:
            models = self.client.list()
            model_names = [m["model"] for m in models.get("models", [])]
            return any(self.model in name for name in model_names)
        except Exception as e:
            print(f"Ollama connection check failed: {str(e)}")
            return False


def get_embedding_service() -> EmbeddingService:
    return EmbeddingService()
