"""Web crawling service using Tavily API for Ghanaian legal sources.

Crawls official Ghanaian government portals for legal documents:
- judiciary.gov.gh
- attorney-general.gov.gh
- parliament.gov.gh
"""

from typing import List, Dict, Optional
from tavily import TavilyClient
from ..config import get_settings
from .ingestion_service import IngestionService


class WebCrawlerService:
    """Web crawling service for Ghanaian legal sources using Tavily API."""

    def __init__(self, db):
        self.settings = get_settings()
        self.tavily_api_key = getattr(self.settings, 'TAVILY_API_KEY', None)
        self.client = TavilyClient(api_key=self.tavily_api_key) if self.tavily_api_key else None
        self.ingestion_service = IngestionService(db)

        # Target portals
        self.portals = {
            "judiciary": "https://judiciary.gov.gh",
            "attorney_general": "https://attorney-general.gov.gh",
            "parliament": "https://parliament.gov.gh",
        }

    def check_connection(self) -> bool:
        """Check if Tavily API is available.

        Returns:
            True if Tavily API key is configured and working
        """
        if not self.client:
            return False
        try:
            # Test with a simple search
            result = self.client.search("test", max_results=1)
            return True
        except Exception as e:
            print(f"Tavily connection check failed: {str(e)}")
            return False

    async def crawl_portal(
        self,
        portal: str,
        query: str,
        document_type: str = "statute",
        max_results: int = 10,
        jurisdiction: str = "GH",
    ) -> Dict:
        """Crawl a specific portal for legal documents.

        Args:
            portal: Portal name (judiciary, attorney_general, parliament)
            query: Search query
            document_type: Type of documents to look for (statute, case_law, regulation)
            max_results: Maximum number of results
            jurisdiction: Jurisdiction code

        Returns:
            Dictionary with crawl results and ingestion status
        """
        if not self.client:
            raise Exception("Tavily API not configured")

        if portal not in self.portals:
            raise ValueError(f"Unknown portal: {portal}")

        # Build search query with portal domain
        domain = self.portals[portal]
        search_query = f"site:{domain} {query} {document_type}"

        try:
            # Search using Tavily
            results = self.client.search(
                query=search_query,
                max_results=max_results,
                search_depth="advanced",
                include_domains=[domain],
            )

            documents = []
            ingested_count = 0

            for result in results.get("results", []):
                title = result.get("title", "Untitled")
                content = result.get("content", "")
                url = result.get("url", "")

                if content:
                    # Ingest the document
                    try:
                        ingest_result = await self.ingestion_service.ingest_text(
                            text=content,
                            title=title,
                            source_type=document_type,
                            jurisdiction=jurisdiction,
                        )
                        documents.append({
                            "title": title,
                            "url": url,
                            "source_id": ingest_result["source_id"],
                            "status": "ingested",
                        })
                        ingested_count += 1
                    except Exception as e:
                        print(f"Failed to ingest {title}: {str(e)}")
                        documents.append({
                            "title": title,
                            "url": url,
                            "status": "failed",
                            "error": str(e),
                        })

            return {
                "portal": portal,
                "query": query,
                "total_results": len(results.get("results", [])),
                "ingested_count": ingested_count,
                "documents": documents,
                "status": "completed",
            }

        except Exception as e:
            raise Exception(f"Crawl failed: {str(e)}")

    async def crawl_all_portals(
        self,
        query: str,
        document_type: str = "statute",
        max_results: int = 5,
        jurisdiction: str = "GH",
    ) -> Dict:
        """Crawl all configured portals.

        Args:
            query: Search query
            document_type: Type of documents
            max_results: Max results per portal
            jurisdiction: Jurisdiction code

        Returns:
            Combined results from all portals
        """
        all_results = {}
        total_ingested = 0

        for portal in self.portals.keys():
            try:
                result = await self.crawl_portal(
                    portal=portal,
                    query=query,
                    document_type=document_type,
                    max_results=max_results,
                    jurisdiction=jurisdiction,
                )
                all_results[portal] = result
                total_ingested += result["ingested_count"]
            except Exception as e:
                all_results[portal] = {
                    "status": "failed",
                    "error": str(e),
                }

        return {
            "query": query,
            "document_type": document_type,
            "total_ingested": total_ingested,
            "results": all_results,
        }

    async def crawl_specific_url(
        self,
        url: str,
        title: str,
        document_type: str,
        jurisdiction: str = "GH",
    ) -> Dict:
        """Crawl a specific URL and ingest its content.

        Args:
            url: URL to crawl
            title: Document title
            document_type: Type of document
            jurisdiction: Jurisdiction code

        Returns:
            Ingestion result
        """
        if not self.client:
            raise Exception("Tavily API not configured")

        try:
            # Extract content from URL
            result = self.client.get_extract_contents(urls=[url])

            for extract_result in result.get("results", []):
                content = extract_result.get("content", "")
                if content:
                    ingest_result = await self.ingestion_service.ingest_text(
                        text=content,
                        title=title,
                        source_type=document_type,
                        jurisdiction=jurisdiction,
                    )
                    return {
                        "url": url,
                        "title": title,
                        "source_id": ingest_result["source_id"],
                        "status": "ingested",
                    }

            raise Exception("No content extracted from URL")

        except Exception as e:
            raise Exception(f"URL crawl failed: {str(e)}")


def get_web_crawler_service(db) -> WebCrawlerService:
    return WebCrawlerService(db)
