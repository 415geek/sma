# Research Agent Prompt

## Agent Identity

```yaml
agent_id: research_agent
version: 1.0.0
model: gpt-4o
temperature: 0.3
max_tokens: 4096
```

---

## System Prompt

```
You are the Research Agent for an Agency Operating System. Your role is to process raw data from websites, social media profiles, reviews, and search results, then extract structured information for downstream analysis.

## ROLE
You are a meticulous research analyst who extracts factual information from raw source materials. You never invent or assume information—you only report what is explicitly present in the source data.

## OBJECTIVE
Process raw crawled content and extract:
1. Key factual claims with exact source excerpts
2. Structured business information (services, pricing, locations, hours)
3. Brand messaging and positioning signals
4. Visual and tonal characteristics
5. Contact and operational details

## CORE PRINCIPLES

### Evidence-First Extraction
- Every extracted fact MUST have a corresponding excerpt from the source
- If information is not explicitly stated, mark as "not_found" or "inferred" with reasoning
- Preserve original language/terminology from source

### Confidence Scoring
Assign confidence based on:
- HIGH: Directly stated, unambiguous, from official source
- MEDIUM: Stated but requires minor interpretation, or from secondary source
- LOW: Inferred, partially stated, or from user-generated content

### Source Attribution
- Always include source_url and capture_timestamp
- Note the source_type (official_website, google_business, yelp, social_profile, review, etc.)
- Flag if content appears outdated (dates older than 6 months)

## FORBIDDEN BEHAVIORS
1. DO NOT invent information not present in source data
2. DO NOT make assumptions about missing data
3. DO NOT summarize in a way that loses source traceability
4. DO NOT mix information from different sources without clear attribution
5. DO NOT provide recommendations or analysis—only extraction

## OUTPUT REQUIREMENTS
- All outputs must conform to the specified JSON schema
- Use null for missing fields, never empty strings
- Preserve unicode characters and special formatting
- Include raw excerpts with exact quotes when available
```

---

## Input Schema

```json
{
  "type": "object",
  "required": ["project_id", "source_data"],
  "properties": {
    "project_id": {
      "type": "string",
      "format": "uuid"
    },
    "client_context": {
      "type": "object",
      "properties": {
        "brand_name": {"type": "string"},
        "industry": {"type": "string"},
        "location": {"type": "string"}
      }
    },
    "source_data": {
      "type": "object",
      "required": ["source_type", "url", "raw_content"],
      "properties": {
        "source_type": {
          "type": "string",
          "enum": ["website_homepage", "website_about", "website_services", "website_menu", "website_pricing", "website_locations", "google_business", "yelp_profile", "yelp_reviews", "instagram_profile", "facebook_page", "tiktok_profile", "xiaohongshu_profile", "review_collection", "search_results"]
        },
        "url": {"type": "string", "format": "uri"},
        "raw_content": {"type": "string"},
        "captured_at": {"type": "string", "format": "date-time"},
        "metadata": {
          "type": "object",
          "properties": {
            "page_title": {"type": "string"},
            "meta_description": {"type": "string"},
            "language": {"type": "string"}
          }
        }
      }
    },
    "extraction_focus": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["business_info", "services", "pricing", "reviews", "brand_messaging", "visual_identity", "social_metrics", "location_details", "competitive_mentions"]
      }
    }
  }
}
```

---

## Output Schema (OpenAI Structured Outputs Format)

> 对应结构化输出 schema 文件：`agents/schemas/openai/research_extraction.json`

```json
{
  "name": "research_extraction",
  "strict": true,
  "schema": {
    "type": "object",
    "required": ["extraction_id", "source_summary", "extracted_data", "evidence_items", "extraction_metadata"],
    "additionalProperties": false,
    "properties": {
      "extraction_id": {
        "type": "string",
        "description": "Unique identifier for this extraction, format: EXT-{timestamp}"
      },
      "source_summary": {
        "type": "object",
        "required": ["source_type", "url", "content_date_estimate", "language", "quality_score"],
        "additionalProperties": false,
        "properties": {
          "source_type": {"type": "string"},
          "url": {"type": "string"},
          "content_date_estimate": {
            "type": "string",
            "description": "Estimated date of content, format: YYYY-MM or 'unknown'"
          },
          "language": {"type": "string"},
          "quality_score": {
            "type": "string",
            "enum": ["high", "medium", "low"],
            "description": "Quality of source for extraction purposes"
          },
          "quality_notes": {"type": ["string", "null"]}
        }
      },
      "extracted_data": {
        "type": "object",
        "required": ["business_info", "services", "pricing", "brand_signals", "operational_info"],
        "additionalProperties": false,
        "properties": {
          "business_info": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "legal_name": {"type": ["string", "null"]},
              "display_name": {"type": ["string", "null"]},
              "tagline": {"type": ["string", "null"]},
              "description": {"type": ["string", "null"]},
              "year_established": {"type": ["integer", "null"]},
              "business_type": {"type": ["string", "null"]},
              "categories": {
                "type": "array",
                "items": {"type": "string"}
              }
            },
            "required": ["legal_name", "display_name", "tagline", "description", "year_established", "business_type", "categories"]
          },
          "services": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["name", "description", "price_info", "excerpt"],
              "additionalProperties": false,
              "properties": {
                "name": {"type": "string"},
                "description": {"type": ["string", "null"]},
                "price_info": {"type": ["string", "null"]},
                "category": {"type": ["string", "null"]},
                "excerpt": {"type": "string"}
              }
            }
          },
          "pricing": {
            "type": "object",
            "additionalProperties": false,
            "required": ["price_range", "price_tier", "pricing_model", "specific_prices"],
            "properties": {
              "price_range": {
                "type": ["string", "null"],
                "description": "e.g., '$10-50' or '$$$'"
              },
              "price_tier": {
                "type": ["string", "null"],
                "enum": ["budget", "mid", "premium", "luxury", null]
              },
              "pricing_model": {
                "type": ["string", "null"],
                "description": "e.g., 'per service', 'subscription', 'hourly'"
              },
              "specific_prices": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["item", "price", "excerpt"],
                  "additionalProperties": false,
                  "properties": {
                    "item": {"type": "string"},
                    "price": {"type": "string"},
                    "excerpt": {"type": "string"}
                  }
                }
              }
            }
          },
          "brand_signals": {
            "type": "object",
            "additionalProperties": false,
            "required": ["value_propositions", "key_messages", "tone_indicators", "differentiators"],
            "properties": {
              "value_propositions": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["statement", "excerpt"],
                  "additionalProperties": false,
                  "properties": {
                    "statement": {"type": "string"},
                    "excerpt": {"type": "string"}
                  }
                }
              },
              "key_messages": {
                "type": "array",
                "items": {"type": "string"}
              },
              "tone_indicators": {
                "type": "array",
                "items": {"type": "string"},
                "description": "e.g., 'professional', 'casual', 'luxurious', 'friendly'"
              },
              "differentiators": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["claim", "excerpt"],
                  "additionalProperties": false,
                  "properties": {
                    "claim": {"type": "string"},
                    "excerpt": {"type": "string"}
                  }
                }
              }
            }
          },
          "operational_info": {
            "type": "object",
            "additionalProperties": false,
            "required": ["locations", "hours", "contact", "social_links"],
            "properties": {
              "locations": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["address", "city", "state", "zip"],
                  "additionalProperties": false,
                  "properties": {
                    "name": {"type": ["string", "null"]},
                    "address": {"type": ["string", "null"]},
                    "city": {"type": ["string", "null"]},
                    "state": {"type": ["string", "null"]},
                    "zip": {"type": ["string", "null"]},
                    "phone": {"type": ["string", "null"]},
                    "is_primary": {"type": "boolean"}
                  }
                }
              },
              "hours": {
                "type": ["string", "null"],
                "description": "Operating hours as stated"
              },
              "contact": {
                "type": "object",
                "additionalProperties": false,
                "required": ["phone", "email", "booking_url"],
                "properties": {
                  "phone": {"type": ["string", "null"]},
                  "email": {"type": ["string", "null"]},
                  "booking_url": {"type": ["string", "null"]}
                }
              },
              "social_links": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["platform", "url"],
                  "additionalProperties": false,
                  "properties": {
                    "platform": {"type": "string"},
                    "url": {"type": "string"},
                    "handle": {"type": ["string", "null"]}
                  }
                }
              }
            }
          }
        }
      },
      "evidence_items": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["statement", "excerpt", "confidence", "category"],
          "additionalProperties": false,
          "properties": {
            "statement": {
              "type": "string",
              "description": "Factual claim extracted from source"
            },
            "excerpt": {
              "type": "string",
              "description": "Exact quote from source supporting this statement"
            },
            "confidence": {
              "type": "string",
              "enum": ["high", "medium", "low"]
            },
            "confidence_reason": {
              "type": ["string", "null"]
            },
            "category": {
              "type": "string",
              "enum": ["brand", "service", "pricing", "location", "audience", "competitor_mention", "review_insight", "operational"]
            },
            "tags": {
              "type": "array",
              "items": {"type": "string"}
            }
          }
        },
        "description": "Individual evidence items for the evidence_items table"
      },
      "extraction_metadata": {
        "type": "object",
        "required": ["total_evidence_items", "extraction_completeness", "data_gaps", "processing_notes"],
        "additionalProperties": false,
        "properties": {
          "total_evidence_items": {"type": "integer"},
          "extraction_completeness": {
            "type": "string",
            "enum": ["complete", "partial", "minimal"],
            "description": "How much useful data was extracted"
          },
          "data_gaps": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Information that was expected but not found"
          },
          "processing_notes": {
            "type": ["string", "null"],
            "description": "Any issues or observations during extraction"
          }
        }
      }
    }
  }
}
```

