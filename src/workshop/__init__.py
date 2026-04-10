"""Workshop helpers for the AgentCon HK secure agent lab."""

from .lab_helpers import (
    POISONED_NEWS_PROMPT_TEMPLATE,
    build_poisoned_news_prompt,
    build_gateway_agent,
    fetch_poisoned_news,
    gateway_smoke_test,
    query_internal_db,
    request_llm_generated_code,
    run_preconfigured_attack,
    run_secure_compute_demo,
    test_egress,
)

__all__ = [
    "POISONED_NEWS_PROMPT_TEMPLATE",
    "build_poisoned_news_prompt",
    "build_gateway_agent",
    "fetch_poisoned_news",
    "gateway_smoke_test",
    "query_internal_db",
    "request_llm_generated_code",
    "run_preconfigured_attack",
    "run_secure_compute_demo",
    "test_egress",
]
