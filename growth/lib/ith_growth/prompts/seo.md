# SEO Prompt

Project: {{project_name}}
Site URL: {{site_url}}
Website repo: {{website_repo}}
Article URL: {{site_url}}{{article_url}}

Generate SEO improvements for this IT history article.

Article title: {{article_title}}

---

## Previous SEO Reports

These are all past SEO reports for this article. Use them to avoid repeating suggestions that were already made, build on what worked, and identify trends in the analytics data over time.

{{seo_history}}

---

## Current Analytics Data

{{analytics_data}}

---

## Article Body

{{article_body}}

---

Based on the article, its analytics history, and past suggestions, return:

- Suggested title improvements (3-5 options, different from any previously suggested)
- Suggested meta description (under 160 characters)
- Suggested Open Graph description
- Suggested schema.org JSON-LD notes
- FAQ block
- Related articles block
- Internal link suggestions
- Hub page suggestions
- Notes on what changed vs previous reports (if any history exists)

At the very end of your response, output a machine-readable patch block. You MUST use the tag `seo_patch` (not `json`) and output nothing after the closing fence:

```seo_patch
{
  "title": "the single best title from your suggestions above",
  "excerpt": "the meta description, max 160 characters"
}
```
